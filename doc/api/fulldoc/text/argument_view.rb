require 'hash_view'

class ArgumentView < HashView
  attr_reader :line

  def initialize(line)
    @line = line.gsub(/\s+/m, " ")
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
    format(@name)
  end

  def desc
    format(@desc)
  end

  def type_parts
    (@type || '').split(/\s*[,\|]\s*/).
      map{ |t| t.force_encoding('UTF-8') }
  end

  def types
    type_parts.reject{ |t| %w(optional required).include?(t.downcase) }
  end

  def optional?
    type_parts.map{ |t| t.downcase }.include?('optional')
  end

  def required?
    !!optional?
  end

  def to_swagger
    {
      "paramType" => "path",
      "name" => name,
      "description" => desc,
      "type" => types.first,
      # "format" => "",
      "required" => required?,
    }
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