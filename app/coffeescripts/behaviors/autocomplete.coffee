#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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

