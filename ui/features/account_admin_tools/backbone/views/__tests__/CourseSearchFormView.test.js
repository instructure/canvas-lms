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

import CourseRestore from '../../models/CourseRestore'
import CourseSearchFormView from '../CourseSearchFormView'
import $ from 'jquery'
import {isAccessible} from '@canvas/test-utils/jestAssertions'
import sinon from 'sinon'

const sandbox = sinon.createSandbox()
let course_id
let courseRestore
let courseSearchFormView

describe('CourseSearchFormView', () => {
  beforeEach(() => {
    course_id = 42
    courseRestore = new CourseRestore({account_id: 4})
    courseSearchFormView = new CourseSearchFormView({model: courseRestore})
    $('#fixtures').append(courseSearchFormView.render().el)
  })

  afterEach(() => {
    courseSearchFormView.remove()
  })

  test('should be accessible', function (done) {
    isAccessible(courseSearchFormView, done, {a11yReport: true})
  })

  test('#search, when form is submited, search is called', function () {
    sandbox.mock(courseRestore).expects('search').once().returns($.Deferred().resolve())
    courseSearchFormView.$searchField.val(course_id)
    courseSearchFormView.$el.submit()
  })

  test('#search shows an error when given a blank query', function () {
    sandbox.mock(courseSearchFormView.$searchField).expects('errorBox').once()
    courseSearchFormView.$el.submit()
  })
})
