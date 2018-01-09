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
  'underscore'
  '../../PaginatedCollectionView'
  './GroupView'
  './GroupUsersView'
  './GroupDetailView'
  '../../Filterable'
  'jst/groups/manage/groups'
], (_, PaginatedCollectionView, GroupView, GroupUsersView, GroupDetailView, Filterable, template) ->

  class GroupsView extends PaginatedCollectionView

    @mixin Filterable

    template: template

    els: Object.assign {}, # override Filterable's els, since our filter is in another view
      PaginatedCollectionView::els
      '.no-results': '$noResults'

    events: Object.assign {},
      PaginatedCollectionView::events
      'scroll': 'closeMenus'
      'dragstart': 'closeMenus'

    closeMenus: _.throttle ->
      for model in @collection.models
        model.itemView.closeMenus()
    , 50

    attach: ->
      @collection.on 'change', @reorder

    afterRender: ->
      @$filter = @$externalFilter
      super

    initialize: ->
      super
      @detachScroll() if @collection.loadAll

    createItemView: (group) ->
      groupUsersView = new GroupUsersView {
        model: group,
        collection: group.users(),
        itemViewOptions: {
          canEditGroupAssignment: not group.isLocked()
          markInactiveStudents: group.users()?.markInactiveStudents
        }
      }
      groupDetailView = new GroupDetailView {model: group, users: group.users()}
      groupView = new GroupView {
        model: group,
        groupUsersView,
        groupDetailView,
        addUnassignedMenu: @options.addUnassignedMenu
      }
      group.itemView = groupView

    updateDetails: ->
      for model in @collection.models
        model.itemView.updateFullState()
