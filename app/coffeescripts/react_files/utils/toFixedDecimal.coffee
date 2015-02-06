define [], ()->

  # Converts a number to the given number of decimal places, only when needed.
  # You have the option of calling it using either of these two ways:
  #
  # With Parameters:
  #   toFixedDecimal(3.14159, 3) => 3.141
  #
  # With Object:
  #   toFixedDecimal({number: 3.14159, decimals: 2}) => 3.14
  toFixedDecimal = (number, decimalPlaces) ->
    # This is a slightly weak check, but it will suffice for now, just make
    # sure you use a plain object and not an array, etc.
    if typeof number != 'number'
      decimalPlaces = number?.decimals
      number = number?.number
    parseFloat(number.toFixed(decimalPlaces))
