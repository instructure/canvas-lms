#
# Copyright (C) 2012 Instructure, Inc.
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

require [
  'jquery'
  'underscore'
  'compiled/collections/UserCollection'
  'compiled/collections/SectionCollection'
  'compiled/views/courses/RosterView'
  'jst/courses/Roster'
], ($, _, UserCollection, SectionCollection, RosterView, roster) ->

  # Load environment
  course       = ENV.context_asset_string.split('_')[1]
  url          = "/api/v1/courses/#{course}/users"
  fetchOptions =
    include: ['avatar_url', 'enrollments', 'email']
    per_page: 50

  sections     = new SectionCollection(ENV.SECTIONS)
  columns =
    students: $('.roster .student_roster')
    teachers: $('.roster .teacher_roster')

  for roster_data in ENV.COURSE_ROSTERS
    users = new UserCollection
    users.url = url
    users.sections = sections
    users.roles = roster_data['roles']

    usersOptions = add: false, data: _.extend({}, fetchOptions, enrollment_role: roster_data['roles'])

    column = columns[roster_data['column']]
    html = roster
      title: roster_data['title']
    column.append(html)
    list = column.find('.user_list').last()

    usersView = new RosterView
      collection: users
      el: list
      fetchOptions: usersOptions

    users.on('reset', usersView.render, usersView)
    usersView.$el.disableWhileLoading(users.fetch(usersOptions))