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

import {InternalLtiConfiguration} from '../../../../model/internal_lti_configuration/InternalLtiConfiguration'
import {LtiRegistrationWithAllInformation} from '../../../../model/LtiRegistration'
import {mockRegistration} from '../../../manage/__tests__/helpers'

export const mockRegistrationWithAllInformation = (
  n: string,
  i: number,
  configuration: Partial<InternalLtiConfiguration> = {},
  registration: Partial<LtiRegistrationWithAllInformation> = {},
) => {
  const mockedReg = mockRegistration(n, i, configuration, registration)
  return {
    ...mockedReg,
    overlaid_configuration: {
      ...mockedReg.configuration,
      ...registration.overlaid_configuration,
    },
  }
}

export const mockConfiguration = (
  config: Partial<InternalLtiConfiguration>,
): InternalLtiConfiguration => {
  return {
    title: 'Test App',
    oidc_initiation_url: 'http://example.com',
    placements: [],
    scopes: [],
    target_link_uri: 'http://example.com',
    ...config,
  }
}
