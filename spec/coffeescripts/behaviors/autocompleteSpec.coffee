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

  module 'autocomplete',

    teardown: ->
      $el.remove()

  test 'it should create an autocomplete box by reading data attributes', ->
    $('body').append($el)
    createAutocompletes()
    keys = (key for key of $('#autocomplete-box').data())

    ok _.include(keys, 'autocomplete')
    equal typeof $('#non-autocomplete-box').data('autocomplete'), 'undefined'

