#!/usr/bin/env python
#
# Copyright 2012 the V8 project authors. All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of Google Inc. nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# This is a utility for converting JavaScript source code into Objective-C
# arrays of NSStrings.

import os, re, sys, string
import jsmin


def ToNSStringArray(sources):
  nsstrings = []
  replacements = [('\\', r'\\'), ('"', r'\"'), ('\n', r'\n')]
  for source in sources:
    for replacement in replacements:
      source = source.replace(*replacement)
    nsstrings.append('@"' + source + '"')
  return '\n  ' + ',\n  '.join(nsstrings) + '\n'


def RemoveCommentsAndTrailingWhitespace(lines):
  #lines = re.sub(r'//.*\n', '\n', lines) # end-of-line comments
  lines = re.sub(
    re.compile(r'/\*.*?\*/', re.DOTALL),
    lambda match: '\n' * len(re.findall('\n', match.group(0))),
    lines) # comments.
  lines = re.sub(r'[ \t]+\n', '\n', lines) # trailing whitespace
  return lines


def ReadFile(filename):
  with open(filename, "rt") as file:
    return file.read()


def ReadLines(filename):
  result = []
  for line in open(filename, "rt"):
    if '#' in line:
      line = line[:line.index('#')]
    line = line.strip()
    if len(line) > 0:
      result.append(line)
  return result


def LoadConfigFrom(name):
  import ConfigParser
  config = ConfigParser.ConfigParser()
  config.read(name)
  return config


def ParseValue(string):
  string = string.strip()
  if string.startswith('[') and string.endswith(']'):
    return string.lstrip('[').rstrip(']').split()
  else:
    return string


EVAL_PATTERN = re.compile(r'\b(?<!\.)eval\s*\(')
WITH_PATTERN = re.compile(r'\b(?<!\.)with\s*\(')


def Validate(lines, file):
  lines = RemoveCommentsAndTrailingWhitespace(lines)
  # Because of simplified context setup, eval and with is not
  # allowed in the natives files.
  eval_match = EVAL_PATTERN.search(lines)
  if eval_match:
    raise ("Eval disallowed in natives: %s" % file)
  with_match = WITH_PATTERN.search(lines)
  if with_match:
    raise ("With statements disallowed in natives: %s" % file)


def ExpandConstants(lines, constants):
  for key, value in constants:
    lines = key.sub(str(value), lines)
  return lines


def ExpandMacroDefinition(lines, pos, name_pattern, macro, expander):
  pattern_match = name_pattern.search(lines, pos)
  while pattern_match is not None:
    # Scan over the arguments
    height = 1
    start = pattern_match.start()
    end = pattern_match.end()
    assert lines[end - 1] == '('
    last_match = end
    arg_index = [0]  # Wrap state into array, to work around Python "scoping"
    mapping = { }
    def add_arg(str):
      # Remember to expand recursively in the arguments
      replacement = expander(str.strip())
      mapping[macro.args[arg_index[0]]] = replacement
      arg_index[0] += 1
    while end < len(lines) and height > 0:
      # We don't count commas at higher nesting levels.
      if lines[end] == ',' and height == 1:
        add_arg(lines[last_match:end])
        last_match = end + 1
      elif lines[end] in ['(', '{', '[']:
        height = height + 1
      elif lines[end] in [')', '}', ']']:
        height = height - 1
      end = end + 1
    # Remember to add the last match.
    add_arg(lines[last_match:end-1])
    result = macro.expand(mapping)
    # Replace the occurrence of the macro with the expansion
    lines = lines[:start] + result + lines[end:]
    pattern_match = name_pattern.search(lines, start + len(result))
  return lines

def ExpandMacros(lines, macros):
  # We allow macros to depend on the previously declared macros, but
  # we don't allow self-dependecies or recursion.
  for name_pattern, macro in reversed(macros):
    def expander(s):
      return ExpandMacros(s, macros)
    lines = ExpandMacroDefinition(lines, 0, name_pattern, macro, expander)
  return lines

class TextMacro:
  def __init__(self, args, body):
    self.args = args
    self.body = body
  def expand(self, mapping):
    result = self.body
    for key, value in mapping.items():
        result = result.replace(key, value)
    return result

class PythonMacro:
  def __init__(self, args, fun):
    self.args = args
    self.fun = fun
  def expand(self, mapping):
    args = []
    for arg in self.args:
      args.append(mapping[arg])
    return str(self.fun(*args))

CONST_PATTERN = re.compile(r'^const\s+([a-zA-Z0-9_]+)\s*=\s*([^;]*);$')
MACRO_PATTERN = re.compile(r'^macro\s+([a-zA-Z0-9_]+)\s*\(([^)]*)\)\s*=\s*([^;]*);$')
PYTHON_MACRO_PATTERN = re.compile(r'^python\s+macro\s+([a-zA-Z0-9_]+)\s*\(([^)]*)\)\s*=\s*([^;]*);$')


