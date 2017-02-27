define [
  'jquery'
  'underscore'
  'compiled/behaviors/autocomplete'
], ($, _, createAutocompletes) ->

  options =
    delay: 150
    minLength: 4
    source: ['one', 'two', 'three']

  $el = $("""
  <div id="autocomplete-wrapper">
    <input type="text"
           id="autocomplete-box"
           data-behaviors="autocomplete"
           data-autocomplete-options='#{JSON.stringify(options)}' />

    <input type="text" id="non-autocomplete-box" />
  </div>
  """)

  QUnit.module 'autocomplete',
    teardown: ->
      $el.remove()
      $('#fixtures').empty()

  test 'it should create an autocomplete box by reading data attributes', ->
    $('#fixtures').append($el)
    createAutocompletes()
    keys = (key for key of $('#autocomplete-box').data())

    ok _.include(keys, 'autocomplete'), 'hi'
    equal typeof $('#non-autocomplete-box').data('autocomplete'), 'undefined', 'there'
