require 'yaml'

module MimetypeFu
  EXTENSIONS = YAML.load_file(File.dirname(__FILE__) + '/mime_types.yml')
end