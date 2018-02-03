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
  'i18n!GroupUserCollection'
  'jquery'
  '../collections/PaginatedCollection'
  '../models/GroupUser'
  'str/htmlEscape'
], (I18n, $, PaginatedCollection, GroupUser, h) ->

  class GroupUserCollection extends PaginatedCollection

    comparator: (user) -> user.get('sortable_name').toLowerCase()

    @optionProperty 'group'
    @optionProperty 'category'
    @optionProperty 'markInactiveStudents'

    url: ->
      url_base = "/api/v1/groups/#{@group.id}/users?"
      params = {
        per_page: 50
        include: ['sections', 'group_submissions']
        exclude: ['pseudonym']
      }

      if @markInactiveStudents
        params.include.push('active_status')

      url_base + $.param(params)

    initialize: (models) ->
      super
      @loaded = @loadedAll = models?
      @on 'change:group', @onChangeGroup
      @model = GroupUser.extend defaults: {group: @group, @category}

    load: (target = 'all') ->
      @loadAll = target is 'all'
      @loaded = true
      @fetch() if target isnt 'none'
      @load = ->

    onChangeGroup: (model, group) =>
      @removeUser model
      @groupUsersFor(group)?.addUser model

    membershipsLocked: ->
      false

    getUser: (asset_string) ->
      @get(asset_string.replace("user_", ""))

    addUser: (user) ->
      if @membershipsLocked()
        @get(user)?.moved()
        return

      if @loaded
        if @get(user)
          @flashAlreadyInGroupError user
        else
          @add user
          @increment 1
        user.moved()
      else
        user.once 'ajaxJoinGroupSuccess', (data) =>
          return if data.just_created
          # uh oh, we already had this user -- undo the increment and flash an error.
          @increment -1
          @flashAlreadyInGroupError user
        @increment 1

    flashAlreadyInGroupError: (user) ->
      $.flashError I18n.t 'flash.userAlreadyInGroup',
        "WARNING: %{user} is already a member of %{group}",
        user: h(user.get('name'))
        group: h(@group.get('name'))

    removeUser: (user) ->
      return if @membershipsLocked()
      @increment -1
      @group.set('leader', null) if @group?.get('leader')?.id == user.id
      @remove user if @loaded

    increment: (amount) ->
      @group.increment 'members_count', amount

    groupUsersFor: (group) ->
      @category?.groupUsersFor(group)
