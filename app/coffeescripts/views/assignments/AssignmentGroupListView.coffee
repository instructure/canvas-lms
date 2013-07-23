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
  'underscore'
  'compiled/class/cache'
  'compiled/views/CollectionView'
  'compiled/views/assignments/AssignmentGroupListItemView'
  'jst/assignments/AssignmentGroupList'
], (_, Cache, CollectionView, AssignmentGroupListItemView, template) ->

  class AssignmentGroupListView extends CollectionView
    template: template
    itemView: AssignmentGroupListItemView

    initialize: ->
      super
      $.extend true, @, Cache
      @firstResetLanded = @collection.length > 0

    render: ->
      data = super
      @collapseFromCache()
      data

    renderOnReset: =>
      @firstResetLanded = true
      super

    toJSON: ->
      data = super
      _.extend({}, data,
        firstResetLanded: @firstResetLanded
      )

    # This will be used when we implement searching
    expandAll: ->
      for m in @collection.models
        if !m.groupView.isExpanded()
            #force expand it
            #but it will retain it's state in cache
            m.groupView.toggle()

    #also can be used to collapse after searching
    collapseFromCache: ->
      for m in @collection.models
        if !m.groupView.isExpanded()
          #collapse it
          m.groupView.toggle()
