/* eslint-disable qunit/no-identical-names */
/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import SisValidationHelper from '@canvas/sis/SisValidationHelper'
import Backbone from '@canvas/backbone'

class AssignmentStub extends Backbone.Model {
  postToSIS = postToSisBoolean => {
    if (typeof postToSisBoolean === 'undefined') {
      return this.get('post_to_sis')
    }
    return this.set('post_to_sis', postToSisBoolean)
  }

  name = newName => {
    if (typeof newName === 'undefined') {
      return this.get('name')
    }
    return this.set('name', newName)
  }

  maxNameLength = () => ENV.MAX_NAME_LENGTH

  dueAt = date => {
    if (typeof date === 'undefined') {
      return this.get('due_at')
    }
    return this.set('due_at', date)
  }

  allDates = alldate => {
    if (typeof alldate === 'undefined') {
      return this.get('all_dates')
    }
    return this.set('all_dates', alldate)
  }
}
AssignmentStub.prototype.url = '/fake'

QUnit.module('SisValidationHelper')

test('nameTooLong returns true if name is too long AND postToSIS is true', function () {
  this.helper = new SisValidationHelper({
    model: new AssignmentStub(),
    postToSIS: true,
    name: 'Too Much Tuna',
    maxNameLength: 5,
    maxNameLengthRequired: true,
  })
  ok(this.helper.nameTooLong())
})

test('nameTooLong returns false if name is too long AND postToSIS is false', function () {
  this.helper = new SisValidationHelper({
    model: new AssignmentStub(),
    postToSIS: false,
    name: 'Too Much Tuna',
    maxNameLength: 5,
    maxNameLengthRequired: false,
  })
  ok(!this.helper.nameTooLong())
})

test('dueDateMissing returns true if dueAt is null AND postToSIS is true', function () {
  this.helper = new SisValidationHelper({
    model: new AssignmentStub(),
    postToSIS: true,
    dueDateRequired: true,
  })
  ok(this.helper.dueDateMissing())
})

test('dueDateMissing returns false if dueAt is null AND postToSIS is false', function () {
  this.helper = new SisValidationHelper({
    model: new AssignmentStub(),
    postToSIS: true,
    dueDateRequired: false,
  })
  ok(!this.helper.dueDateMissing())
})

test('dueDateMissing returns true if dueAt is null with multiple sections AND postToSIS is true', function () {
  this.helper = new SisValidationHelper({
    model: new AssignmentStub(),
    postToSIS: true,
    allDates: [{dueAt: 'Something'}, {dueAt: null}],
    dueDateRequired: true,
  })
  ok(this.helper.dueDateMissing())
})

test('dueDateMissing returns true if dueAt is null with multiple sections AND postToSIS is true', function () {
  this.helper = new SisValidationHelper({
    model: new AssignmentStub(),
    postToSIS: true,
    allDates: [{dueAt: 'Something'}, {dueAt: 'Something2'}],
    dueDateRequired: true,
  })
  ok(!this.helper.dueDateMissing())
})

test('dueDateMissing returns false if dueAt is valid AND postToSIS is true', function () {
  this.helper = new SisValidationHelper({
    model: new AssignmentStub(),
    postToSIS: true,
    dueDate: 'Due Date',
    dueDateRequired: true,
  })
  ok(!this.helper.dueDateMissing())
})

test('dueDateMissing returns false if dueAt is valid AND postToSIS is false', function () {
  this.helper = new SisValidationHelper({
    model: new AssignmentStub(),
    postToSIS: false,
    dueDate: 'Due Date',
    dueDateRequired: true,
  })
  ok(!this.helper.dueDateMissing())
})

test('dueDateMissing returns false if dueAt is valid with multiple section overrides AND postToSIS is true', function () {
  this.helper = new SisValidationHelper({
    model: new AssignmentStub(),
    postToSIS: true,
    dueDate: 'Due Date',
    allDates: [{dueAt: 'Something'}, {dueAt: 'Something2'}],
    dueDateRequired: true,
  })
  ok(!this.helper.dueDateMissing())
})

test('dueDateMissing returns true if dueAt is valid with multiple section overrides as null AND postToSIS is true', function () {
  this.helper = new SisValidationHelper({
    model: new AssignmentStub(),
    postToSIS: true,
    dueDate: 'Due Date',
    allDates: [{dueAt: null}, {dueAt: null}],
    dueDateRequired: true,
  })
  ok(this.helper.dueDateMissing())
})
