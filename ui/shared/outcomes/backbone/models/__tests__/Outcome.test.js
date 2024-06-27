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

import Outcome from '../Outcome'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('Outcome Tests', () => {
  describe('Course Outcomes', () => {
    let importedOutcome
    let courseOutcome

    beforeEach(() => {
      importedOutcome = {
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
      courseOutcome = {
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
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    test('isNative returns false for an outcome imported from the account level', () => {
      const outcome = new Outcome(importedOutcome, {parse: true})
      expect(outcome.isNative()).toBe(false)
    })

    test('isNative returns true for an outcome created in the course', () => {
      const outcome = new Outcome(courseOutcome, {parse: true})
      expect(outcome.isNative()).toBe(true)
    })

    test('CanManage returns true for an account outcome on the course level', () => {
      const outcome = new Outcome(importedOutcome, {parse: true})
      expect(outcome.canManage()).toBe(true)
    })

    test('default calculation method settings not set if calculation_method exists', () => {
      const spy = jest.spyOn(Outcome.prototype, 'setDefaultCalcSettings')
      new Outcome(importedOutcome, {parse: true})
      expect(spy).not.toHaveBeenCalled()
    })

    test('default calculation method settings set if calculation_method is null', () => {
      const spy = jest.spyOn(Outcome.prototype, 'setDefaultCalcSettings')
      new Outcome(courseOutcome, {parse: true})
      expect(spy).toHaveBeenCalled()
    })
  })

  describe('Account Outcomes', () => {
    let accountOutcome

    beforeEach(() => {
      accountOutcome = {
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
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    test('isNative is true for an account level outcome when viewed on the account', () => {
      const outcome = new Outcome(accountOutcome, {parse: true})
      expect(outcome.isNative()).toBe(true)
    })
  })

  describe('Global Outcomes in a course', () => {
    let globalOutcome

    beforeEach(() => {
      globalOutcome = {
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
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    test('CanManage returns true for a global outcome on the course level', () => {
      const outcome = new Outcome(globalOutcome, {parse: true})
      expect(outcome.canManage()).toBe(true)
    })
  })

  describe('With the account_level_mastery_scales FF enabled', () => {
    let importedOutcome
    let ratings

    beforeEach(() => {
      importedOutcome = {
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
      ratings = [
        {description: 'Exceeds Mastery', points: 4.0, mastery: false, color: '127A1B'},
        {description: 'Mastery', points: 3.0, mastery: true, color: '0B874B'},
        {description: 'Near Mastery', points: 2.0, mastery: false, color: 'FAB901'},
        {description: 'Below Mastery', points: 1.0, mastery: false, color: 'FD5D10'},
        {description: 'Well Below Mastery', points: 0.0, mastery: false, color: 'E0061F'},
      ]
      fakeENV.setup()
      ENV.PERMISSIONS = {manage_outcomes: true}
      ENV.ROOT_OUTCOME_GROUP = {context_type: 'Course'}
      ENV.MASTERY_SCALE = {
        outcome_proficiency: {ratings},
      }
      ENV.ACCOUNT_LEVEL_MASTERY_SCALES = true
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    test('it uses the ENV.MASTERY_SCALES ratings', () => {
      const outcome = new Outcome(importedOutcome, {parse: true})
      expect(outcome.get('ratings')).toBe(ratings)
      expect(outcome.get('mastery_points')).toBe(3)
      expect(outcome.get('points_possible')).toBe(4)
    })

    test('ignores proficiency attributes during saving', () => {
      const outcome = new Outcome(importedOutcome, {parse: true})
      jest.spyOn(outcome, 'url').mockReturnValue('fake-url')
      outcome.save({}, {})

      expect(outcome.get('mastery_points')).toBeUndefined()
      expect(outcome.get('points_possible')).toBeUndefined()
      expect(outcome.get('ratings')).toBeUndefined()
      expect(outcome.get('calculation_method')).toBeUndefined()
      expect(outcome.get('calculation_int')).toBeUndefined()
    })
  })
})
