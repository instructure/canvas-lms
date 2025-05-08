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

import {z} from 'zod'
import {LtiRegistrationId} from '../model/LtiRegistrationId'
import {LtiDeployment, ZLtiDeployment} from '../model/LtiDeployment'
import {ApiResult, parseFetchResult} from '../../common/lib/apiResult/ApiResult'
import {defaultFetchOptions} from '@canvas/util/xhr'

export type FetchControlsByDeployment = (options: {
  registrationId: LtiRegistrationId
}) => Promise<ApiResult<LtiDeployment[]>>

/**
 * Returns a list of LtiDeployments, each containing
 * a list of LtiContextControls in `context_controls`.
 */
export const fetchControlsByDeployment: FetchControlsByDeployment = options =>
  parseFetchResult(z.array(ZLtiDeployment))(
    fetch(`/api/v1/lti_registrations/${options.registrationId}/controls`, defaultFetchOptions()),
  )
