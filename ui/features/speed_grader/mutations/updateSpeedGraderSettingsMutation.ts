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

import {z} from 'zod'
import {executeQuery} from '@canvas/graphql'
import {gql} from '@apollo/client'

export const UPDATE_SPEED_GRADER_SETTINGS = gql`
  mutation UpdateSpeedGraderSettingsPlatformSG($gradeByQuestion: Boolean!) {
    __typename
    updateSpeedGraderSettings(input: {gradeByQuestion: $gradeByQuestion}) {
      speedGraderSettings {
        gradeByQuestion
      }
    }
  }
`

export const ZUpdateSpeedGraderSettingsParams = z.object({gradeByQuestion: z.boolean()})
type UpdateSpeedGraderSettingsParams = z.infer<typeof ZUpdateSpeedGraderSettingsParams>

export async function updateSpeedGraderSettings(
  params: UpdateSpeedGraderSettingsParams,
): Promise<any> {
  const result = executeQuery<any>(UPDATE_SPEED_GRADER_SETTINGS, params)

  return result
}
