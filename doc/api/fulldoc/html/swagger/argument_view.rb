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
    clean_line = line.gsub(/\s+/m, " ")
    name, remaining = clean_line.scan(/^([^\s]+)(.*)$/).first
    name.strip! if @name
    if remaining
      type, desc = split_type_desc(remaining)
      # type = format(type.strip.gsub('[', '').gsub(']', '')) if type
      type.strip! if type
      desc.strip! if desc
    end
    [clean_line, name, type, desc]
  end

  # Atrocious use of regex to parse out type signatures such as:
  # "[[Integer], Optional] The IDs of the override's target students."
  def split_type_desc(str)
    type_desc_parts_to_pair(
      str.strip.
      # turn "] ," into "],"
      gsub(/\]\s+,/, '],').
      # put "|||" between type and desc
      sub(/[^,] /){ |s| s[0] == ']' ? s[0] + '|||' : s }.
      # split on "|||"
      split('|||')
    )
  end

  def type_desc_parts_to_pair(parts)
    case parts.size
    when 0 then [DEFAULT_TYPE, DEFAULT_DESC]
    when 1 then
      if parts.first.include?('[') and parts.first.include?(']')
        [parts.first, DEFAULT_DESC]
      else
        [DEFAULT_TYPE, parts.first]
      end
    when 2 then
      parts
    else
      raise "Too many parts while splitting type and description: #{parts.inspect}"
    end
  end

  def name
    format(@name.gsub('[]', ''))
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
      when 'put', 'post' then   'form'
      else
        raise "Unknown HTTP verb: #{@verb}"
      end
    end
  end

  def swagger_type
    (types.first || 'string').downcase
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
    ["string", "integer"].include?(type)
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