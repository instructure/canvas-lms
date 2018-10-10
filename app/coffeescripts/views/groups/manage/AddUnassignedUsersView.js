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
  'underscore'
  '../../CollectionView'
  'jst/groups/manage/addUnassignedUsers'
  'jst/groups/manage/addUnassignedUser'
], ({View}, _, CollectionView, template, itemTemplate) ->

  class AddUnassignedUsersView extends CollectionView

    initialize: (options) ->
      super _.extend {}, options,
        itemView: View.extend tagName: 'li'
        itemViewOptions:
          template: itemTemplate

    template: template

    attach: ->
      @collection.on 'add remove change reset', @render
      @collection.on 'setParam deleteParam', @checkParam

    checkParam: (param, value) =>
      @lastRequest?.abort()
      @collection.termError = value is false
      if value
        @lastRequest = @collection.fetch()
      else
        @render()

    toJSON: ->
      users: @collection.toJSON()
      term: @collection.options.params?.search_term
      termError: @collection.termError
