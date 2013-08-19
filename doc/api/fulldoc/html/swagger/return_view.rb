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
    nil
  end
end

class ReturnView < ReturnViewNull
  def initialize(line)
    if line
      @line = line.gsub(/\s+/m, " ").strip
    end
  end

  def array?
    if @line
      @line.include?('[') && @line.include?(']')
    else
      false
    end
  end

  def type
    if @line
      @line.gsub('[', '').gsub(']', '')
    else
      nil
    end
  end

  def to_swagger
    type
  end
end