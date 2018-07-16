#
# Copyright (C) 2013 - present Instructure, Inc.
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
  'Backbone'
  'jst/assignments/DateDueColumnView'
  'jquery'
  '../../behaviors/tooltip'
], (Backbone, template, $) ->

  class DateDueColumnView extends Backbone.View
    template: template

    els:
      '.vdd_tooltip_link': '$link'

    afterRender: ->
      @$link.tooltip
        position: {my: 'center bottom', at: 'center top-10', collision: 'fit fit'},
        tooltipClass: 'center bottom vertical',
        content: -> $($(@).data('tooltipSelector')).html()

    # has to handle both the discusson's model,
    # and a graded discussion's child assignment model
    toJSON: ->
      data = @model.toView()
      m = @model.get('assignment') || @model

      data.selector  = m.get("id") + "_due"
      data.linkHref  = m.htmlUrl()
      data.allDates  = m.allDates()
      data
