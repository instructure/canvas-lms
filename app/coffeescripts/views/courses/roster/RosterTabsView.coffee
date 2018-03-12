#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'Backbone'
  'jst/courses/roster/rosterTabs'
], ($, _, Backbone, template) ->

  class RosterTabsView extends Backbone.View
    template: template

    tagName: 'li'
    className: 'collectionViewItems ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all'


    attach: ->
      @collection.on 'reset', @render, this

    fetch: ->
      if ENV.canManageCourse
        @collection.fetch()

    render: ->
      super
      @refreshTabs()

    refreshTabs: ->
      $tabs = $('#group_categories_tabs')
      $tabs.tabs().show()
      $tabs.tabs
        beforeActivate: (event, ui) ->
          ui.newTab.hasClass('static')

      $groupTabs = $tabs.find('li').not('.static')
      $groupTabs.find('a').unbind()
      $groupTabs.on 'keydown', (event) ->
        event.stopPropagation()
        if event.keyCode == 13 or event.keyCode == 32
          window.location.href = $(this).find('a').attr('href')

    toJSON: ->
      json = {}
      json.collection = super
      json.course = ENV.course
      json
