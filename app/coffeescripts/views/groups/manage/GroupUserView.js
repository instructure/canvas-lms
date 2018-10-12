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
  'jst/groups/manage/groupUser'
], ({View}, template) ->

  class GroupUserView extends View

    @optionProperty 'canAssignToGroup'
    @optionProperty 'canEditGroupAssignment'

    tagName: 'li'

    className: 'group-user'

    template: template

    els:
      '.al-trigger': '$userActions'

    closeMenu: ->
      @$userActions.data('kyleMenu')?.$menu.popup 'close'

    attach: ->
      @model.on 'change', @render, this

    afterRender: ->
      @$el.data('model', @model)

    highlight: ->
      @$el.addClass 'group-user-highlight'
      setTimeout =>
        @$el.removeClass 'group-user-highlight'
      , 1000

    toJSON: ->
      result = Object.assign {groupId: @model.get('group')?.id}, this, super
      result.shouldMarkInactive =
        @options.markInactiveStudents && @model.attributes.is_inactive
      result.isLeader = @isLeader()
      result

    isLeader: ->
      @model.get('group')?.get?('leader')?.id == @model.get('id')
