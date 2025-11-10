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

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconArrowOpenDownSolid, IconArrowOpenUpSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'
import type {ComponentProps} from 'react'
import {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useLtiAssetProcessorsAndReportsForSpeedgrader} from '../hooks/useLtiAssetProcessorsAndReportsForSpeedgrader'
import {
  extractStudentUserIdOrAnonymousId,
  type StudentUserIdOrAnonymousId,
} from '../queries/getLtiAssetReports'
import type {LtiAssetReport} from '../types/LtiAssetReports'
import {AssetReportModal} from './AssetReportModal'
import LtiAssetReportStatus from './LtiAssetReportStatus'
import {LtiAssetReports} from './LtiAssetReports'

const I18n = createI18nScope('lti_asset_processor')

/**
 * LtiAssetReports component is also used for Student View / Gradebook page.
 * This component is specifically for Asset Reports shown in Speedgrader .
 */
export type LtiAssetReportsForSpeedgraderProps = {
  assignmentId: string

  attempt: number
  submissionType: string
  attachments: {_id: string; displayName: string}[]

  // This is to allow the caller to remember the state of the toggle (used in
  // new speedgrader)
  expanded?: boolean
  onToggleExpanded?: ComponentProps<typeof ToggleDetails>['onToggle']
} & StudentUserIdOrAnonymousId

// If we ever need to use this outside of speedgrader, we should probably change
// ResubmitLtiAssetReportsParams to take userId + anonymousId and move this
// function next to resubmitPath()
function studentIdForResubmission(student: StudentUserIdOrAnonymousId): string | null {
  if (student.studentAnonymousId !== null) {
    return `anonymous:${student.studentAnonymousId}`
  }
  return student.studentUserId
}

function AllReportsCard({reports, openModal}: {reports: LtiAssetReport[]; openModal: () => void}) {
  return (
    <Flex direction="column" gap="small" padding="small 0 0 0">
      <Heading level="h3">
        <Text weight="bold" size="small">
          {I18n.t('All comments')}
        </Text>
      </Heading>
      <View
        as="div"
        borderColor="primary"
        borderRadius="medium"
        borderWidth="small"
        padding="small"
      >
        <Flex direction="column" gap="x-small">
          <Heading level="h4">
            <Text weight="bold" size="small">
              {I18n.t('Reports')}
            </Text>
          </Heading>
          <LtiAssetReportStatus reports={reports} textSize="small" textWeight="normal" />
          <div>
            <Button
              data-pendo="asset-reports-all-reports-view-reports-button"
              size="small"
              onClick={openModal}
            >
              {I18n.t('View reports')}
            </Button>
          </div>
        </Flex>
      </View>
    </Flex>
  )
}
export function LtiAssetReportsForSpeedgrader(
  props: LtiAssetReportsForSpeedgraderProps,
): JSX.Element | null {
  const [modalOpen, setModalOpen] = useState(false)

  const {assignmentId, submissionType} = props
  const processorsAndReports = useLtiAssetProcessorsAndReportsForSpeedgrader({
    assignmentId,
    submissionType,
    ...extractStudentUserIdOrAnonymousId(props),
  })

  if (!processorsAndReports) {
    return null
  }
  const {assetProcessors, assetReports, compatibleSubmissionType} = processorsAndReports

  const childProps = {
    attachments: props.attachments,
    reports: assetReports,
    assetProcessors,
    attempt: props.attempt.toString(),
    submissionType: compatibleSubmissionType,
    studentIdForResubmission: studentIdForResubmission(props) ?? undefined,
    showDocumentDisplayName: true,
  }

  return (
    <View as="section" margin="0 0 medium 0">
      <ToggleDetails
        summary={
          <Text weight="bold" size="medium" data-testid="comments-label">
            {I18n.t('Document processor reports')}
          </Text>
        }
        iconPosition="end"
        icon={() => <IconArrowOpenDownSolid />}
        iconExpanded={() => <IconArrowOpenUpSolid />}
        fluidWidth
        expanded={props.expanded}
        onToggle={props.onToggleExpanded}
        defaultExpanded={props.onToggleExpanded ? undefined : true}
      >
        {submissionType === 'discussion_topic' && assetReports.length > 1 ? (
          <AllReportsCard reports={assetReports} openModal={() => setModalOpen(true)} />
        ) : (
          <LtiAssetReports {...childProps} />
        )}
        {modalOpen && (
          <AssetReportModal
            modalTitle={I18n.t('Document processor reports')}
            onClose={() => setModalOpen(false)}
            {...childProps}
          />
        )}
      </ToggleDetails>
    </View>
  )
}