def ReadMacros(lines):
  constants = []
  macros = []
  for line in lines:
    hash = line.find('#')
    if hash != -1: line = line[:hash]
    line = line.strip()
    if len(line) is 0: continue
    const_match = CONST_PATTERN.match(line)
    if const_match:
      name = const_match.group(1)
      value = const_match.group(2).strip()
      constants.append((re.compile("\\b%s\\b" % name), value))
    else:
      macro_match = MACRO_PATTERN.match(line)
      if macro_match:
        name = macro_match.group(1)
        args = [match.strip() for match in macro_match.group(2).split(',')]
        body = macro_match.group(3).strip()
        macros.append((re.compile("\\b%s\\(" % name), TextMacro(args, body)))
      else:
        python_match = PYTHON_MACRO_PATTERN.match(line)
        if python_match:
          name = python_match.group(1)
          args = [match.strip() for match in python_match.group(2).split(',')]
          body = python_match.group(3).strip()
          fun = eval("lambda " + ",".join(args) + ': ' + body)
          macros.append((re.compile("\\b%s\\(" % name), PythonMacro(args, fun)))
        else:
          raise ("Illegal line: " + line)
  return (constants, macros)

INLINE_MACRO_PATTERN = re.compile(r'macro\s+([a-zA-Z0-9_]+)\s*\(([^)]*)\)\s*\n')
INLINE_MACRO_END_PATTERN = re.compile(r'endmacro\s*\n')

def ExpandInlineMacros(lines, filename):
  pos = 0
  while True:
    macro_match = INLINE_MACRO_PATTERN.search(lines, pos)
    if macro_match is None:
      # no more macros
      return lines
    name = macro_match.group(1)
    args = [match.strip() for match in macro_match.group(2).split(',')]
    end_macro_match = INLINE_MACRO_END_PATTERN.search(lines, macro_match.end());
    if end_macro_match is None:
      raise ("Macro %s unclosed in %s" % (name, filename))
    body = lines[macro_match.end():end_macro_match.start()]

    # remove macro definition
    lines = lines[:macro_match.start()] + lines[end_macro_match.end():]
    name_pattern = re.compile("\\b%s\\(" % name)
    macro = TextMacro(args, body)

    # advance position to where the macro defintion was
    pos = macro_match.start()

    def non_expander(s):
      return s
    lines = ExpandMacroDefinition(lines, pos, name_pattern, macro, non_expander)

TEMPLATE_PATH = os.path.join(os.path.dirname(__file__), 'EmbeddedNativeSources.template.m')
HEADER_TEMPLATE = open(TEMPLATE_PATH).read()


GET_INDEX_CASE = """\
    if ([moduleName isEqualToString:@"%(id)s\"]) return %(i)i;
"""


GET_SCRIPT_NAME_CASE = """\
    if (index == %(i)i) return @"%(name)s";
"""


GET_MODULE_NAME_CASE = """\
    if (index == %(i)i) return @"%(id)s";
"""

def JS2C(source, target, env):
  ids = []
  debugger_ids = []
  modules = []
  # Locate the macros file name.
  consts = []
  macros = []
  for s in source:
    if 'macros.py' == (os.path.split(str(s))[1]):
      (consts, macros) = ReadMacros(ReadLines(str(s)))
    else:
      modules.append(s)

  minifier = jsmin.JavaScriptMinifier()

  all_sources = []
  for module in modules:
    filename = str(module)
    debugger = filename.endswith('-debugger.js')
    lines = ReadFile(filename)
    lines = ExpandConstants(lines, consts)
    lines = ExpandMacros(lines, macros)
    lines = RemoveCommentsAndTrailingWhitespace(lines)
    lines = ExpandInlineMacros(lines, filename)
    Validate(lines, filename)
    if 'MINIFY' in env and env['MINIFY']:
      lines = minifier.JSMinify(lines)
    id = (os.path.split(filename)[1])[:-3]
    if debugger: id = id[:-9]
    raw_length = len(lines)
    if debugger:
      debugger_ids.append((id, raw_length))
    else:
      ids.append((id, raw_length))
    all_sources.append(lines)

  if env['COMPRESSION'] == 'off':
    sources_data = ToNSStringArray(all_sources)
  else:
    raise Exception('Compression is not supported')

  # Build debugger support functions
  get_index_cases = [ ]
  get_script_name_cases = [ ]
  get_module_name_cases = [ ]

  i = 0
  for (id, raw_length) in debugger_ids + ids:
    native_name = "native %s.js" % id
    get_index_cases.append(GET_INDEX_CASE % { 'id': id, 'i': i })
    get_script_name_cases.append(GET_SCRIPT_NAME_CASE % {
        'name': native_name,
        'length': len(native_name),
        'i': i
        })
    get_module_name_cases.append(GET_MODULE_NAME_CASE % {
        'id': id,
        'length': len(id),
        'i': i
        })
    i = i + 1

  # Emit result
  generated_source = HEADER_TEMPLATE % {
    'generated': '@' + 'generated',
    'builtin_count': len(ids) + len(debugger_ids),
    'debugger_count': len(debugger_ids),
    'sources_data': sources_data,
    'get_index_cases': "".join(get_index_cases),
    'get_script_name_cases': "".join(get_script_name_cases),
    'get_module_name_cases': "".join(get_module_name_cases),
    'type': env['TYPE']
  }

  output_path = str(target[0])
  try:
    with open(output_path, 'r') as output:
      if output.read() == generated_source:
        return
  except IOError:
    pass

  with open(output_path, 'w') as output:
    output.write(generated_source)

def main():
  natives = sys.argv[1]
  type = sys.argv[2]
  compression = sys.argv[3]
  source_files = sys.argv[4:]
  JS2C(source_files, [natives], { 'TYPE': type, 'COMPRESSION': compression })

if __name__ == "__main__":
  main()
