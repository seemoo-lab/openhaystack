import json, shutil, zipfile, urllib, os, fnmatch

class SystemUtils:

    folder_filter = ["ble", "ble-nrf51822", "mbed-classic","nrf51-sdk"]

    ###
    # reads a file and returns a list of lines
    #
    # @param path the path where the file is located
    #
    # @return the list of lines representing the file.
    ###
    def read(self, path, plain=False):
        if plain:
            return self.__read_plain(path)
        print "Opening: " + path + " \n"
        with open(path, 'r') as file:
            return file.readlines()

    def __read_plain(self, path):
        print "Opening: " + path + " \n"
        with open(path, 'r') as file:
            return file.read()

    ###
    # writes a given set of lines to a path.
    #
    # @param path the path where the file is located
    # @param lines the lines to write
    ###
    def write(self, path, lines):
        print "Writing to: " + path + " \n"
        with open(path, 'w') as file:
            file.writelines(lines)

    #http://stackoverflow.com/questions/2186525/use-a-glob-to-find-files-recursively-in-python
    def find_files(self, directory, pattern):

        print("DIR:")
        for root, dirs, files in os.walk(directory):
            if any(dir in root for dir in self.folder_filter):
                continue

            for basename in files:
                if fnmatch.fnmatch(basename, pattern):
                    filename = os.path.join(root, basename)
                    yield filename

    ###
    # removes files from a folder.
    ###
    def clean_dir(self, dir):
        for root, dirs, files in os.walk(dir):
            for f in files:
                os.unlink(os.path.join(root, f))
            for d in dirs:
                shutil.rmtree(os.path.join(root, d))

    ###
    # this files from one location to another
    ###
    def copy_files(self, from_dir, to_dir, pattern):


        files = self.find_files(from_dir, pattern)

        print("FILES!!!! ")
        for file in files:
            print file
            shutil.copy(file,to_dir)

    def mk_dir(self, path):
        if not os.path.exists(path):
            os.makedirs(path)

    def copytree(self, src, dst, symlinks=False, ignore=None):
        if not os.path.exists(dst):
            os.makedirs(dst)
        for item in os.listdir(src):
            s = os.path.join(src, item)
            d = os.path.join(dst, item)
            if os.path.isdir(s):
                self.copytree(s, d, symlinks, ignore)
            else:
                if not os.path.exists(d) or os.stat(s).st_mtime - os.stat(d).st_mtime > 1:
                    shutil.copy2(s, d)

    def __add_version_info(self,version_string, extract_location):
        content_path = extract_location + "js/base.js"
        lines = self.read(content_path)
        html_string = '<div class=\'admonition warning\' style=\'margin-top:30px;\'><p class=\'admonition-title\'>Warning</p><p>You are viewing documentation for <b>' + version_string + '</b></p></div>'
        lines[0]= '$(document).ready(function() { $(\'div[role="main"]\').prepend("' + html_string + '") });'
        self.write(content_path, lines)

    def validate_version(self, working_dir, module_paths, extract_location):
        import yaml

        module_string = "/module.json"
        mkdocs_yml = yaml.load(self.read("./mkdocs.yml", plain=True))

        module_strings = []

        for current_path in module_paths:
            module_strings = module_strings + [json.loads(self.read(current_path + module_string, plain=True))["version"]]

        if module_strings[1:] != module_strings[:-1]:
            raise Exception("Version mismatch exception! microbit-dal and microbit are not compatible versions.")

        module_string = "v" + str(module_strings[0])

        if mkdocs_yml["versioning"]["runtime"] != module_string:
            #capture old site, save in docs/historic/versionNumber
            zip_dest = working_dir + "/" + str(mkdocs_yml["versioning"]["runtime"]) + ".zip"

            extract_folder = extract_location+ "/" + mkdocs_yml["versioning"]["runtime"]+"/"

            urllib.urlretrieve("https://github.com/lancaster-university/microbit-docs/archive/gh-pages.zip", zip_dest)

            zip_ref = zipfile.ZipFile(zip_dest)

            #obtain the archive prepended name
            archive_name = working_dir + "/" + zip_ref.namelist()[0]

            zip_ref.extractall(working_dir)
            zip_ref.close()

            self.copytree(archive_name, extract_folder)

            self.__add_version_info(mkdocs_yml["versioning"]["runtime"], extract_folder)

            self.clean_dir(archive_name)

            mkdocs_yml["versioning"]["runtime"] = module_string

            with open("./mkdocs.yml", "w") as f:
                yaml.dump(mkdocs_yml, f, default_flow_style=False )
