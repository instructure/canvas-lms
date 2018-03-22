/*
 * Copyright (C) 2013 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import Backbone from 'Backbone'
import ContentMigration from 'compiled/models/ContentMigration'
import CopyCourseView from 'compiled/views/content_migrations/CopyCourseView'
import DateShiftView from 'compiled/views/content_migrations/subviews/DateShiftView'
import assertions from 'helpers/assertions'

QUnit.module('CopyCourseView: Initializer', {
  setup() {
    this.copyCourseView = new CopyCourseView({
      courseFindSelect: new Backbone.View(),
      dateShift: new DateShiftView({
        collection: new Backbone.Collection(),
        model: new ContentMigration()
      })
    })
  },
  teardown() {
    return this.copyCourseView.remove()
  }
})

test('it should be accessible', function(assert) {
  const done = assert.async()
  assertions.isAccessible(this.copyCourseView, done, {a11yReport: true})
})

test('after init, calls updateNewDates when @courseFindSelect.triggers "course_changed" event', function() {
  $('#fixtures').html(this.copyCourseView.render().el)
  const sinonSpy = this.spy(this.copyCourseView.dateShift, 'updateNewDates')
  const course = {
    start_at: 'foo',
    end_at: 'bar'
  }
  this.copyCourseView.courseFindSelect.trigger('course_changed', course)
  ok(sinonSpy.calledWith(course), 'Called updateNewDates with passed in object')
})
