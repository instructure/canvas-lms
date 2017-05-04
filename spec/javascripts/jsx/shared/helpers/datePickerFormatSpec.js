import I18n from 'i18n!calendar'
import datePickerFormat from 'jsx/shared/helpers/datePickerFormat'

QUnit.module('Date Picker Format Spec')

test('formats medium with weekday correcly', () => {
  const format = datePickerFormat(I18n.t('#date.formats.medium_with_weekday'))
  equal(format, 'D M d, yy')
})

test('formats medium correctly', () => {
  const format = datePickerFormat(I18n.t('#date.formats.medium'))
  equal(format, 'M d, yy')
})
