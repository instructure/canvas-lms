define [
  'ember'
], (Ember) ->

  # example usage:
  #
  #   {{numeric-field
  #     min=0
  #     max=1440
  #     allowDecimal=false
  #     allowNegative=false
  #   }}

  NumericFieldComponent = Ember.TextField.extend
    type: 'text'
    classNameBindings: 'isValid:valid:invalid'

    min: 0
    max: 1440
    allowDecimal: true
    allowNegative: true

    isValid: ( ->
      return true unless rawValue = @get('value')
      intValue = parseInt(rawValue)
      rawValue && intValue >= @get('min') && intValue <= @get('max')
    ).property('value')

    keyPress: (evt) ->
      code = if evt.which != undefined then evt.which else evt.keyCode

      # delete, backspace, tab, end, home, left, right
      controlKeys = Ember.A([0, 8, 9, 35, 36, 37, 39])
      return true if controlKeys.contains(code)

      validDecimal  = @get("allowDecimal")  and code == 46
      validNegative = @get("allowNegative") and code == 45
      validNumber   = code > 47 and code < 58
      return false if !validDecimal && !validNegative && !validNumber
