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

import Backbone from 'Backbone'
import CourseRestore from 'compiled/models/CourseRestore'
import CourseSearchFormView from 'compiled/views/accounts/admin_tools/CourseSearchFormView'
import $ from 'jquery'
import assertions from 'helpers/assertions'

QUnit.module('CourseSearchFormView', {
  setup() {
    this.course_id = 42
    this.courseRestore = new CourseRestore({account_id: 4})
    this.courseSearchFormView = new CourseSearchFormView({model: this.courseRestore})
    return $('#fixtures').append(this.courseSearchFormView.render().el)
  },
  teardown() {
    return this.courseSearchFormView.remove()
  }
})

test('should be accessible', function(assert) {
  const done = assert.async()
  assertions.isAccessible(this.courseSearchFormView, done, {a11yReport: true})
})

test('#search, when form is submited, search is called', function() {
  this.mock(this.courseRestore)
    .expects('search')
    .once()
    .returns($.Deferred().resolve())
  this.courseSearchFormView.$courseSearchField.val(this.course_id)
  return this.courseSearchFormView.$el.submit()
})

test('#search shows an error when given a blank query', function() {
  this.mock(this.courseSearchFormView.$courseSearchField)
    .expects('errorBox')
    .once()
  return this.courseSearchFormView.$el.submit()
})
