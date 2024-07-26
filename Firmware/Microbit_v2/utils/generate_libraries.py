import os
import git
from git import Actor
import optparse
import fnmatch
import glob
import shutil
import ntpath
import json

def make_cmake(lib_name, lib_file_name, include_path, dest):
    print "LIB NAME " + lib_name
    with open(dest + "/CMakeLists.txt", 'w') as f:
        lines = [
            "project(" + lib_name + ")\r\n"
            "add_library(" + lib_name + " STATIC " + lib_file_name + ")\r\n",
            "set_target_properties(" + lib_name +" PROPERTIES LINKER_LANGUAGE CXX)\r\n",
            "target_include_directories(" + lib_name + " PUBLIC \"" + include_path + "\")\r\n",
        ]
        print "LINES : " + str(lines)
        f.writelines(lines)
        f.close()

def copytree(src, dst, symlinks=False, ignore=None):
    if not os.path.exists(dst):
        os.makedirs(dst)
    for item in os.listdir(src):
        s = os.path.join(src, item)
        d = os.path.join(dst, item)
        if os.path.isdir(s):
            copytree(s, d, symlinks, ignore)
        else:
            if not os.path.exists(d) or os.stat(s).st_mtime - os.stat(d).st_mtime > 1:
                shutil.copy2(s, d)

def path_leaf(path):
    head, tail = ntpath.split(path)
    return tail or ntpath.basename(head)

def recursive_glob(treeroot, pattern):
    results = []
    for base, dirs, files in os.walk(treeroot):
        goodfiles = fnmatch.filter(files, pattern)
        results.extend(os.path.join(base, f) for f in goodfiles)
    return results

parser = optparse.OptionParser()
parser.add_option('-c', '--clean', dest='clean', action="store_true", help='Whether to clean before building.', default=False)

(options, args) = parser.parse_args()

os.chdir("..")

if not os.path.exists("build"):
    os.mkdir("build")

# out of source build!
os.chdir("build")

# configure os.system("cmake ..")
os.system("cmake .. -DCODAL_HEADER_EXTRACTION:BOOL=TRUE")

if options.clean:
    os.system("make clean")

# build
os.system("make -j 10")

with open('../codal.json') as data_file:
    codal = json.load(data_file)

#ntpath.basename(f)
folders = [path_leaf(f) for f in glob.glob("../libraries/*/")]
header_folders = [path_leaf(f) for f in glob.glob("./build/*/")]

print folders
print header_folders

mapping = []

#note for next time, need to copy all lib files to their appropriate build/lib place otherwise they get auto cleaned.

valid_libs = []

for folder in header_folders:
    lib_file_name = "lib" + folder + ".a"
    if not os.path.exists("./"+lib_file_name):
        print "No library exists, skipping: " + lib_file_name
        continue

    shutil.copy("./" + lib_file_name, "./build/"+folder)
    valid_libs = valid_libs + [folder]


for folder in valid_libs:
    lib_name = folder
    lib_file_name = "lib" + folder + ".a"
    folder_path = '../libraries/' + folder
    header_folder = "./build/" + folder
    header_ext = "includes"

    with open(folder_path + "CMakeLists.txt") as cmake:

        "target_link_libraries\((?:\s*(.+))+\s*\)"

        for line in cmake.lines():
            if "target_link_libraries" in line



    # get the repo
    try:
        repo = git.Repo('../libraries/' + folder)
    except:
        print folder + " is not a valid git repository."
        continue

    active_branch = repo.active_branch.name

    # check for any uncommitted changes
    if len(repo.index.diff(None)) > 0 :
        print folder + " has uncommitted changes, skipping."
        continue;

    branch_names = [b.name for b in repo.branches]

    lib_branch_name = "lib_" + codal["target"]["processor"] + codal["target"]["device"]

    # tag using above + version specified in target.json

    # swap to an orphaned branch if none exists
    if lib_branch_name not in branch_names:
        repo.active_branch.checkout(orphan=lib_branch_name)

        for f in glob.glob(folder_path + "/*/"):
            shutil.rmtree(f)

        files = [f for f in os.listdir('.') if os.path.isfile(f)]

        for file in files:
            os.remove(file)
    else:
        repo.active_branch.checkout(lib_branch_name)

    repo.index.remove("*", r=True)

    copytree(header_folder, folder_path + "/")

    make_cmake(lib_name, lib_file_name, header_ext, folder_path + "/")

    repo.index.add("*")

    author = Actor("codal", "codal@example.com")

    repo.index.commit("Library generated", author=author, committer=author)

    #repo.git.checkout(active_branch)

    #break
