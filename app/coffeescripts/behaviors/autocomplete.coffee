##
# behaviors/autocomplete.coffee
#
# Create jQueryUI autocomplete widgets from all inputs with "autocomplete"
# as part of their data-behaviors attribute. Configure using a JSON object
# in the data-autocomplete-options attribute.
#
# Examples
#
# // HTML
# // <input type="text"
# //        name="search"
# //        data-behaviors="autocomplete"
# //        data-autocomplete-options="{\"minLength\": 4, \"source\": [1, 2, 3]}" />
#
# // Require the bundle
# require('compiled/bundles/autocomplete');
#
# To configure event handlers in the autocomplete-options attribute, pass a
# self-executing function as a string, e.g.
#
# data-autocomplete-options="\"select:\" \"(function(){ return function(e, ui) { ... } })();\"  "
define ['jquery', 'jqueryui/autocomplete'], ($) ->

  createAutocompletes = ->
    $('input[data-behaviors~=autocomplete]').each ->
      $el     = $(this)
      options = $el.data('autocomplete-options')
      $el.autocomplete(options)

  $(document).ready -> createAutocompletes()

  createAutocompletes

