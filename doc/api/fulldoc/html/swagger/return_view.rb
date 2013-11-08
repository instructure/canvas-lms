require 'hash_view'

class ReturnViewNull < HashView
  def array?; false; end

  def type; nil; end

  def to_hash
    {
      "array" => array?,
      "type" => format(type),
    }
  end

  def to_swagger
    {
      "type" => "void"
    }
  end
end

class ReturnView < ReturnViewNull
  def initialize(line)
    if line
      @line = line.gsub(/\s+/m, " ").strip
    else
      raise "@return type required"
    end
  end

  def array?
    @line.include?('[') && @line.include?(']')
  end

  def type
    @line.gsub('[', '').gsub(']', '')
  end

  def to_swagger
    if array? and type
      {
        "type" => "array",
        "items" => {
          "$ref" => type
        }
      }
    else
      {
        "type" => type
      }
    end
  end
end