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
  '../DialogFormView'
  '../../models/UserSettings'
  'jst/DiscussionTopics/UserSettingsView'
], (I18n, DialogFormView, UserSettings, template) ->

  class UserSettingsView extends DialogFormView

    defaults:
      title: I18n.t "edit_settings", "Edit Discussions Settings"

    template: template

    initialize: ->
      super
      @model or= new UserSettings
      @attachModel()
      @fetch()

    attachModel: ->
      @model.on 'change', @render

    fetch: ->
      @$el.disableWhileLoading(@model.fetch())

