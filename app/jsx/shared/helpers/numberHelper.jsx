define([
  'parse-decimal-number',
  'i18nObj'
], (parseNumber, I18n) => {

  const helper = {
    _parseNumber: parseNumber,

    parse (input) {
      if (input == null) {
        return NaN
      } else if (typeof input === 'number') {
        return input
      }

      let inputStr = input.toString()

      // this hack can be removed once this gets merged:
      // https://github.com/AndreasPizsa/parse-decimal-number/pull/5
      inputStr = inputStr.replace(/^\+/, '')

      let num = helper._parseNumber(inputStr, {
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
