#
# Copyright (C) 2011 - present Instructure, Inc.
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

define [ "jquery" ], (jQuery) ->
  $fixtures = jQuery("#fixtures")
  fixtures = {}
  fixtureId = 1
  (fixture) ->
    id = fixture + fixtureId++
    path = "fixtures/" + fixture + ".html"
    jQuery.ajax
      async: false
      cache: false
      dataType: "html"
      url: path
      success: (html) ->
        fixtures[id] = jQuery("<div/>",
          html: html
          id: id
        ).appendTo($fixtures)

      error: ->
        console.error "Failed to load fixture", path

    fixtures[id]
