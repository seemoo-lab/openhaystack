import os, re, json, xml.etree.ElementTree
from optparse import OptionParser

from doxygen_extractor import DoxygenExtractor
from md_converter import MarkdownConverter
from system_utils import SystemUtils

member_func_filter = ["idleCallback", "systemCallback", "~"]

filters = True

utils = SystemUtils()

###
# the trigger for generating our documentation
###
def generate_mkdocs(header_paths, type_colour = "#a71d5d", function_name_colour = "#795da3"):

    global member_func_filter
    doxygen = DoxygenExtractor(os.path.abspath("."), header_paths)
    markdown = MarkdownConverter(type_colour, function_name_colour, separate_defaults = True, display_defaults = False)

    doxygen.generate_doxygen()
    #utils.validate_version(doxygen.working_dir, header_paths, "./docs/archive")

    file_names = utils.find_files('docs','*.md')
    section_kind = ["public-func"]
    meta_data_regex = re.compile( r'\[comment\]: <> \((.*?)\)', re.MULTILINE | re.DOTALL )

    for filename in file_names:
        print(filename)

        read_lines = utils.read(filename)

        file_lines = markdown.clean(read_lines, meta_data_regex)

        utils.write(filename, file_lines)

        previous = ""

        for line_number, line in enumerate(file_lines, 1):

            result = re.findall(meta_data_regex,line)

            if len(result) is not 0:

                meta_data = json.loads(result[0])

                if previous is not "" and "end" in meta_data.keys() and meta_data['end'] == previous:
                    previous = ""
                    continue
                elif previous is "":
                    try:
                        previous = meta_data['className']
                    except:
                        raise Exception('There isn\'t a match for the meta_data '+ meta_data)
                else:
                    raise Exception('There isn\'t a match for the meta_data \''+ previous + "'")

                local_filter = member_func_filter

                if "filter" in meta_data:
                    for member_function in meta_data["filter"]:
                        local_filter = local_filter + [ str(member_function) ]

                    print "Custom filter applied: " + str(member_func_filter)

                class_xml_files = list(utils.find_files("./xml","*class*"+meta_data['className'] + ".xml"))

                print class_xml_files

                if len(class_xml_files) == 0:
                    raise Exception("Invalid classname: " + meta_data['className'])
                elif len(class_xml_files) > 1:
                    class_xml_files

                doxygen_class_xml = xml.etree.ElementTree.parse(class_xml_files[0]).getroot()

                member_functions = []

                for section_def in doxygen_class_xml.iter('sectiondef'):
                    if section_def.attrib['kind'] in section_kind:
                        for member_func in section_def.iter('memberdef'):
                            new_member = doxygen.extract_member_function(member_func, local_filter, filter= filters)
                            if new_member is not None:
                                member_functions.append(new_member)

                before = file_lines[:line_number]
                after = file_lines[line_number:]

                between = markdown.gen_member_func_doc(meta_data['className'], member_functions)

                utils.write(filename, before + between + after)
