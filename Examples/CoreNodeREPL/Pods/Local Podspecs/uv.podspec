# -*- coding: utf-8 -*-
Pod::Spec.new do |s|
  s.name         = 'uv'
  s.version      = '0.11.27'
  s.summary      = 'libuv is a multi-platform support library with a focus on asynchronous I/O'
  s.description  = <<-DESC
                   See https://github.com/joyent/libuv
                   DESC
  s.homepage     = 'http://sixfivezero.net'
  s.license      = ''
  s.author       = '650 Industries'
  s.platform     = :ios, '7.0'

  s.public_header_files = 'libuv/include/*.h'
  s.source_files  = 'libuv/src/**/*.{c,h}'
  s.exclude_files = [
    'libuv/src/win',
    'libuv/src/unix/*{aix,android,bsd,linux,sunos}*.c',
    'libuv/src/unix/pthread-fixes.c',
    'libuv/include/uv-{bsd,linux,sunos,win}*.h',
    'libuv/include/*msvc2008*.h',
  ]
end
