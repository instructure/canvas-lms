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
  'jst/accounts/admin_tools/authLoggingItem'
  'i18n!auth_logging'
], (Backbone, template, I18n) ->

  class AuthLoggingItemView extends Backbone.View

    tagName: 'tr'

    className: 'logitem'

    template: template

    toJSON: ->
      json = super
      if json.event_type == "login"
        json.event = I18n.t("login", "LOGIN")
      else if json.event_type == "logout"
        json.event = I18n.t("logout", "LOGOUT")
      else if json.event_type == "corrupted"
        json.event = I18n.t("corrupted", "Details Not Available")
      json
