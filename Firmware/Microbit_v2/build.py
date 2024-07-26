#!/usr/bin/env python

# The MIT License (MIT)

# Copyright (c) 2017 Lancaster University.

# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

import os
import sys
import optparse
import platform
import json
import shutil
import re
from utils.python.codal_utils import system, build, read_json, checkgit, read_config, update, revision, printstatus, status, get_next_version, lock, delete_build_folder, generate_docs

parser = optparse.OptionParser(usage="usage: %prog target-name-or-url [options]", description="This script manages the build system for a codal device. Passing a target-name generates a codal.json for that devices, to list all devices available specify the target-name as 'ls'.")
parser.add_option('-c', '--clean', dest='clean', action="store_true", help='Whether to clean before building. Applicable only to unix based builds.', default=False)
parser.add_option('-t', '--test-platforms', dest='test_platform', action="store_true", help='Specify whether the target platform is a test platform or not.', default=False)
parser.add_option('-l', '--lock', dest='lock_target', action="store_true", help='Create target-lock.json, updating patch version', default=False)
parser.add_option('-b', '--branch', dest='branch', action="store_true", help='With -l, use vX.X.X-BRANCH.Y', default=False)
parser.add_option('-m', '--minor', dest='update_minor', action="store_true", help='With -l, update minor version', default=False)
parser.add_option('-M', '--major', dest='update_major', action="store_true", help='With -l, update major version', default=False)
parser.add_option('-V', '--version', dest='version', metavar="VERSION", help='With -l, set the version; use "-V v0.0.1" to bootstrap', default=False)
parser.add_option('-u', '--update', dest='update', action="store_true", help='git pull target and libraries', default=False)
parser.add_option('-s', '--status', dest='status', action="store_true", help='git status target and libraries', default=False)
parser.add_option('-r', '--revision', dest='revision', action="store", help='Checkout a specific revision of the target', default=False)
parser.add_option('-d', '--dev', dest='dev', action="store_true", help='enable developer mode (does not use target-locked.json)', default=False)
parser.add_option('-g', '--generate-docs', dest='generate_docs', action="store_true", help='generate documentation for the current target', default=False)

(options, args) = parser.parse_args()

if not os.path.exists("build"):
    os.mkdir("build")

if options.lock_target:
    lock(options)
    exit(0)

if options.update:
    update()
    exit(0)

if options.status:
    status()
    exit(0)

if options.revision:
    revision(options.revision)
    exit(0)

# out of source build!
os.chdir("build")

test_json = read_json("../utils/targets.json")

# configure the target a user has specified:
if len(args) == 1:

    target_name = args[0]
    target_config = None

    # list all targets
    if target_name == "ls":
        for json_obj in test_json:
            s = "%s: %s" % (json_obj["name"], json_obj["info"])
            if "device_url" in json_obj.keys():
                s += "(%s)" % json_obj["device_url"]
            print(s)
        exit(0)

    # cycle through out targets and check for a match
    for json_obj in test_json:
        if json_obj["name"] != target_name:
            continue

        del json_obj["device_url"]
        del json_obj["info"]

        target_config = json_obj
        break

    if target_config == None and target_name.startswith("http"):
        target_config = {
            "name": re.sub("^.*/", "", target_name),
            "url": target_name,
            "branch": "master",
            "type": "git"
        }

    if target_config == None:
        print("'" + target_name + "'" + " is not a valid target.")
        exit(1)

    # developer mode is for users who wish to contribute, it will clone and checkout commitable branches.
    if options.dev:
        target_config["dev"] = True

    config = {
        "target":target_config
    }

    with open("../codal.json", 'w') as codal_json:
        json.dump(config, codal_json, indent=4)

    # remove the build folder, a user could be swapping targets.
    delete_build_folder()


elif len(args) > 1:
    print("Too many arguments supplied, only one target can be specified.")
    exit(1)

if not options.test_platform:

    if not os.path.exists("../codal.json"):
        print("No target specified in codal.json, does codal.json exist?")
        exit(1)

    if options.generate_docs:
        generate_docs()
        exit(0)

    build(options.clean)
    exit(0)

for json_obj in test_json:

    # some platforms aren't supported by travis, ignore them when testing.
    if "test_ignore" in json_obj:
        print("ignoring: " + json_obj["name"])
        continue

    # ensure we have a clean build tree.
    delete_build_folder()

    # clean libs
    if os.path.exists("../libraries"):
        shutil.rmtree('../libraries')

    # configure the target and tests...
    config = {
        "target":json_obj,
        "output":".",
        "application":"libraries/"+json_obj["name"]+"/tests/"
    }

    with open("../codal.json", 'w') as codal_json:
        json.dump(config, codal_json, indent=4)

    build(True, True)
