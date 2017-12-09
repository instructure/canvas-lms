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
  'jquery'
  'Backbone'
  'jst/gradebook/total_column_header'
], ($, Backbone, template) ->

  class TotalColumnHeaderView extends Backbone.View

    el: '#total_column_header'

    events:
      "click .toggle_percent": "togglePercent"
      "click .move_column": "moveColumn"

    template: template

    togglePercent: =>
      @options.toggleShowingPoints()
      false

    switchTotalDisplay: (showAsPoints) =>
      @options.showingPoints = showAsPoints
      @render()

    moveColumn: =>
      @options.moveTotalColumn()
      @render()
      false

    render: ->
      # the menu doesn't live in @$el, so remove it manually
      @$menu.remove() if @$menu

      super()

      @$menu = @$el.find('.gradebook-header-menu')
      @$el.find('#total_dropdown').kyleMenu
        noButton: true
        appendMenuTo: '#gradebook_grid'
      @$menu.css('width', '150')

      this

    toJSON: ->
      json =
        showingPoints: @options.showingPoints
        weightedGrades: @options.weightedGrades
        totalColumnInFront: @options.totalColumnInFront
