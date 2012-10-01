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
], ($, _, UserCollection, SectionCollection, RosterView) ->

  # Load environment
  course       = ENV.context_asset_string.split('_')[1]
  url          = "/api/v1/courses/#{course}/users"
  fetchOptions =
    include: ['avatar_url', 'enrollments', 'email']
    per_page: 50

  # Cache elements
  $studentList = $('.student_roster .user_list')
  $teacherList = $('.teacher_roster .user_list')

  # Create views
  sections = new SectionCollection(ENV.SECTIONS)
  students = new UserCollection
  teachers = new UserCollection

  _.each [students, teachers], (c) ->
    c.url      = url
    c.sections = sections

  studentOptions = add: false, data: _.extend({}, fetchOptions, enrollment_type: 'student')
  teacherOptions = add: false, data: _.extend({}, fetchOptions, enrollment_type: ['teacher', 'ta'])

  studentView = new RosterView
    collection: students
    el: $studentList
    fetchOptions: studentOptions
  teacherView = new RosterView
    collection: teachers
    el: $teacherList
    fetchOptions: teacherOptions

  # Add events
  students.on('reset', studentView.render, studentView)
  teachers.on('reset', teacherView.render, teacherView)

  # Fetch roster
  studentView.$el.disableWhileLoading(students.fetch(studentOptions))
  teacherView.$el.disableWhileLoading(teachers.fetch(teacherOptions))

