#
# Copyright (C) 2014 - present Instructure, Inc.
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
  'compiled/views/CollectionView'
  'compiled/views/grade_summary/GroupView'
  'jst/grade_summary/section'
], ({View, Collection}, _, CollectionView, GroupView, template) ->

  class SectionView extends View
    tagName: 'li'
    className: 'section'

    els:
      '.groups': '$groups'

    template: template

    render: ->
      super
      groupsView = new CollectionView
        el: @$groups
        collection: @model.get('groups')
        itemView: GroupView
      groupsView.render()
