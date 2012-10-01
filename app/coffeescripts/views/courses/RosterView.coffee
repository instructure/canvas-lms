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

  # RosterView: Display a paginated collection of users inside of a course.
  #
  # Examples
  #
  #   view = new RosterView el: $('..'), collection: new UserCollection(...)
  #   view.collection.on('reset', view.render, view)
  #   view.collection.fetch(...)
  class RosterView extends PaginatedView
    # Public: Create a new instance.
    #
    # fetchOptions - Options to be passed to @collection.fetch(). Needs to be
    #   passed for subsequent page gets (see PaginatedView).
    initialize: ({fetchOptions}) ->
      @paginationScrollContainer = @$el
      super(fetchOptions: fetchOptions)

    # Public: Append new records to the roster list.
    #
    # Returns nothing.
    render: ->
      @combineSectionNames(@collection)
      @appendCourseId(@collection)
      html = _.map(@collection.models, @renderUser)
      @$el.append(html.join(''))
      super

    # Public: Return HTML for a given record.
    #
    # user - The user object to render as HTML.
    #
    # Returns an HTML string.
    renderUser: (user) ->
      rosterUser(user.toJSON())

    # Internal: Mutate a user collection, adding a sectionNames property to
    #   each child model.
    #
    # collection - The collection to alter.
    #
    # Returns nothing.
    combineSectionNames: (collection) ->
      collection.each (user) =>
        user.set('sectionNames', @getSections(user), silent: true)

    # Internal: Mutate a user collection, adding a course_id attribute to
    #   each child model.
    #
    # collection - The collection to alter.
    #
    # Returns nothing
    appendCourseId: (collection) ->
      collection.each (user) ->
        user.set('course_id', user.get('enrollments')[0].course_id, silent: true)

    # Internal: Get the names of a user's sections.
    #
    # user - The user to return section names for.
    #
    # Return an array of section names.
    getSections: (user) ->
      sections = _.map user.get('enrollments'), (enrollment) =>
        @collection.sections.find (section) -> enrollment.course_section_id == section.id

      _.uniq(_.map(sections, (section) -> section.get('name')))

