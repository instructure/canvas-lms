define([
  'jsx/shared/helpers/urlHelper',
], ({ encodeSpecialChars, decodeSpecialChars }) => {
  module('Url Helper')

  test('encodes % properly', () => {
    equal(encodeSpecialChars('/some/path%thing'), '/some/path&#37;thing')
  })

  test('decodes the encoded % properly', () => {
    equal(decodeSpecialChars('/some/path%26%2337%3Bthing'), '/some/path%25thing')
  })
})
