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

import doFetchApi from '@canvas/do-fetch-api-effect'

import type {QueryFunctionContext} from '@tanstack/react-query'
import type {ExperienceSummary} from '../../../../api.d'

const EXPERIENCE_SUMMARY_PATH = '/api/v1/career/experience_summary'

export default async function experienceSummaryQuery({
  signal,
}: QueryFunctionContext): Promise<ExperienceSummary> {
  const fetchOpts = {signal}

  const {json} = await doFetchApi<ExperienceSummary>({path: EXPERIENCE_SUMMARY_PATH, fetchOpts})
  if (json) return json
  throw new Error('Error while fetching experience summary')
}
