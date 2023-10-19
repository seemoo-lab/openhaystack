import os
from system_utils import SystemUtils

class DoxygenExtractor:

    md_special_chars =[
        {
            "md_char": "*",
            "replacement": "&#42;"
        },
        {
            "md_char": "#",
            "replacement": "&#35;"
        },
        {
            "md_char": "`",
            "replacement": "&#183;"
        }
    ]

    #constructor
    def __init__(self, root, header_paths, working_dir = "./temp", doxygen_xml_dest = "./xml"):
        os.chdir(root)
        self.header_paths = header_paths
        self.utils = SystemUtils()
        self.doxygen_xml_dest = doxygen_xml_dest
        self.working_dir = working_dir

    ###
    # this function copies headers recursively from a source director to a destination
    # directory.
    ###
    def get_headers(self, from_dir, to_dir):
        self.utils.copy_files(from_dir, to_dir, "*.h")

    ###
    # Strips out reserved characters used in markdown notation, and replaces them
    # with html character codes.
    #
    # @param text the text to strip and replace the md special characters
    #
    # @return the stripped text.
    ###
    def escape_md_chars(self, text):
        for char in self.md_special_chars:
            text = text.replace(char['md_char'], "\\" + char['md_char'])
        return text


    ###
    # this function extracts data from an element tag ignoring the tag 'ref', but
    # obtains the textual data it has inside the ref tag.
    #
    # @param element the element to process
    #
    # @return a list of extracted strings.
    ###
    def extract_ignoring_refs(self, element):
        list = []

        if element.text is not None:
            list.append(element.text)

        for ref in element.iter(tag="ref"):
            list.append(ref.text)

        return list

    ###
    # this function extracts data from an element tag including all sub elements
    # (recursive)
    #
    # @param element the element to process
    #
    # @return a list of extracted strings.
    ###
    def extract_with_subelements(self, element):
        list = []

        list.append(element.text or "")

        #if element.text is not None:
            #list.append(element.text)

        for subelement in element:
            if subelement is not None:
                list = list + self.extract_with_subelements(subelement)

        list.append(element.tail or "")

        return list

    ###
    # this function was at one point intended to fetch a value of a default parameter
    # it is now only used to fetch the default parameters' name.
    #
    # @param document_root the root of the entire document
    # @param element the element containing the default parameter
    #
    # @return a dictionary containing:
    # {
    #     'name':'',
    #     'value':''
    # }
    #
    # @note this would be more useful if it return the value, it currently does not.
    ###
    def extract_default(self, element):
        ref = element.find("ref")
        return {'name':' '.join(element.itertext()), 'value':''}

    ###
    # extracts a member function form the xml document
    #
    # @param root the document root
    # @param xml_element the member function xml element.
    #
    # @return a function dictionary:
    # {
    #     'short_name':"",
    #     'name':"",
    #     'return_type':"",
    #     'params':[],
    #     'description':[],
    #     'returns':"",
    #     'notes':"",
    #     'examples':""
    # }
    ###
    def extract_member_function(self, xml_element, function_filter = [], filter = True):

        function = {
            'short_name':"",
            'name':"",
            'return_type':"",
            'params':[],
            'description':[],
            'returns':"",
            'notes':"",
            'examples':""
        }

        function['name'] = xml_element.find('definition').text
        function['short_name'] = xml_element.find('name').text

        if filter and any(filtered_func in function['short_name'] for filtered_func in function_filter):
            print "Filtered out: " + function['short_name']
            return

        print "Generating documentation for: " + function['short_name']

        if xml_element.find('type') is not None:
            function['return_type'] = self.escape_md_chars(' '.join(self.extract_ignoring_refs(xml_element.find('type'))))

        #extract our parameters for this member function
        for parameter in xml_element.iter('param'):

            type = ""
            name = ""

            if parameter.find('type') is not None:
                type = self.escape_md_chars(' '.join(parameter.find('type').itertext()))

            if parameter.find('declname') is not None:
                name = ' '.join(self.extract_ignoring_refs(parameter.find('declname')))

            param_object = {
                'type': type,
                'name': name,
                'default':{
                    'name':"",
                    'value':""
                }
            }

            if parameter.find('defval') is not None:
                extracted = self.extract_default(parameter.find('defval'))
                param_object['default']['name'] = extracted['name']
                param_object['default']['value'] = extracted['value']

            function['params'].append(param_object)


        detailed_description = xml_element.find('detaileddescription')

        if len(detailed_description.findall("para")) is not 0:
            for para in detailed_description.findall("para"):
                if len(para.findall("programlisting")) is 0 and len(para.findall("simplesect")) is 0:
                    function['description'] = function['description'] + self.extract_with_subelements(para)

                #para indicates a new paragraph - we should treat it as such... append \n!
                function['description'] = function['description'] + ["\n\n"]

        if len(detailed_description.findall("para/simplesect[@kind='return']/para")) is not 0:
             return_section = detailed_description.findall("para/simplesect[@kind='return']/para")[0]
             function['returns'] = ' '.join(return_section.itertext())

        if len(detailed_description.findall("para/simplesect[@kind='note']/para")) is not 0:
             return_section = detailed_description.findall("para/simplesect[@kind='note']/para")[0]
             function['notes'] =  ' '.join(return_section.itertext())

        examples = detailed_description.find('para/programlisting')

        if examples is not None:
             function['examples'] = ''.join([('' if index is 0 else ' ')+word for index, word in enumerate(examples.itertext(),1) ])

        param_list = detailed_description.findall('para/parameterlist')

        if len(param_list) is not 0:
            for parameter_desc in param_list[0].findall('parameteritem'):

                 param_descriptor = {
                     'name':'',
                     'description':''
                 }

                 param_name = parameter_desc.findall('parameternamelist/parametername')
                 additional = parameter_desc.findall('parameterdescription/para')

                 if len(param_name) is not 0:
                     param_descriptor['name'] = param_name[0].text

                 if len(additional) is not 0:
                     param_descriptor['description'] = ' '.join(additional[0].itertext())

                 for descriptor in function['params']:
                     if param_descriptor['name'] in descriptor['name']:
                         descriptor['description'] = param_descriptor['description']

        return function

    def generate_doxygen(self):
        self.utils.mk_dir(self.working_dir)
        self.utils.clean_dir(self.working_dir)

        for path in self.header_paths:
            self.get_headers(path, self.working_dir)

        if os.path.exists(self.doxygen_xml_dest):
            self.utils.clean_dir(self.doxygen_xml_dest)

        os.system('doxygen doxy-config.cfg')
