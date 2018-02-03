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
  'i18n!discussions'
  'jquery'
  '../DialogFormView'
  '../../models/DiscussionsSettings'
  '../../models/UserSettings'
  'jst/DiscussionTopics/DiscussionsSettingsView'
], (I18n, $, DialogFormView, DiscussionsSettings, UserSettings, template) ->

  class DiscussionsSettingsView extends DialogFormView

    defaults:
      title: I18n.t "edit_settings", "Edit Discussions Settings"

    template: template

    initialize: ->
      super
      @model      or= new DiscussionsSettings
      @userSettings = new UserSettings
      @fetch()

    render: () ->
      super(arguments)
      @$el
        .find('#manual_mark_as_read')
        .prop('checked', @userSettings.get('manual_mark_as_read'))

    submit: (event) ->
      super(event)
      @userSettings.set('manual_mark_as_read', @$el.find('#manual_mark_as_read').prop('checked'))
      @userSettings.save()

    fetch: ->
      isComplete = $.Deferred()
      $.when(@model.fetch(), @userSettings.fetch()).then =>
        isComplete.resolve()
        @render()
      @$el.disableWhileLoading(isComplete)

