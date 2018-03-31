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
  'jst/assignments/DateAvailableColumnView'
  'jquery'
  'underscore'
  '../../behaviors/tooltip'
], (Backbone, template, $, _) ->

  class DateAvailableColumnView extends Backbone.View
    template: template

    els:
      '.vdd_tooltip_link': '$link'

    afterRender: ->
      @$link.tooltip
        position: {my: 'center bottom', at: 'center top-10', collision: 'fit fit'},
        tooltipClass: 'center bottom vertical',
        content: -> $($(@).data('tooltipSelector')).html()

    toJSON: ->
      group = @model.defaultDates()

      data = @model.toView()
      data.defaultDates = group.toJSON()
      data.canManage    = @canManage()
      data.selector     = @model.get("id") + "_lock"
      data.linkHref     = @model.htmlUrl()
      data.allDates     = @model.allDates()
      data

    canManage: ->
      ENV.PERMISSIONS.manage
