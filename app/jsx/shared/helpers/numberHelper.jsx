define([
  'parse-decimal-number',
  'i18nObj'
], (parseNumber, I18n) => {

  const helper = {
    _parseNumber: parseNumber,

    parse (input) {
      let num = helper._parseNumber(input, {
        thousands: I18n.lookup('number.format.delimiter'),
        decimal: I18n.lookup('number.format.separator')
      })

      // fallback to default delimiters if invalid with locale specific ones
      if (isNaN(num)) {
        num = helper._parseNumber(input)
      }

      return num
    },

    validate (input) {
      return !isNaN(helper.parse(input))
    }
  }

  return helper
})
