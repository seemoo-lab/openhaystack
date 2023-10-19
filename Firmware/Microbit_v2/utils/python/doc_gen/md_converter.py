import re, json, copy

class MarkdownConverter:

    #constructor
    def __init__(self, type_colour, function_name_colour, separate_defaults = True, display_defaults = False):
        self.type_colour = type_colour
        self.function_name_colour = function_name_colour
        self.separate_defaults = separate_defaults
        self.display_defaults = display_defaults

    ###
    # wraps text in a div element with a given color
    #
    # @param text the text to wrap
    # @param color the desired text color
    #
    # @return a string representing the now wrapped text
    ###
    def wrap_text(self, text, color):
        return "<div style='color:" + color + "; display:inline-block'>" + text + "</div>"

    ###
    # removes previously generated markdown from the file.
    #
    # @param file_lines a list of lines representing a file.
    # @param regexp the regular expression that dictates a match.
    ###
    def clean(self, file_lines, regexp):
        start = 0
        end = 0

        for line_number, line in enumerate(file_lines, 1):
            result = re.findall(regexp,line)

            if len(result) is not 0:
                meta_data = json.loads(result[0])

                keys = meta_data.keys()

                #classname indicates the beginning of a meta_data section
                if 'className' in keys:
                    start = line_number

                #end indicated the end of a meta_data section
                if 'end' in keys:
                    end = line_number - 1

        return file_lines[:start] + file_lines[end:]

    ###
    # given a member function, this function derives the alternative versions
    #
    # @param member_func the member function that is required to be derrived
    #
    # @return a list of function dictionaries that contain the alternatives, based on the original
    ###
    def derive_functions(self, member_func):
        member_functions_derived = []

        if len(member_func['params']) is not 0:

            param_index = 0

            for param in member_func['params']:
                if len(param['default']['name']) is 0:
                    param_index = param_index + 1
                else:
                    break

            bare_function = {
                'short_name' : member_func['short_name'],
                'name' : member_func['name'],
                'params' : [],
                'description' : member_func['description'],
                'returns' : member_func['returns'],
                'notes' : member_func['notes'],
                'examples' : member_func['examples'],
                'return_type' : member_func['return_type'],
            }

            for i in range(0, param_index):
                bare_function['params'] = bare_function['params'] + [member_func['params'][i]]

            member_functions_derived = member_functions_derived + [bare_function]

            current = copy.copy(bare_function)

            #lists retain references, so we have to copy objects to maintain separation
            for remainder in range(param_index, len(member_func['params'])):
                current['params'] = current['params'] + [member_func['params'][remainder]]
                member_functions_derived = member_functions_derived + [current]
                current = copy.copy(current)

        else:
            member_functions_derived = member_functions_derived + [member_func]

        return member_functions_derived

    ###
    # given a parameter, this function generates text
    #
    # @param param the parameter that needs a textual translation
    #
    # @return a string representing the parameter
    ###
    def gen_param_text(self, param):
        text = "\n> "

        if param['type'] is not None:
            text = text + " " + self.wrap_text(param['type'], self.type_colour)

        text = text + " " + param['name']

        if self.display_defaults:
            if len(param['default']['name']) is not 0:
                text = text + " `= " + param['default']['name']

                if len(param['default']['value']) is not 0:
                    text = text + param['default']['value']

                text = text + "`"

        if 'description' in param.keys():
            text = text +" - " + param['description']

        text = text.encode('ascii','ignore')

        return text

    ###
    # given a list of member functions, this function returns a list of new lines for the
    # file currently being processed.
    #
    # @param class_name the name of the current class (found in the meta data)
    # @param member_functions the list of member_functions extracted from XML
    #
    # @return a list containing the new lines to be inserted into the current file.
    ###
    def gen_member_func_doc(self, class_name, member_functions):

        # this is what a member function dictionary contains.
        # function = {
        #     'short_name':"",
        #     'name':"",
        #     'return_type':"",
        #     'params':[],
        #     'description':[],
        #     'returns':"",
        #     'notes':"",
        #     'examples':"",
        #     'default':None
        # }

        lines = []

        for index, member_func in enumerate(member_functions,0):

            member_functions_derived = []

            if index is 0 or member_func['short_name'] != member_functions[index - 1]['short_name']:
                if class_name == member_func["short_name"]:
                    lines.append("##Constructor\n")
                else:
                    lines.append("##" + member_func["short_name"]+"\n")

            #we want to clearly separate our different level of functions in the DAL
            #so we present methods with defaults as overloads.
            if self.separate_defaults is True:
                member_functions_derived = member_functions_derived + self.derive_functions(member_func)

            for derived_func in member_functions_derived:
                #---- short name for urls ----
                lines.append("<br/>\n")

                short_name = ""

                if len(derived_func["return_type"]) is not 0:
                    short_name = "####" + self.wrap_text(derived_func["return_type"],self.type_colour) + " " +self.wrap_text(derived_func["short_name"], self.function_name_colour)  + "("
                else:
                    short_name = "####" + derived_func["short_name"] + "("

                last_param = None

                if len(derived_func['params']) is not 0:
                    last_param = derived_func['params'][-1]

                #generate parameters for the name of this function
                for param in derived_func['params']:
                    text = ""

                    if param['type'] is not None:
                        text = text + " " + self.wrap_text(param['type'], self.type_colour)

                    text = text + " " + param['name']

                    if param is not last_param:
                        short_name = short_name + text +", "
                    else:
                        short_name = short_name + text

                lines.append(short_name + ")\n")
                #-----------------------------

                #---- description ----
                if len(derived_func['description']) is not 0:
                    lines.append("#####Description\n")
                    lines.append(' '.join(derived_func['description']) + "\n")
                #-----------------------------

                #---- parameters ----
                if len(derived_func['params']) is not 0:
                    lines.append("#####Parameters\n")

                    for param in derived_func['params']:
                        lines.append(self.gen_param_text(param) + "\n")
                #-----------------------------

                #---- returns ----
                if len(derived_func['returns']) is not 0:
                    lines.append("#####Returns\n")
                    lines.append(derived_func['returns'] + "\n")
                #-----------------------------

                #---- examples ----
                if len(derived_func['examples']) is not 0:
                    lines.append("#####Example\n")
                    lines.append("```cpp\n")
                    lines.append(derived_func['examples'])
                    lines.append("```\n")
                #-----------------------------

                #---- notes ----
                if len(derived_func['notes']) is not 0:
                    lines.append("\n!!! note\n")
                    lines.append("    " + derived_func['notes'].replace('\n','\n    '))
                    lines.append('\n\n')
                #-----------------------------

        lines.append("____\n")

        return lines
