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

import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconArrowOpenDownSolid, IconArrowOpenUpSolid} from '@instructure/ui-icons'
import {ToolIconOrDefault} from '@canvas/lti-apps/components/common/ToolIconOrDefault'
import TruncateWithTooltip from '@canvas/lti-apps/components/common/TruncateWithTooltip'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {
  buildAPDisplayTitle,
  type ExistingAttachedAssetProcessor,
} from '@canvas/lti/model/AssetProcessor'
import type {
  LtiAssetReport,
  SpeedGraderLtiAssetReports,
} from '@canvas/lti-asset-processor/model/AssetReport'
import {
  LtiAssetReportsCard,
  LtiAssetReportsMissingReportsCard,
} from './LtiAssetReports/LtiAssetReportsCard'
import {useResubmitLtiAssetReports} from './hooks/useResubmitLtiAssetReports'
import {Button} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ResubmitLtiAssetReportsParams} from '../shared-with-sg/replicated/mutations/resubmitLtiAssetReports'

const I18n = createI18nScope('speed_grader')

// Below here, code should be copiable to SG2

export type LtiAssetReportsProps = {
  versionedAttachments: {attachment: {id: string; display_name?: string}}[] | undefined
  reports: SpeedGraderLtiAssetReports | undefined
  assetProcessors: ExistingAttachedAssetProcessor[]
  studentId: string | undefined
  attempt: string
  submissionType: 'online_text_entry' | 'online_upload'
}

function ltiAssetProcessorHeader(assetProcessor: ExistingAttachedAssetProcessor) {
  return (
    <Flex direction="row" gap="small">
      <Flex.Item>
        <ToolIconOrDefault
          size={24}
          toolId={assetProcessor.tool_id}
          toolName={assetProcessor.tool_name}
          iconUrl={assetProcessor.icon_or_tool_icon_url}
        />
      </Flex.Item>
      <Flex.Item padding="0 large 0 0">
        <Heading level="h4">
          <TruncateWithTooltip linesAllowed={1} backgroundColor={undefined} horizontalOffset={0}>
            {buildAPDisplayTitle({
              toolName: assetProcessor.tool_name,
              toolPlacementLabel: assetProcessor.tool_placement_label,
              title: assetProcessor.title,
            })}
          </TruncateWithTooltip>
        </Heading>
      </Flex.Item>
    </Flex>
  )
}

type LtiAssetReportsCardGroupProps = {
  displayName?: string
  reports: LtiAssetReport[] | undefined
}

function LtiAssetReportsCardGroup({displayName, reports}: LtiAssetReportsCardGroupProps) {
  const anyReports = reports && reports.length > 0

  return (
    <Flex direction="column" gap="x-small">
      {displayName && <Heading level="h4">{displayName}</Heading>}
      {anyReports ? (
        reports.map(r => <LtiAssetReportsCard key={r._id} report={r} />)
      ) : (
        <LtiAssetReportsMissingReportsCard />
      )}
    </Flex>
  )
}

type ShouldShowResubmitButtonProps = {
  processorId: string
  reports: SpeedGraderLtiAssetReports
  versionedAttachments: {attachment: {id: string}}[]
  attempt: string
  submissionType: 'online_text_entry' | 'online_upload'
}

function shouldShowResubmitButton({
  processorId,
  reports,
  versionedAttachments,
  attempt,
  submissionType,
}: ShouldShowResubmitButtonProps) {
  const hasResubmittableReports = (reportsList: LtiAssetReport[] | undefined) =>
    !reportsList || reportsList.length === 0 || reportsList.some(rep => rep.resubmitAvailable)

  if (submissionType === 'online_text_entry') {
    const reportForAttempt = reports.by_attempt?.[attempt]?.[processorId]
    return hasResubmittableReports(reportForAttempt)
  }
  if (submissionType === 'online_upload') {
    return versionedAttachments.some(({attachment}) => {
      const reportsForAttachment = reports.by_attachment?.[attachment.id]?.[processorId]
      return hasResubmittableReports(reportsForAttachment)
    })
  }

  return false // Handle unexpected submission types
}

export function ResubmitButton(props: ResubmitLtiAssetReportsParams) {
  const resubmitMutation = useResubmitLtiAssetReports()
  return (
    <Flex.Item>
      <Button
        id="asset-processor-resubmit-notices"
        size="small"
        disabled={!(resubmitMutation.isIdle || resubmitMutation.isError)}
        onClick={() => {
          resubmitMutation.mutate(props)
        }}
      >
        {I18n.t('Resubmit All Files')}
      </Button>
    </Flex.Item>
  )
}

export function LtiAssetReports({
  versionedAttachments,
  reports,
  assetProcessors,
  studentId,
  attempt,
  submissionType,
}: LtiAssetReportsProps) {
  if (!versionedAttachments || !reports) {
    return null
  }

  return (
    <View as="div" padding="small none none none">
      <Flex direction="column" gap="small">
        {assetProcessors.map(processor => (
          <ToggleDetails
            summary={ltiAssetProcessorHeader(processor)}
            key={processor.id}
            iconPosition="end"
            icon={() => <IconArrowOpenDownSolid />}
            iconExpanded={() => <IconArrowOpenUpSolid />}
            defaultExpanded
            fluidWidth
          >
            <View as="div" padding="small none">
              <Flex direction="column" gap="small">
                {versionedAttachments.map(({attachment}) => (
                  <LtiAssetReportsCardGroup
                    key={attachment.id}
                    displayName={attachment.display_name}
                    reports={reports.by_attachment?.[attachment.id]?.[processor.id]}
                  />
                ))}
                {submissionType === 'online_text_entry' && (
                  <LtiAssetReportsCardGroup
                    displayName={I18n.t('Text submitted to Canvas')}
                    reports={reports.by_attempt?.[attempt]?.[processor.id] ?? []}
                  />
                )}
                {studentId &&
                  shouldShowResubmitButton({
                    processorId: processor.id.toString(),
                    reports,
                    versionedAttachments,
                    attempt,
                    submissionType,
                  }) && (
                    <ResubmitButton
                      processorId={processor.id.toString()}
                      studentId={studentId}
                      attempt={attempt}
                    />
                  )}
              </Flex>
            </View>
          </ToggleDetails>
        ))}
      </Flex>
    </View>
  )
}
