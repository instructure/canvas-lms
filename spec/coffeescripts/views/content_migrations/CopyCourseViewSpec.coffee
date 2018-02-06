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
  'jquery'
  'Backbone'
  'compiled/models/ContentMigration'
  'compiled/views/content_migrations/CopyCourseView'
  'compiled/views/content_migrations/subviews/DateShiftView'
  'helpers/assertions'
], ($, Backbone, ContentMigration, CopyCourseView, DateShiftView, assertions) ->
  QUnit.module 'CopyCourseView: Initializer',
    setup: ->
      @copyCourseView = new CopyCourseView
                         courseFindSelect: new Backbone.View
                         dateShift: new DateShiftView
                            collection: new Backbone.Collection
                            model: new ContentMigration
    teardown: ->
      @copyCourseView.remove()

  test 'it should be accessible', (assert) ->
    done = assert.async()
    assertions.isAccessible @copyCourseView, done, {'a11yReport': true}

  test 'after init, calls updateNewDates when @courseFindSelect.triggers "course_changed" event', ->
    $('#fixtures').html @copyCourseView.render().el
    sinonSpy = @spy(@copyCourseView.dateShift, 'updateNewDates')
    course = {start_at: 'foo', end_at: 'bar'}
    @copyCourseView.courseFindSelect.trigger 'course_changed', course
    ok sinonSpy.calledWith(course), "Called updateNewDates with passed in object"
