util = require 'util'
ioslogging = process.binding 'ioslogging'

console =
  log: ->
    ioslogging.logInfo util.format arguments...
  error: ->
    ioslogging.logError "[error] " + util.format arguments...
  warn: ->
    ioslogging.logWarning "[warn] " + util.format arguments...
  info: ->
    ioslogging.logInfo "[info] " + util.format arguments...
  debug: ->
    ioslogging.logDebug "[debug] " + util.format arguments...
  verbose: ->
    ioslogging.logVerbose "[verbose] " + util.format arguments...
  dir: (object, options) ->
    options = util._extend {customInspect: false}, options
    ioslogging.logInfo util.inspect(object, options) + '\n'
  assert: (expression, args...) ->
    if !expression
      require('assert').ok false, util.format args...

# node.js defines a global getter for the console, which is ignored in web
# contexts with real consoles
if global.console? and global.console isnt module.exports
  browserConsole = global.console
  for name, method of console
    browserMethod = browserConsole[name]
    do (method, browserMethod) ->
      browserConsole[name] = ->
        result = browserMethod.apply browserConsole, arguments
        method.apply console, arguments
        return result
  console = browserConsole

module.exports = console
