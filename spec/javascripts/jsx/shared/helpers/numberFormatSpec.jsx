define([
  'jsx/shared/helpers/numberFormat',
  'i18nObj'
], (numberFormat, I18n) => {

  QUnit.module('numberFormat _format', {
    teardown () {
      if (I18n.n.restore) {
        I18n.n.restore()
      }
    }
  })

  test('passes through non-numbers', () => {
    equal(numberFormat._format('foo'), 'foo')
    ok(isNaN(numberFormat._format(NaN)))
  })

  test('proxies to I18n for numbers', () => {
    sinon.stub(I18n, 'n').returns('1,23')
    equal(numberFormat._format(1.23, { foo: 'bar' }), '1,23')
    ok(I18n.n.calledWithMatch(1.23, { foo: 'bar' }))
  })

  QUnit.module('numberFormat outcomeScore')

  test('requests precision 2', () => {
    equal(numberFormat.outcomeScore(1.234), '1.23')
  })

  test('requests strip insignificant zeros', () => {
    equal(numberFormat.outcomeScore(1.00001), '1')
  })
})
