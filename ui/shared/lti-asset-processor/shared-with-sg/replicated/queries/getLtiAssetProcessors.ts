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
import {useScope as createI18nScope} from '@canvas/i18n'
// biome-ignore lint/nursery/noImportCycles: replicated/ directory should be kept identical to the code in canvas-lms
import {type GqlTemplateStringType, gql} from '../../dependenciesShims'

const I18n = createI18nScope('lti_asset_processor')

// For use in Canvas
export const LTI_ASSET_PROCESSORS_QUERY_NODES_FRAGMENT: GqlTemplateStringType = gql`
  fragment LtiAssetProcessorFragment on LtiAssetProcessor {
    _id
    title
    iconOrToolIconUrl
    externalTool {
      _id
      name
      labelFor(placement: ActivityAssetProcessor)
    }
  }
`

// Exported for use in Canvas
export const LTI_ASSET_PROCESSORS_QUERY: GqlTemplateStringType = gql`
  query SpeedGrader_LtiAssetProcessorsQuery($assignmentId: ID!) {
    assignment(id: $assignmentId) {
      ltiAssetProcessorsConnection {
        nodes { ...LtiAssetProcessorFragment }
      }
    }
  }
  ${LTI_ASSET_PROCESSORS_QUERY_NODES_FRAGMENT}
`

export const ZGetLtiAssetProcessorsParams: z.ZodSchema<{
  assignmentId: string
}> = z.object({
  assignmentId: z.string().min(1),
})

export type GetLtiAssetProcessorsParams = z.infer<typeof ZGetLtiAssetProcessorsParams>

export function getLtiAssetProcessorsErrorMessage(): string {
  return I18n.t('Error loading Document Processors')
}
