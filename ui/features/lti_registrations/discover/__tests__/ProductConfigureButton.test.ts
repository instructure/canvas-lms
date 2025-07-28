/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {Product} from '@canvas/lti-apps/models/Product'
import {findLtiVersion} from '../ProductConfigureButton'

describe('findLtiVersion', () => {
  it('chooses 1.1 if only 1.1 is available', () => {
    const integrationConfiguration: Product['tool_integration_configurations'] = {
      lti_11: [{integration_type: 'lti_11_url'}],
      lti_13: [],
    }

    expect(findLtiVersion(integrationConfiguration)).toBe('1p1')
  })

  it('chooses 1.1 if the only configs for 1.3 are backfills', () => {
    const integrationConfiguration: Product['tool_integration_configurations'] = {
      lti_11: [{integration_type: 'lti_11_url'}],
      lti_13: [{integration_type: 'lti_13_legacy_backfill'}],
    }

    expect(findLtiVersion(integrationConfiguration)).toBe('1p1')
  })

  it('chooses 1.1 there is at least one non-backfill for 1.1', () => {
    const integrationConfiguration: Product['tool_integration_configurations'] = {
      lti_11: [{integration_type: 'lti_11_url'}, {integration_type: 'lti_11_legacy_backfill'}],
      lti_13: [{integration_type: 'lti_13_legacy_backfill'}],
    }

    expect(findLtiVersion(integrationConfiguration)).toBe('1p1')
  })

  it('chooses 1.3 if only 1.3 is available', () => {
    const integrationConfiguration: Product['tool_integration_configurations'] = {
      lti_11: [],
      lti_13: [{integration_type: 'lti_13_configuration'}],
    }

    expect(findLtiVersion(integrationConfiguration)).toBe('1p3')
  })

  it('chooses 1.3 if both 1.1 and 1.3 are available', () => {
    const integrationConfiguration: Product['tool_integration_configurations'] = {
      lti_11: [{integration_type: 'lti_11_url'}],
      lti_13: [{integration_type: 'lti_13_url'}],
    }

    expect(findLtiVersion(integrationConfiguration)).toBe('1p3')
  })

  it('chooses 1.3 if neither 1.1 or 1.3 have configs', () => {
    const integrationConfiguration: Product['tool_integration_configurations'] = {
      lti_11: [],
      lti_13: [],
    }

    expect(findLtiVersion(integrationConfiguration)).toBe('1p3')
  })

  it('chooses 1.3 if both 1.1 and 1.3 only have backfills', () => {
    const integrationConfiguration: Product['tool_integration_configurations'] = {
      lti_11: [{integration_type: 'lti_11_legacy_backfill'}],
      lti_13: [{integration_type: 'lti_13_legacy_backfill'}],
    }

    expect(findLtiVersion(integrationConfiguration)).toBe('1p3')
  })
})
