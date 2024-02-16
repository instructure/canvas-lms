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
import 'jquery-migrate'
import Backbone from '@canvas/backbone'
import ContentMigration from '@canvas/content-migrations/backbone/models/ContentMigration'
import CopyCourseView from 'ui/features/content_migrations/backbone/views/CopyCourseView'
import DateShiftView from '@canvas/content-migrations/backbone/views/DateShiftView'
import SelectContentCheckboxView from '@canvas/content-migrations/backbone/views/subviews/SelectContentCheckboxView'
import assertions from 'helpers/assertions'

QUnit.module('CopyCourseView: Initializer', {
  setup() {
    this.contentMigration = new ContentMigration()
    this.copyCourseView = new CopyCourseView({
      courseFindSelect: new Backbone.View(),
      dateShift: new DateShiftView({
        collection: new Backbone.Collection(),
        model: this.contentMigration,
      }),
      selectContent: new SelectContentCheckboxView({
        model: this.contentMigration,
      }),
    })
  },
  teardown() {
    return this.copyCourseView.remove()
  },
})

/* eslint-disable qunit/resolve-async */
test('it should be accessible', function (assert) {
  const done = assert.async()
  assertions.isAccessible(this.copyCourseView, done, {a11yReport: true})
})
/* eslint-enable qunit/resolve-async */

test('after init, calls updateNewDates when @courseFindSelect.triggers "course_changed" event', function () {
  $('#fixtures').html(this.copyCourseView.render().el)
  const sinonSpy = sandbox.spy(this.copyCourseView.dateShift, 'updateNewDates')
  const course = {
    start_at: 'foo',
    end_at: 'bar',
  }
  this.copyCourseView.courseFindSelect.trigger('course_changed', course)
  ok(sinonSpy.calledWith(course), 'Called updateNewDates with passed in object')
})

test('after init, calls SelectContentCheckbox.courseSelected on @courseFindSelect\'s "course_changed" event', function () {
  $('#fixtures').html(this.copyCourseView.render().el)
  const sinonSpy = sandbox.spy(this.copyCourseView.selectContent, 'courseSelected')
  const course = {
    start_at: 'foo',
    end_at: 'bar',
  }
  this.copyCourseView.courseFindSelect.trigger('course_changed', course)
  ok(sinonSpy.calledWith(course), 'Called updateNewDates with passed in object')
})
