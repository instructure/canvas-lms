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
  '../../SelectView',
  'jst/courses/roster/roleSelect'
], (SelectView, template) ->

  class RoleSelectView extends SelectView
    @optionProperty 'rolesCollection'
    template: template

    attach: ->
      @rolesCollection.on 'add reset remove change', @render

    toJSON: ->
      roles: @rolesCollection.toJSON()
      selectedRole: if @el.selectedOptions?.length
        this.el.selectedOptions[0].value
      else
        ""
