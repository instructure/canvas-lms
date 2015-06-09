module CustomColorHelper

  HEX_REGEX = /^#?(\h{3}|\h{6})$/.freeze

  # returns true or false if the provide value is a valid hex code
  def valid_hexcode?(hex_to_check)
    # Early escape if nil was passed in
    return false if hex_to_check.nil?
    # Check the hex to see if it matches our regex
    value = HEX_REGEX =~ hex_to_check
    # If there wasn't a match it returns null, so return the reverse of a null check
    !value.nil?
  end

  def normalize_hexcode(hex_to_normalize)
    if hex_to_normalize.start_with?('#')
      hex_to_normalize
    else
      hex_to_normalize.prepend('#')
    end
  end

end
