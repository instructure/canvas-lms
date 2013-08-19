class HashView
  def to_hash
    {}
  end

protected
  def format(str)
    str.to_s.force_encoding('UTF-8') if str
  end
end
