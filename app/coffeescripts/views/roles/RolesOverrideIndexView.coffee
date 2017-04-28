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
  'Backbone'
  'jst/roles/rolesOverrideIndex'
], ($, _, Backbone, template) ->
  class RolesOverrideIndexView extends Backbone.View

    template: template

    els:
      "#role_tabs": "$roleTabs"

    # Method Summary
    #   Enable tabs for account/course roles.
    # @api custom backbone override
    afterRender: ->
      @$roleTabs.tabs()

    toJSON: ->
      @options
