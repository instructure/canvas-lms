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
  'underscore'
  'compiled/collections/PaginatedCollection'
  'compiled/models/Enrollment'
], (_, PaginatedCollection, Enrollment) ->

  # A collection for managing responses from EnrollmentsApiController.
  # Extends PaginatedCollection to allow for paging of returned results.
  class EnrollmentCollection extends PaginatedCollection
    model: Enrollment

    # Format returned responses by flattening the enrollment/user objects
    # returned and adding a section name if given sections.
    #
    # @param response {Object} - A parsed JSON object from the server.
    #
    # @api private
    # @return a formatted JSON response
    parse: (response) ->
      _.map(response, @flattenEnrollment)
      super

    # Add the returned user elements to the parent enrollment object to
    # make templating easier (e.g. remove all {{#with}} calls in Handlebars.
    #
    # @param enrollment {Object} - An enrollment object w/ a user sub-object.
    #
    # @api private
    # @return a formatted enrollment JSON object
    flattenEnrollment: (enrollment) =>
      id = enrollment.user.id
      delete enrollment.user.id
      enrollment[key] = value for key, value of enrollment.user
      enrollment.user.id = id
      @storeSection(enrollment) if @sections?
      enrollment

    # If the collection has been assigned a SectionCollection as @sections,
    # use the course_section_id to find the section name and add it as
    # course_section_name to the enrollment.
    #
    # NOTE: This function side-effects the passed enrollment to add the
    # given column. It doesn't return anything.
    #
    # @param enrollment {Object} - An enrollment object.
    #
    # @api private
    # @return nothing
    storeSection: (enrollment) ->
      section = @sections.find((section) -> section.get('id') == enrollment.course_section_id)
      enrollment.course_section_name = section.get('name')

