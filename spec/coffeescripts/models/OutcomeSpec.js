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

import Outcome from '@canvas/outcomes/backbone/models/Outcome'
import fakeENV from 'helpers/fakeENV'

QUnit.module('Course Outcomes', {
  setup() {
    this.importedOutcome = {
      context_type: 'Account',
      context_id: 1,
      outcome: {
        title: 'Account Outcome',
        context_type: 'Course',
        context_id: 1,
        calculation_method: 'decaying_average',
        calculation_int: 65,
      },
    }
    this.courseOutcome = {
      context_type: 'Course',
      context_id: 2,
      outcome: {
        title: 'Course Outcome',
        context_type: 'Course',
        context_id: 2,
      },
    }
    fakeENV.setup()
    ENV.PERMISSIONS = {manage_outcomes: true}
    ENV.ROOT_OUTCOME_GROUP = {context_type: 'Course'}
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('isNative returns false for an outcome imported from the account level', function () {
  const outcome = new Outcome(this.importedOutcome, {parse: true})
  equal(outcome.isNative(), false)
})

test('isNative returns true for an outcome created in the course', function () {
  const outcome = new Outcome(this.courseOutcome, {parse: true})
  equal(outcome.isNative(), true)
})

test('CanManage returns true for an account outcome on the course level', function () {
  const outcome = new Outcome(this.importedOutcome, {parse: true})
  equal(outcome.canManage(), true)
})

test('default calculation method settings not set if calculation_method exists', function () {
  const spy = sandbox.spy(Outcome.prototype, 'setDefaultCalcSettings')
  new Outcome(this.importedOutcome, {parse: true})
  ok(!spy.called)
})

test('default calculation method settings set if calculation_method is null', function () {
  const spy = sandbox.spy(Outcome.prototype, 'setDefaultCalcSettings')
  new Outcome(this.courseOutcome, {parse: true})
  ok(spy.calledOnce)
})

QUnit.module('Account Outcomes', {
  setup() {
    this.accountOutcome = {
      context_type: 'Account',
      context_id: 1,
      outcome: {
        title: 'Account Outcome',
        context_type: 'Account',
        context_id: 1,
      },
    }
    fakeENV.setup()
    ENV.PERMISSIONS = {manage_outcomes: true}
    ENV.ROOT_OUTCOME_GROUP = {context_type: 'Account'}
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('isNative is true for an account level outcome when viewed on the account', function () {
  const outcome = new Outcome(this.accountOutcome, {parse: true})
  equal(outcome.isNative(), true)
})

QUnit.module('Global Outcomes in a course', {
  setup() {
    this.globalOutcome = {
      context_type: 'Account',
      context_id: 1,
      outcome: {
        title: 'Account Outcome',
        context_type: undefined,
        context_id: undefined,
      },
    }
    fakeENV.setup()
    ENV.PERMISSIONS = {manage_outcomes: true}
    ENV.ROOT_OUTCOME_GROUP = {context_type: 'Course'}
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('CanManage returns true for a global outcome on the course level', function () {
  const outcome = new Outcome(this.globalOutcome, {parse: true})
  equal(outcome.canManage(), true)
})

QUnit.module('With the account_level_mastery_scales FF enabled', {
  setup() {
    this.importedOutcome = {
      context_type: 'Account',
      context_id: 1,
      outcome: {
        title: 'Account Outcome',
        context_type: 'Course',
        context_id: 1,
        calculation_method: 'decaying_average',
        calculation_int: 65,
      },
    }
    fakeENV.setup()
    this.ratings = [
      {description: 'Exceeds Mastery', points: 4.0, mastery: false, color: '127A1B'},
      {description: 'Mastery', points: 3.0, mastery: true, color: '0B874B'},
      {description: 'Near Mastery', points: 2.0, mastery: false, color: 'FAB901'},
      {description: 'Below Mastery', points: 1.0, mastery: false, color: 'FD5D10'},
      {description: 'Well Below Mastery', points: 0.0, mastery: false, color: 'E0061F'},
    ]
    ENV.PERMISSIONS = {manage_outcomes: true}
    ENV.ROOT_OUTCOME_GROUP = {context_type: 'Course'}
    ENV.MASTERY_SCALE = {
      outcome_proficiency: {ratings: this.ratings},
    }
    ENV.ACCOUNT_LEVEL_MASTERY_SCALES = true
  },
  teardown() {
    fakeENV.teardown()
  },
})

test('it uses the ENV.MASTERY_SCALES ratings', function () {
  const outcome = new Outcome(this.importedOutcome, {parse: true})
  equal(outcome.get('ratings'), this.ratings)
  equal(outcome.get('mastery_points'), 3)
  equal(outcome.get('points_possible'), 4)
})

test('ignores proficiency attributes during saving', function () {
  const outcome = new Outcome(this.importedOutcome, {parse: true})
  sinon.stub(outcome, 'url').returns('fake-url')
  outcome.save({}, {})
  equal(outcome.get('mastery_points'), null)
  equal(outcome.get('points_possible'), null)
  equal(outcome.get('ratings'), null)
  equal(outcome.get('calculation_method'), null)
  equal(outcome.get('calculation_int'), null)
})
