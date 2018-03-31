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

import Outcome from 'compiled/models/Outcome'
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
        calculation_int: 65
      }
    }
    this.courseOutcome = {
      context_type: 'Course',
      context_id: 2,
      outcome: {
        title: 'Course Outcome',
        context_type: 'Course',
        context_id: 2
      }
    }
    fakeENV.setup()
    ENV.PERMISSIONS = {manage_outcomes: true}
    ENV.ROOT_OUTCOME_GROUP = {context_type: 'Course'}
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('isNative returns false for an outcome imported from the account level', function() {
  const outcome = new Outcome(this.importedOutcome, {parse: true})
  equal(outcome.isNative(), false)
})

test('isNative returns true for an outcome created in the course', function() {
  const outcome = new Outcome(this.courseOutcome, {parse: true})
  equal(outcome.isNative(), true)
})

test('CanManage returns true for an account outcome on the course level', function() {
  const outcome = new Outcome(this.importedOutcome, {parse: true})
  equal(outcome.canManage(), true)
})

test('default calculation method settings not set if calculation_method exists', function() {
  const spy = this.spy(Outcome.prototype, 'setDefaultCalcSettings')
  const outcome = new Outcome(this.importedOutcome, {parse: true})
  ok(!spy.called)
})

test('default calculation method settings set if calculation_method is null', function() {
  const spy = this.spy(Outcome.prototype, 'setDefaultCalcSettings')
  const outcome = new Outcome(this.courseOutcome, {parse: true})
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
        context_id: 1
      }
    }
    fakeENV.setup()
    ENV.PERMISSIONS = {manage_outcomes: true}
    ENV.ROOT_OUTCOME_GROUP = {context_type: 'Account'}
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('isNative is true for an account level outcome when viewed on the account', function() {
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
        context_id: undefined
      }
    }
    fakeENV.setup()
    ENV.PERMISSIONS = {manage_outcomes: true}
    ENV.ROOT_OUTCOME_GROUP = {context_type: 'Course'}
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('CanManage returns true for a global outcome on the course level', function() {
  const outcome = new Outcome(this.globalOutcome, {parse: true})
  equal(outcome.canManage(), true)
})
