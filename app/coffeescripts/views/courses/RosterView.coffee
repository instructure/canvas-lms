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

define [
  'jquery'
  'underscore'
  'compiled/views/PaginatedView'
  'jst/courses/RosterUser'
], ($, _, PaginatedView, rosterUser) ->

  # This view displays a paginated collection of users inside of a course.
  #
  # @examples
  #
  #   view = RosterView.new
  #     el: $('...')
  #     collection: EnrollmentCollection.new(...')
  #
  #   view.collection.on('reset', view.render)
  class RosterView extends PaginatedView
    # Default options to be passed to the server on each request for new
    # collection records.
    fetchOptions:
      include: ['avatar_url']
      per_page: 50

    # Create and configure a new RosterView.
    #
    # @param el {jQuery} - The parent element (should have overflow: hidden and
    #   a height for infinite scroll).
    # @param collection {EnrollmentCollection} - The collection to retrieve
    #   results from.
    # @param options {Object} - Configuration options.
    #   - requestOptions: options to be passed w/ every server call.
    #
    # @examples
    #
    #   view = new RosterView
    #     el: $(...)
    #     collection: new EnrollmentCollection
    #       url: ...
    #       sections: ENV.SECTIONS
    #     requestOptions:
    #       type: ['StudentEnrollment']
    #       include: ['avatar_url']
    #       per_page: 25
    #
    # @api public
    # @return a RosterView.
    initialize: (options) ->
      @fetchOptions =
        data: _.extend({}, @fetchOptions, options.requestOptions)
        add: false
      @collection.on('reset', @render, this)
      @paginationScrollContainer = @$el
      @$el.disableWhileLoading(@collection.fetch(@fetchOptions))
      super(fetchOptions: @fetchOptions)

    # Append newly fetched records to the roster list.
    #
    # @api private
    # @return nothing.
    render: ->
      users       = @combinedSectionEnrollments(@collection)
      enrollments = _.map(users, @renderUser)
      @$el.append(enrollments.join(''))
      super

    # Create the HTML for a given user record.
    #
    # @param enrollment - An enrollment model.
    #
    # @api private
    # @return nothing.
    renderUser: (enrollment) ->
      rosterUser(enrollment.toJSON())

    # Take users in multiple sections and combine their section names
    # into an array to be displayed in a list.
    #
    # @param collection {EnrollmentCollection} - Enrollments to format.
    #
    # @api private
    # @return an array of user models.
    combinedSectionEnrollments: (collection) ->
      users       = collection.groupBy (enrollment) -> enrollment.get('user_id')
      enrollments = _.reduce users, (list, enrollments, key) ->
        enrollment = enrollments[0]
        names      = _.map(enrollments, (e) -> e.get('course_section_name'))
        # do it this way instead of calling .set(...) so that we don't fire an
        # extra page load from PaginatedView.
        enrollment.attributes.course_section_name = _.uniq(names)
        list.push(enrollment)
        list
      , []
      enrollments

