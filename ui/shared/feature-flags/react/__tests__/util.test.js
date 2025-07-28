/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {render} from '@testing-library/react'

import sampleData from './sampleData.json'
import * as util from '../util'

const DEFAULT_ENV = {
  PRODUCTION: true,
  ACCOUNT: {
    site_admin: true,
  },
}

describe('feature_flags:util', () => {
  beforeEach(() => {
    global.ENV = DEFAULT_ENV
  })

  afterEach(() => {
    global.ENV = {}
  })

  describe('buildTransitions', () => {
    it('generates the right things for allowed, allowsDefaults', () => {
      expect(util.buildTransitions(sampleData.allowedFeature.feature_flag, true)).toEqual(
        expect.objectContaining({
          enabled: 'allowed_on',
          disabled: 'allowed',
          lock: 'off',
        }),
      )
    })

    it('generates the right things for allowedOn, allowsDefaults', () => {
      expect(util.buildTransitions(sampleData.allowedOnFeature.feature_flag, true)).toEqual(
        expect.objectContaining({
          enabled: 'allowed_on',
          disabled: 'allowed',
          lock: 'on',
        }),
      )
    })

    it('generates the right things for allowedOn, no allowsDefaults', () => {
      expect(util.buildTransitions(sampleData.allowedOnFeature.feature_flag, false)).toEqual(
        expect.objectContaining({
          enabled: 'on',
          disabled: 'off',
        }),
      )
    })
  })

  describe('buildDescription', () => {
    it('generates the right things with allowsDefaults for context type account', () => {
      expect(util.buildDescription(sampleData.offFeature.feature_flag, true, 'Account')).toEqual(
        'Disabled for all subaccounts',
      )
      expect(
        util.buildDescription(sampleData.allowedFeature.feature_flag, true, 'Account'),
      ).toEqual('Allowed for subaccounts, default off')
      expect(
        util.buildDescription(sampleData.allowedOnFeature.feature_flag, true, 'Account'),
      ).toEqual('Allowed for subaccounts, default on')
      expect(util.buildDescription(sampleData.onFeature.feature_flag, true, 'Account')).toEqual(
        'Enabled for all subaccounts',
      )
    })

    it('generates the right things with allowsDefaults for context type course', () => {
      expect(util.buildDescription(sampleData.offFeature.feature_flag, true, 'Course')).toEqual(
        'Disabled for all courses',
      )
      expect(util.buildDescription(sampleData.allowedFeature.feature_flag, true, 'Course')).toEqual(
        'Allowed for courses, default off',
      )
      expect(
        util.buildDescription(sampleData.allowedOnFeature.feature_flag, true, 'Course'),
      ).toEqual('Allowed for courses, default on')
      expect(util.buildDescription(sampleData.onFeature.feature_flag, true, 'Course')).toEqual(
        'Enabled for all courses',
      )
    })

    it('generates the right things with no allowsDefaults for context type account', () => {
      expect(util.buildDescription(sampleData.offFeature.feature_flag, false, 'Account')).toEqual(
        'Disabled',
      )
      expect(
        util.buildDescription(sampleData.allowedFeature.feature_flag, false, 'Account'),
      ).toEqual('Disabled')
      expect(
        util.buildDescription(sampleData.allowedOnFeature.feature_flag, false, 'Account'),
      ).toEqual('Enabled')
      expect(util.buildDescription(sampleData.onFeature.feature_flag, false, 'Account')).toEqual(
        'Enabled',
      )
    })

    it('generates the right things with no allowsDefaults for context type course', () => {
      expect(util.buildDescription(sampleData.offFeature.feature_flag, false, 'Course')).toEqual(
        'Disabled',
      )
      expect(
        util.buildDescription(sampleData.allowedFeature.feature_flag, false, 'Course'),
      ).toEqual('Optional in course, default off')
      expect(
        util.buildDescription(sampleData.allowedOnFeature.feature_flag, false, 'Course'),
      ).toEqual('Optional in course, default on')
      expect(util.buildDescription(sampleData.onFeature.feature_flag, false, 'Course')).toEqual(
        'Enabled',
      )
    })
  })

  describe('doesAllowDefaults', () => {
    it('correctly determines whether allowed states are available', () => {
      expect(util.doesAllowDefaults(sampleData.offFeature.feature_flag)).toBe(true)
      expect(util.doesAllowDefaults(sampleData.onFeature.feature_flag)).toBe(true)
      expect(util.doesAllowDefaults(sampleData.allowedFeature.feature_flag)).toBe(true)
      expect(util.doesAllowDefaults(sampleData.allowedOnFeature.feature_flag)).toBe(true)
      expect(util.doesAllowDefaults(sampleData.allowedOnRootAccountFeature.feature_flag)).toBe(
        false,
      )
      expect(util.doesAllowDefaults(sampleData.allowedOnCourseFeature.feature_flag)).toBe(false)
    })
  })
})
