class BooleanTranslator
  def self.value_to_boolean(value)
    return value if [true, false].include?(value)
    return true if ["yes", "true", "on"].include?(value)
    return false if ["no", "false", "off"].include?(value.to_s.downcase)
    return value.to_i != 0
  end
end
