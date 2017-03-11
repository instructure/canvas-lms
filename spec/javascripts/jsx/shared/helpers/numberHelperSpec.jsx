define([
  'jsx/shared/helpers/numberHelper',
  'i18nObj',
  'helpers/I18nStubber'
], (numberHelper, I18n, I18nStubber) => {

  let input, output, delimiter, separator

  QUnit.module('Number Helper Parse and Validate', {
    setup () {
      delimiter = ' '
      separator = ','
      I18nStubber.pushFrame()
      I18nStubber.stub('foo', {
        number: {
          format: {
            delimiter,
            separator,
            precision: 3,
            strip_insignificant_zeros: false
          }
        }
      })
      I18nStubber.setLocale('foo')

      input = '47'
      output = 47
      sinon.stub(numberHelper, '_parseNumber').returns(output)
    },

    teardown () {
      I18nStubber.popFrame()
      if (numberHelper._parseNumber.restore) {
        numberHelper._parseNumber.restore()
      }
    }
  })

  test('uses default parse function', () => {
    numberHelper._parseNumber.restore()
    equal(numberHelper.parse(`1${delimiter}000${separator}2`), 1000.2)
  })

  test('returns NaN for invalid numbers', () => {
    numberHelper._parseNumber.restore()
    ok(isNaN(numberHelper.parse('foo')))
  })

  test('returns value of parse function', () => {
    equal(numberHelper.parse('1'), output)
  })

  test('uses delimiter and separator from current locale', () => {
    numberHelper.parse(input)
    ok(numberHelper._parseNumber.calledWithMatch(input, {
      thousands: delimiter,
      decimal: separator
    }))
  })

  test('uses default delimiter and separator if not a valid number', () => {
    numberHelper._parseNumber.onFirstCall().returns(NaN)
    const ret = numberHelper.parse(input)
    ok(numberHelper._parseNumber.secondCall.calledWithExactly, input)
    equal(ret, output)
  })

  test('returns NaN for null and undefined values', () => {
    ok(isNaN(numberHelper.parse(null)))
    ok(isNaN(numberHelper.parse(undefined)))
  })

  test('returns input if already a number', () => {
    const input = 4.7
    equal(numberHelper.parse(input), input)
  })

  test('parses toString value of objects', () => {
    numberHelper._parseNumber.restore()
    const obj = {toString: () => `2${separator}3`}
    equal(numberHelper.parse(obj), 2.3)
  })

  test('parses positive numbers beginning with "+"', () => {
    numberHelper._parseNumber.restore()
    equal(numberHelper.parse('+4'), 4)
  })

  test('validate returns false if parse returns NaN', () => {
    numberHelper._parseNumber.returns(NaN)
    equal(numberHelper.validate('1'), false)
  })

  test('validate returns true if parse returns a number', () => {
    numberHelper._parseNumber.returns(1)
    equal(numberHelper.validate('1'), true)
  })
})
