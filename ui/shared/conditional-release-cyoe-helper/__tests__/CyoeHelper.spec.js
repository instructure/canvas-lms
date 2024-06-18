/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import fakeENV from '@canvas/test-utils/fakeENV'
import CyoeHelper from '../index'

const cyoeEnv = () => ({
  CONDITIONAL_RELEASE_SERVICE_ENABLED: true,
  CONDITIONAL_RELEASE_ENV: {
    active_rules: [
      {
        trigger_assignment_id: '1',
        trigger_assignment_model: {
          grading_type: 'percentage',
        },
        scoring_ranges: [
          {
            upper_bound: 1,
            lower_bound: 0.7,
            assignment_sets: [{assignment_set_associations: [{assignment_id: '2'}]}],
          },
        ],
      },
    ],
  },
})

const setEnv = env => {
  fakeENV.setup(env)
  CyoeHelper.reloadEnv()
}

const testSetup = {
  setup() {
    setEnv({
      CONDITIONAL_RELEASE_SERVICE_ENABLED: false,
      CONDITIONAL_RELEASE_ENV: null,
    })
  },
  teardown() {
    fakeENV.teardown()
  },
}

describe('CYOE Helper', () => {
  describe('isEnabled', () => {
    beforeEach(() => {
      testSetup.setup()
    })

    afterEach(() => {
      testSetup.teardown()
    })

    test('returns false if not enabled', () => {
      expect(CyoeHelper.isEnabled()).toBeFalsy()
    })

    test('returns true if enabled', () => {
      setEnv(cyoeEnv())
      expect(CyoeHelper.isEnabled()).toBeTruthy()
    })
  })

  describe('getItemData', () => {
    beforeEach(() => {
      testSetup.setup()
    })

    afterEach(() => {
      testSetup.teardown()
    })

    test('return isTrigger = false if item is not a trigger assignment', () => {
      setEnv(cyoeEnv())
      const itemData = CyoeHelper.getItemData('2')
      expect(itemData.isTrigger).toBeFalsy()
    })

    test('return isTrigger = true if item is a trigger assignment', () => {
      setEnv(cyoeEnv())
      const itemData = CyoeHelper.getItemData('1')
      expect(itemData.isTrigger).toBeTruthy()
    })

    test('return isReleased = false if item is not a released assignment', () => {
      setEnv(cyoeEnv())
      const itemData = CyoeHelper.getItemData('1')
      expect(itemData.isReleased).toBeFalsy()
    })

    test('return isReleased = true if item is a released assignment', () => {
      setEnv(cyoeEnv())
      const itemData = CyoeHelper.getItemData('2')
      expect(itemData.isReleased).toBeTruthy()
    })

    test('return isCyoeAble = false if item is not graded', () => {
      setEnv(cyoeEnv())
      const itemData = CyoeHelper.getItemData('1', false)
      expect(itemData.isCyoeAble).toBeFalsy()
    })

    test('return isCyoeAble = true if item is graded', () => {
      setEnv(cyoeEnv())
      const itemData = CyoeHelper.getItemData('1')
      expect(itemData.isCyoeAble).toBeTruthy()
    })

    test('return null for releasedLabel if item is not released by a rule', () => {
      setEnv(cyoeEnv())
      const itemData = CyoeHelper.getItemData('1')
      expect(itemData.releasedLabel).toBeNull()
    })

    test('return correct scoring range for releasedLabel if item is released by a single rule', () => {
      setEnv(cyoeEnv())
      const itemData = CyoeHelper.getItemData('2')
      expect(itemData.releasedLabel).toBe('100% - 70%')
    })

    test('return correct "Multiple" for releasedLabel if item is released by multiple rules', () => {
      const env = cyoeEnv()
      const newRule = {...env.CONDITIONAL_RELEASE_ENV.active_rules[0]}
      newRule.trigger_assignment = '3'
      env.CONDITIONAL_RELEASE_ENV.active_rules.push(newRule)
      setEnv(env)
      const itemData = CyoeHelper.getItemData('2')
      expect(itemData.releasedLabel).toBe('Multiple')
    })
  })

  describe('reloadEnv', () => {
    beforeEach(() => {
      testSetup.setup()
    })

    afterEach(() => {
      testSetup.teardown()
    })

    test('reloads data from ENV', () => {
      const env = cyoeEnv()
      setEnv(env) // set env calls reloadEnv internally
      let itemData = CyoeHelper.getItemData('1')
      expect(itemData.isTrigger).toBeTruthy()

      env.CONDITIONAL_RELEASE_ENV.active_rules[0].trigger_assignment_id = '2'
      setEnv(env)

      itemData = CyoeHelper.getItemData('1')
      expect(itemData.isTrigger).toBeFalsy()
    })
  })
})
