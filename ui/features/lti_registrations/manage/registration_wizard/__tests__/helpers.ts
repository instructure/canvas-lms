/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import type {LtiConfiguration} from '../../model/lti_tool_configuration/LtiConfiguration'
import type {JsonUrlWizardService} from '../JsonUrlWizardService'

export const mockJsonUrlWizardService = (
  mocked?: Partial<JsonUrlWizardService>,
): JsonUrlWizardService => ({
  fetchThirdPartyToolConfiguration: jest.fn(),
  ...mocked,
})

export const mockToolConfiguration = (config?: Partial<LtiConfiguration>): LtiConfiguration => ({
  title: '',
  target_link_uri: '',
  oidc_initiation_url: '',
  custom_fields: {},
  is_lti_key: true,
  scopes: [],
  extensions: [],
  ...config,
})
