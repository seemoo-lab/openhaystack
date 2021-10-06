import os
import sys
import optparse
import platform
import json
import shutil
import re

import os, re, json, xml.etree.ElementTree
from optparse import OptionParser


def system(cmd):
    if os.system(cmd) != 0:
      sys.exit(1)

def build(clean, verbose = False):
    if platform.system() == "Windows":
        # configure
        system("cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -G \"Ninja\"")

        # build
        system("ninja")
    else:
        # configure
        system("cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -G \"Unix Makefiles\"")

        if clean:
            system("make clean")

        # build
        if verbose:
            system("make -j 10 VERBOSE=1")
        else:
            system("make -j 10")

def read_json(fn):
    json_file = ""
    with open(fn) as f:
        json_file = f.read()
    return json.loads(json_file)

def checkgit():
    stat = os.popen('git status --porcelain').read().strip()
    if stat != "":
        print("Missing checkin in", os.getcwd(), "\n" + stat)
        exit(1)

def read_config():
    codal = read_json("codal.json")
    targetdir = codal['target']['name']
    target = read_json("libraries/" + targetdir + "/target.json")
    return (codal, targetdir, target)

def update(allow_detached=False):
    (codal, targetdir, target) = read_config()
    dirname = os.getcwd()
    for ln in target['libraries']:
        os.chdir(dirname + "/libraries/" + ln['name'])
        system("git checkout " + ln['branch'])
        system("git pull")
    os.chdir(dirname + "/libraries/" + targetdir)
    if ("HEAD detached" in os.popen('git branch').read().strip() and
        allow_detached == False):
        system("git checkout master")
    system("git pull")
    os.chdir(dirname)

def revision(rev):
    (codal, targetdir, target) = read_config()
    dirname = os.getcwd()
    os.chdir("libraries/" + targetdir)
    system("git checkout " + rev)
    os.chdir(dirname)
    update(True)

def printstatus():
    print("\n***%s" % os.getcwd())
    system("git status -s")
    system("git rev-parse HEAD")
    system("git branch")

def status():
    (codal, targetdir, target) = read_config()
    dirname = os.getcwd()
    for ln in target['libraries']:
        os.chdir(dirname + "/libraries/" + ln['name'])
        printstatus()
    os.chdir(dirname + "/libraries/" + targetdir)
    printstatus()
    os.chdir(dirname)
    printstatus()

def get_next_version(options):
    if options.version:
        return options.version
    log = os.popen('git log -n 100').read().strip()
    m = re.search('Snapshot v(\d+)\.(\d+)\.(\d+)(-([\w\-]+).(\d+))?', log)
    if m is None:
        print("Cannot determine next version from git log")
        exit(1)
    v0 = int(m.group(1))
    v1 = int(m.group(2))
    v2 = int(m.group(3))
    vB = -1
    branchName = os.popen('git rev-parse --abbrev-ref HEAD').read().strip()
    if not options.branch and branchName != "master":
        print("On non-master branch use -l -b")
        exit(1)
    suff = ""
    if options.branch:
        if m.group(4) and branchName == m.group(5):
            vB = int(m.group(6))
        suff = "-%s.%d" % (branchName, vB + 1)
    elif options.update_major:
        v0 += 1
        v1 = 0
        v2 = 0
    elif options.update_minor:
        v1 += 1
        v2 = 0
    else:
        v2 += 1
    return "v%d.%d.%d%s" % (v0, v1, v2, suff)

def lock(options):
    (codal, targetdir, target) = read_config()
    dirname = os.getcwd()
    for ln in target['libraries']:
        os.chdir(dirname + "/libraries/" + ln['name'])
        checkgit()
        stat = os.popen('git status --porcelain -b').read().strip()
        if "ahead" in stat:
            print("Missing push in", os.getcwd())
            exit(1)
        sha = os.popen('git rev-parse HEAD').read().strip()
        ln['branch'] = sha
        print(ln['name'], sha)
    os.chdir(dirname + "/libraries/" + targetdir)
    ver = get_next_version(options)
    print("Creating snaphot", ver)
    system("git checkout target-locked.json")
    checkgit()
    target["snapshot_version"] = ver
    with open("target-locked.json", "w") as f:
        f.write(json.dumps(target, indent=4, sort_keys=True))
    system("git commit -am \"Snapshot %s\"" % ver)  # must match get_next_version() regex
    sha = os.popen('git rev-parse HEAD').read().strip()
    system("git tag %s" % ver)
    system("git pull")
    system("git push")
    system("git push --tags")
    os.chdir(dirname)
    print("\nNew snapshot: %s [%s]" % (ver, sha))

def delete_build_folder(in_folder = True):
    if in_folder:
        os.chdir("..")

    shutil.rmtree('./build')
    os.mkdir("./build")

    if in_folder:
        os.chdir("./build")

def generate_docs():
    from doc_gen.doxygen_extractor import DoxygenExtractor
    from doc_gen.md_converter import MarkdownConverter
    from doc_gen.system_utils import SystemUtils
    from doc_gen.doc_gen import generate_mkdocs

    os.chdir("..")
    (codal, targetdir, target) = read_config()

    lib_dir = os.getcwd() + "/libraries/"

    libraries = [lib_dir + targetdir]

    for l in target["libraries"]:
        libraries = libraries + [ lib_dir + l["name"]]

    os.chdir(lib_dir + targetdir)

    generate_mkdocs(libraries)


