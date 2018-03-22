/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import $ from 'jquery'
import EditAssignmentDetails from 'compiled/calendar/EditAssignmentDetails'
import fcUtil from 'compiled/util/fcUtil'
import tz from 'timezone'
import detroit from 'timezone/America/Detroit'
import french from 'timezone/fr_FR'
import I18nStubber from 'helpers/I18nStubber'
import fakeENV from 'helpers/fakeENV'
import commonEventFactory from 'compiled/calendar/commonEventFactory'

const fixtures = $('#fixtures')

QUnit.module('EditAssignmentDetails', {
  setup() {
    this.snapshot = tz.snapshot()
    this.$holder = $('<table />').appendTo(document.getElementById('fixtures'))
    this.event = {
      possibleContexts() {
        return []
      },
      isNewEvent() {
        return true
      },
      startDate() {
        return fcUtil.wrap('2015-08-07T17:00:00Z')
      },
      allDay: false
    }
    fakeENV.setup()
  },
  teardown() {
    this.$holder.detach()
    document.getElementById('fixtures').innerHTML = ''
    fakeENV.teardown()
    tz.restore(this.snapshot)
  }
})
const createView = function(model, event) {
  ;({model})
  const view = new EditAssignmentDetails(fixtures, event, null, null)
  view.$el.appendTo(fixtures)
  return view.render()
}
const commonEvent = () =>
  commonEventFactory({assignment: {due_at: '2016-02-25T23:30:00Z'}}, ['course_1'])
const nameLengthHelper = function(
  view,
  length,
  maxNameLengthRequiredForAccount,
  maxNameLength,
  postToSis
) {
  const name = 'a'.repeat(length)
  ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT = maxNameLengthRequiredForAccount
  ENV.MAX_NAME_LENGTH = maxNameLength
  return view.validateBeforeSave(
    {
      assignment: {
        name,
        post_to_sis: postToSis
      }
    },
    []
  )
}
test('should initialize input with start date and time', function() {
  const view = createView(commonEvent(), this.event)
  equal(view.$('.datetime_field').val(), 'Fri Aug 7, 2015 5:00pm')
})

test('should have blank input when no start date', function() {
  this.event.startDate = () => null
  const view = createView(commonEvent(), this.event)
  equal(view.$('.datetime_field').val(), '')
})

test('should include start date only if all day', function() {
  this.event.allDay = true
  const view = createView(commonEvent(), this.event)
  equal(view.$('.datetime_field').val(), 'Fri Aug 7, 2015')
})

test('should treat start date as fudged', function() {
  tz.changeZone(detroit, 'America/Detroit')
  const view = createView(commonEvent(), this.event)
  equal(view.$('.datetime_field').val(), 'Fri Aug 7, 2015 1:00pm')
})

test('should localize start date', function() {
  I18nStubber.pushFrame()
  tz.changeLocale(french, 'fr_FR', 'fr')
  I18nStubber.setLocale('fr_FR')
  I18nStubber.stub('fr_FR', {
    'date.formats.full_with_weekday': '%a %-d %b %Y %-k:%M',
    'date.formats.medium': '%a %-d %b %Y %-k:%M',
    'date.month_names': ['août'],
    'date.abbr_month_names': ['août']
  })
  const view = createView(commonEvent(), this.event)
  equal(view.$('.datetime_field').val(), 'ven. 7 août 2015 17:00')
  I18nStubber.popFrame()
})

test('requires name to save assignment event', function() {
  const view = createView(commonEvent(), this.event)
  const data = {
    assignment: {
      name: '',
      post_to_sis: ''
    }
  }
  const errors = view.validateBeforeSave(data, [])
  ok(errors['assignment[name]'])
  equal(errors['assignment[name]'].length, 1)
  equal(errors['assignment[name]'][0].message, 'Name is required!')
})

test('has an error when a name has 257 chars', function() {
  const view = createView(commonEvent(), this.event)
  const errors = nameLengthHelper(view, 257, false, 30, '1')
  ok(errors['assignment[name]'])
  equal(errors['assignment[name]'].length, 1)
  equal(errors['assignment[name]'][0].message, 'Name is too long, must be under 257 characters')
})

test('allows assignment event to save when a name has 256 chars, MAX_NAME_LENGTH is not required and post_to_sis is true', function() {
  const view = createView(commonEvent(), this.event)
  const errors = nameLengthHelper(view, 256, false, 30, '1')
  equal(errors.length, 0)
})

test('allows assignment event to save when a name has 15 chars, MAX_NAME_LENGTH is 10 and is required, post_to_sis is true and grading_type is not_graded', function() {
  this.event.grading_type = 'not_graded'
  const view = createView(commonEvent(), this.event)
  const errors = nameLengthHelper(view, 15, true, 10, '1')
  equal(errors.length, 0)
})

test('has an error when a name has 11 chars, MAX_NAME_LENGTH is 10 and is required, and post_to_sis is true', function() {
  const view = createView(commonEvent(), this.event)
  const errors = nameLengthHelper(view, 11, true, 10, '1')
  ok(errors['assignment[name]'])
  equal(errors['assignment[name]'].length, 1)
  equal(
    errors['assignment[name]'][0].message,
    `Name is too long, must be under ${ENV.MAX_NAME_LENGTH + 1} characters`
  )
})

test('allows assignment event to save when name has 11 chars, MAX_NAME_LENGTH is 10 and required, but post_to_sis is false', function() {
  const view = createView(commonEvent(), this.event)
  const errors = nameLengthHelper(view, 11, true, 10, '0')
  equal(errors.length, 0)
})

test('allows assignment event to save when name has 10 chars, MAX_NAME_LENGTH is 10 and required, and post_to_sis is true', function() {
  const view = createView(commonEvent(), this.event)
  const errors = nameLengthHelper(view, 10, true, 10, '1')
  equal(errors.length, 0)
})

test('requires due_at to save assignment event if there is no date and post_to_sis is true', function() {
  ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT = true
  const view = createView(commonEvent(), this.event)
  const data = {
    assignment: {
      name: 'Too much tuna',
      post_to_sis: '1',
      due_at: ''
    }
  }
  const errors = view.validateBeforeSave(data, [])
  ok(errors['assignment[due_at]'])
  equal(errors['assignment[due_at]'].length, 1)
  equal(errors['assignment[due_at]'][0].message, 'Due Date is required!')
})

test('allows assignment event to save if there is no date and post_to_sis is false', function() {
  const view = createView(commonEvent(), this.event)
  const data = {
    assignment: {
      name: 'Too much tuna',
      post_to_sis: '0',
      due_at: ''
    }
  }
  const errors = view.validateBeforeSave(data, [])
  equal(errors.length, 0)
})
