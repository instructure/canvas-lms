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
  'compiled/collections/EnrollmentCollection'
  'compiled/collections/SectionCollection'
  'compiled/views/courses/RosterView'
], ($, _, EnrollmentCollection, SectionCollection, RosterView) ->

  rosterPage =
    init: ->
      @loadEnvironment()
      @cacheElements()
      @createCollections()

    # Get the course ID and create the enrollments API url.
    #
    # @api public
    # @return nothing
    loadEnvironment: ->
      @course = ENV.context_asset_string.split('_')[1]
      @url    = "/api/v1/courses/#{@course}/enrollments"

    # Store DOM elements used.
    #
    # @api public
    # @return nothing
    cacheElements: ->
      @$studentList = $('.student_roster .user_list')
      @$teacherList = $('.teacher_roster .user_list')

    # Create the view and collection objects needed for the page.
    #
    # @api public
    # @return nothing
    createCollections: ->
      @sections    = new SectionCollection(ENV.SECTIONS)
      students     = new EnrollmentCollection
      teachers     = new EnrollmentCollection

      _.each [students, teachers], (c) =>
        c.url      = @url
        c.sections = @sections

      @studentView = new RosterView
        el: @$studentList
        collection: students
        requestOptions: type: ['StudentEnrollment']
      @teacherView = new RosterView
        el: @$teacherList
        collection: teachers
        requestOptions: type: ['TeacherEnrollment', 'TaEnrollment']

  # Start loading the page.
  rosterPage.init()
