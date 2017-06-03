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
