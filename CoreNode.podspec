# -*- coding: utf-8 -*-
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/

Pod::Spec.new do |s|
  s.name         = "CoreNode"
  s.version      = "0.0.1"
  s.summary      = "A JavaScript environment like Node.js running on JavaScriptCore"
  s.description  = <<-DESC
                   CoreNode is a subset of Node.js that runs on JavaScriptCore. We
                   have ported several of Node's native bindings to iOS and use
                   Node's own JS libraries to set up a similar environment.

                   Within CoreNode you can require() modules and even use npm
                   modules as long as they don't use native bindings we don't yet
                   support and aren't native modules themselves.
                   DESC
  s.homepage     = "http://sixfivezero.net"
  s.license      = ''
  s.author       = "650 Industries"
  s.platform     = :ios, '7.0'

  s.dependency 'CocoaLumberjack', '~> 1.9'
  s.dependency 'PromiseKit/base', '~> 0.9'
  s.dependency 'uv'

  s.source_files  = 'CoreNode/**/*.{h,m}'
  #s.exclude_files = 'CoreNode/Exclude'

  # TODO: recursively follow CoreNode.h
  # s.public_header_files = 'Classes/**/*.h'
  s.resource_bundle = { 'CoreNode' => ['CoreNode/js', 'CoreNode/Bindings/*.js'] }

  s.requires_arc = true
  # s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(inherited)' }
  s.prefix_header_file = 'CoreNode/CoreNode-Prefix.pch'
end
