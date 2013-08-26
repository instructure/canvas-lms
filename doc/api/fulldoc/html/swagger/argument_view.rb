require 'hash_view'

class ArgumentView < HashView
  attr_reader :line

  def initialize(line, http_verb = "get", path_variables = [])
    @line = line.gsub(/\s+/m, " ")
    @http_verb = http_verb
    @path_variables = path_variables
    @name, remaining = @line.scan(/^([^\s]+)(.*)$/).first
    @type, @desc = parse_type_desc(remaining)
    # debugger
    @name.strip! if @name
    @type = format(@type.strip.gsub('[', '').gsub(']', '')) if @type
    @desc.strip! if @desc
  end

  # Atrocious use of regex to parse out type signatures such as:
  # "[[Integer], Optional] The IDs of the override's target students."
  def parse_type_desc(str)
    parts = str.strip.
      gsub(/\]\s+,/, '],'). # turn "] ," into "],"
      gsub(/[^,] /){ |s| s[0] == ']' ? s[0] + '|||' : s }. # put "|||" between type and desc
      split('|||')
    if parts.size == 1
      [nil, parts.first]
    else
      parts
    end
  end

  def name
    format(@name.gsub('[]', ''))
  end

  def desc
    format(@desc)
  end

  def metadata_parts
    (@type || '').split(/\s*[,\|]\s*/).map{ |t| t.force_encoding('UTF-8') }
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
    enum_and_types.last.include?('optional')
  end

  def required?
    !!optional?
  end

  def array?
    @name.include?('[]')
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
    swagger['tags'] = {"type" => "array"} if array?
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