#
# Copyright (C) 2013 Instructure, Inc.
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
#

define [
  'Backbone'
  'compiled/collections/GroupUserCollection'
], (Backbone, GroupUserCollection) ->

  class Group extends Backbone.Model
    modelType: 'group'
    resourceName: 'groups'

    initialize: (attrs, options) ->
      super
      @newAndEmpty = options?.newAndEmpty

    users: ->
      initialUsers = if @newAndEmpty then [] else null
      @_users = new GroupUserCollection initialUsers,
        group: this
        category: @collection?.category
      @_users.on 'fetched:last', => @set('members_count', @_users.length)
      @users = -> @_users
      @_users

    usersCount: ->
      @get('members_count')

    sync: (method, model, options = {}) ->
      options.url = @urlFor(method)
      Backbone.sync method, model, options

    urlFor: (method) ->
      if method is 'create'
        "/api/v1/group_categories/#{@get('group_category_id')}/groups"
      else
        "/api/v1/groups/#{@id}"

    theLimit: ->
      max_membership = @get('max_membership')
      max_membership or @collection?.category?.get('group_limit')

    isFull: ->
      limit = @get('max_membership')
      (!limit and @groupCategoryLimitMet()) or (limit and @get('members_count') >= limit)

    groupCategoryLimitMet: ->
      limit = @collection?.category?.get('group_limit')
      limit and @get('members_count') >= limit

    isLocked: ->
      @collection?.category?.isLocked()

    toJSON: ->
      if ENV.student_mode
        {name: @get('name')}
      else
        json = super
        json.isFull = @isFull()
        json
