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
import Backbone from '@canvas/backbone'
import ContentMigration from '@canvas/content-migrations/backbone/models/ContentMigration'
import CopyCourseView from '../CopyCourseView'
import DateShiftView from '@canvas/content-migrations/backbone/views/DateShiftView'
import SelectContentCheckboxView from '@canvas/content-migrations/backbone/views/subviews/SelectContentCheckboxView'
import {isAccessible} from '@canvas/test-utils/jestAssertions'
import sinon from 'sinon'

const fixtues = document.createElement('div')
fixtues.setAttribute('id', 'fixtures')
document.body.appendChild(fixtues)

const sandbox = sinon.createSandbox()

const ok = value => expect(value).toBeTruthy()

let contentMigration
let copyCourseView

describe('CopyCourseView: Initializer', () => {
  beforeEach(() => {
    contentMigration = new ContentMigration()
    copyCourseView = new CopyCourseView({
      courseFindSelect: new Backbone.View(),
      dateShift: new DateShiftView({
        collection: new Backbone.Collection(),
        model: contentMigration,
      }),
      selectContent: new SelectContentCheckboxView({
        model: contentMigration,
      }),
    })
  })

  afterEach(() => {
    copyCourseView.remove()
    $(fixtues).html('')
  })

  test('it should be accessible', function (done) {
    isAccessible(copyCourseView, done, {a11yReport: true})
  })

  // passes in QUnit, fails in Jest
  test.skip('after init, calls updateNewDates when @courseFindSelect.triggers "course_changed" event', function () {
    $('#fixtures').html(copyCourseView.render().el)
    const sinonSpy = sandbox.spy(copyCourseView.dateShift, 'updateNewDates')
    const course = {
      start_at: 'foo',
      end_at: 'bar',
    }
    copyCourseView.courseFindSelect.trigger('course_changed', course)
    ok(sinonSpy.calledWith(course), 'Called updateNewDates with passed in object')
  })

  // passes in QUnit, fails in Jest
  test.skip('after init, calls SelectContentCheckbox.courseSelected on @courseFindSelect\'s "course_changed" event', function () {
    $('#fixtures').html(copyCourseView.render().el)
    const sinonSpy = sandbox.spy(copyCourseView.selectContent, 'courseSelected')
    const course = {
      start_at: 'foo',
      end_at: 'bar',
    }
    copyCourseView.courseFindSelect.trigger('course_changed', course)
    ok(sinonSpy.calledWith(course), 'Called updateNewDates with passed in object')
  })
})
