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
        })
      )
    })

    it('generates the right things for allowedOn, allowsDefaults', () => {
      expect(util.buildTransitions(sampleData.allowedOnFeature.feature_flag, true)).toEqual(
        expect.objectContaining({
          enabled: 'allowed_on',
          disabled: 'allowed',
          lock: 'on',
        })
      )
    })

    it('generates the right things for allowedOn, no allowsDefaults', () => {
      expect(util.buildTransitions(sampleData.allowedOnFeature.feature_flag, false)).toEqual(
        expect.objectContaining({
          enabled: 'on',
          disabled: 'off',
        })
      )
    })
  })

  describe('buildDescription', () => {
    it('generates the right things with allowsDefaults', () => {
      expect(util.buildDescription(sampleData.offFeature.feature_flag, true)).toEqual(
        'Disabled for all subaccounts/courses'
      )
      expect(util.buildDescription(sampleData.allowedFeature.feature_flag, true)).toEqual(
        'Allowed for subaccounts/courses, default off'
      )
      expect(util.buildDescription(sampleData.allowedOnFeature.feature_flag, true)).toEqual(
        'Allowed for subaccounts/courses, default on'
      )
      expect(util.buildDescription(sampleData.onFeature.feature_flag, true)).toEqual(
        'Enabled for all subaccounts/courses'
      )
    })

    it('generates the right things with no allowsDefaults', () => {
      expect(util.buildDescription(sampleData.offFeature.feature_flag, false)).toEqual('Disabled')
      expect(util.buildDescription(sampleData.allowedFeature.feature_flag, false)).toEqual(
        'Disabled'
      )
      expect(util.buildDescription(sampleData.allowedOnFeature.feature_flag, false)).toEqual(
        'Enabled'
      )
      expect(util.buildDescription(sampleData.onFeature.feature_flag, false)).toEqual('Enabled')
    })
  })

  describe('doesAllowDefaults', () => {
    it('correctly determines whether allowed states are available', () => {
      expect(util.doesAllowDefaults(sampleData.offFeature.feature_flag)).toBe(true)
      expect(util.doesAllowDefaults(sampleData.onFeature.feature_flag)).toBe(true)
      expect(util.doesAllowDefaults(sampleData.allowedFeature.feature_flag)).toBe(true)
      expect(util.doesAllowDefaults(sampleData.allowedOnFeature.feature_flag)).toBe(true)
      expect(util.doesAllowDefaults(sampleData.allowedOnRootAccountFeature.feature_flag)).toBe(
        false
      )
      expect(util.doesAllowDefaults(sampleData.allowedOnCourseFeature.feature_flag)).toBe(false)
    })
  })

  describe('transitionMessage', () => {
    it('generates message with warning if flipping a siteadmin flag in anything except development', () => {
      global.ENV.RAILS_ENVIRONMENT = 'test-env'
      global.ENV.ACCOUNT.site_admin = true
      const message = util.transitionMessage(sampleData.offFeature.feature_flag, 'on')
      const {getByText} = render(message)
      expect(
        getByText(
          'You are currently in the test-env environment. This will affect every customer. Are you sure?'
        )
      ).toBeInTheDocument()
    })

    it('does not return a message for siteadmin accounts in development', () => {
      global.ENV.RAILS_ENVIRONMENT = 'development'
      global.ENV.ACCOUNT.site_admin = true
      const message = util.transitionMessage(sampleData.offFeature.feature_flag, 'on')
      const {queryByText} = render(message)
      expect(
        queryByText(
          'You are currently in the development environment. This will affect every customer. Are you sure?'
        )
      ).not.toBeInTheDocument()
    })

    it('does not return a message for non-siteadmin accounts in anything except development', () => {
      global.ENV.RAILS_ENVIRONMENT = 'test-env'
      global.ENV.ACCOUNT.site_admin = false
      const message = util.transitionMessage(sampleData.offFeature.feature_flag, 'on')
      const {queryByText} = render(message)
      expect(
        queryByText(
          'You are currently in the test-env environment. This will affect every customer. Are you sure?'
        )
      ).not.toBeInTheDocument()
    })

    it('does not return a message for non-siteadmin accounts in development', () => {
      global.ENV.RAILS_ENVIRONMENT = 'development'
      global.ENV.ACCOUNT.site_admin = false
      const message = util.transitionMessage(sampleData.offFeature.feature_flag, 'on')
      const {queryByText} = render(message)
      expect(
        queryByText(
          'You are currently in the development environment. This will affect every customer. Are you sure?'
        )
      ).not.toBeInTheDocument()
    })
  })
})
