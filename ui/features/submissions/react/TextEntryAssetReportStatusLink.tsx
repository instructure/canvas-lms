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

import {useShouldShowLtiAssetReportsForStudent} from '@canvas/lti-asset-processor/react/hooks/useLtiAssetProcessorsAndReportsForStudent'
import {LtiAssetReportsForStudentSubmission} from '@canvas/lti-asset-processor/react/LtiAssetReportsForStudentSubmission'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {z} from 'zod'

const I18n = createI18nScope('submissions')

// Props passed in via data- attributes on the div this component is rendered into
export const ZTextEntryAssetReportStatusLinkProps = z.object({
  submissionId: z.string(),
  submissionType: z.string(),
})

export default function TextEntryAssetReportStatusLink(
  props: z.infer<typeof ZTextEntryAssetReportStatusLinkProps>,
) {
  const shouldShow = useShouldShowLtiAssetReportsForStudent(props)
  if (!shouldShow) return null

  return (
    <Flex gap="x-small" alignItems="end">
      <Text weight="bold">{I18n.t('Document Processors:')}</Text>
      <LtiAssetReportsForStudentSubmission {...props} />
    </Flex>
  )
}
