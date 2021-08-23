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

import PaginatedView from '@canvas/pagination/backbone/views/PaginatedView.coffee'
import RecentStudentView from './RecentStudentView.coffee'

export default class RecentStudentCollectionView extends PaginatedView

  initialize: (options) ->
    @collection.on 'add', @renderUser
    @collection.on 'reset', @render
    @paginationScrollContainer = @$el
    super

  render: =>
    ret = super
    @collection.each (user) => @renderUser user
    ret

  renderUser: (user) =>
    user.set('course_id', @collection.course_id, silent: true)
    @$el.append (new RecentStudentView model: user).render().el
