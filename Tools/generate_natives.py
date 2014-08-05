#!/usr/bin/env python

import os
import os.path

import js2c

if __name__ == '__main__':
    js_directory = os.path.join(os.path.dirname(__file__), '../CoreNode/js')
    node_builtins = [os.path.join(js_directory, script) for script in ('node.js', 'iOS.js')]

    node_builtins_directory = os.path.join(js_directory, 'node-lib')
    for filename in os.listdir(node_builtins_directory):
        path = os.path.join(node_builtins_directory, filename)
        if os.path.isfile(path):
            node_builtins.append(path)

    options = {'TYPE': 'CORE', 'COMPRESSION': 'off'}
    output_path = os.path.join(os.path.dirname(__file__), '../CoreNode/Bindings/EmbeddedNativeSources.m')
    js2c.JS2C(node_builtins, [output_path], options)
