require 'hash_view'

class ArgumentView < HashView
  attr_reader :line, :http_verb, :path_variables
  attr_reader :name, :type, :desc

  DEFAULT_TYPE = "[String]"
  DEFAULT_DESC = "no description"

  def initialize(line, http_verb = "get", path_variables = [])
    @line, @name, @type, @desc = parse_line(line)
    @http_verb = http_verb
    @path_variables = path_variables
    parse_line(@line)
  end

  def parse_line(line)
    name, remaining = (line || "").split(/\s/, 2)
    raise(ArgumentError, "param name missing:\n#{line}") unless name
    name.strip!
    type, desc = split_type_desc(remaining || "")
    type.strip!
    desc.strip!
    [line, name, type, desc]
  end

  def split_type_desc(str)
    # This regex is impossible to read, basically we're splitting the string up
    # into the first [bracketed] section, which might contain internal brackets,
    # and then the rest of the string.
    md = str.strip.match(%r{\A(\[[\w ,\[\]\|"]+\])?\s*(.+)?}m)
    [md[1] || DEFAULT_TYPE, md[2] || DEFAULT_DESC]
  end

  def name(json: true)
    name = json ? @name.gsub('[]', '') : @name
    format(name)
  end

  def desc
    format(@desc)
  end

  def remove_outer_square_brackets(str)
    str.sub(/^\[/, '').sub(/\]$/, '')
  end

  def metadata_parts
    remove_outer_square_brackets(@type).
      split(/\s*[,\|]\s*/).map{ |t| t.force_encoding('UTF-8') }
  end

  def enum_and_types
    metadata_parts.partition{ |t| t.include? '"' }
  end

  def enums
    enum_and_types.first.map { |e| e.gsub('"', '') }
  end

  def types
    enum_and_types.last.reject do |t|
      %w(optional required).include?(t.downcase)
    end
  end

  def swagger_param_type
    if @path_variables.include? name
      'path'
    else
      case @http_verb.downcase
      when 'get', 'delete' then 'query'
      when 'put', 'post', 'patch' then 'form'
      else
        raise "Unknown HTTP verb: #{@http_verb}"
      end
    end
  end

  def swagger_type
    type = (types.first || 'string')
    builtin?(type) ? type.downcase : type
  end

  def swagger_format
    case swagger_type
    when 'integer' then 'int64'
    else nil
    end
  end

  def optional?
    not required?
  end

  def required?
    types = enum_and_types.last.map{ |t| t.downcase }
    if swagger_param_type == 'path'
      true
    elsif types.include?('required')
      true
    else
      false
    end
  end

  def array?
    @name.include?('[]')
  end

  def builtin?(type)
    ["string", "integer", "boolean", "number"].include?(type.downcase)
  end

  def to_swagger
    swagger = {
      "paramType" => swagger_param_type,
      "name" => name,
      "description" => desc,
      "type" => swagger_type,
      "format" => swagger_format,
      "required" => required?,
    }
    swagger['enum'] = enums unless enums.empty?
    if array?
      swagger["type"] = "array"
      items = {}
      if builtin?(swagger_type)
        items["type"] = swagger_type
      else
        items["$ref"] = swagger_type
      end
      swagger["items"] = items
    end
    swagger
  end

  def to_hash
    {
      "name"     => name,
      "desc"     => desc,
      "types"    => types,
      "optional" => optional?,
    }
  end
end
