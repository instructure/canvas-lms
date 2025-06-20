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
import type {LtiAssetReport, LtiAssetReportsByProcessor} from '@canvas/lti/model/AssetReport'
import {
  LtiAssetReportsCard,
  LtiAssetReportsMissingReportsCard,
} from './LtiAssetReports/LtiAssetReportsCard'
import {
  type ResubmitLtiAssetReportsProps,
  useResubmitLtiAssetReports,
} from './LtiAssetReports/useResubmitLtiAssetReports'
import {Button} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('speed_grader')

// Below here, code should be copiable to SG2

export type LtiAssetReportsProps = {
  versionedAttachments: {attachment: {id: string; display_name?: string}}[] | undefined
  reportsByAttachment: Record<string, LtiAssetReportsByProcessor> | undefined
  assetProcessors: ExistingAttachedAssetProcessor[]
  studentId: string | undefined
  attempt: number | null | undefined
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
  attachment: {id: string; display_name?: string}
  reports: LtiAssetReport[] | undefined
}

function LtiAssetReportsCardGroup({attachment, reports}: LtiAssetReportsCardGroupProps) {
  const anyReports = reports && reports.length > 0

  return (
    <Flex direction="column" gap="x-small">
      {attachment.display_name && <Heading level="h4">{attachment.display_name}</Heading>}
      {anyReports ? (
        reports.map(r => <LtiAssetReportsCard key={r._id} report={r} />)
      ) : (
        <LtiAssetReportsMissingReportsCard />
      )}
    </Flex>
  )
}

function shouldShowResubmitButton({
  processorId,
  reportsByAttachment,
  versionedAttachments,
}: {
  processorId: string
  reportsByAttachment: Record<string, LtiAssetReportsByProcessor>
  versionedAttachments: {attachment: {id: string}}[]
}) {
  return versionedAttachments.some(({attachment}) => {
    const reports = reportsByAttachment[attachment.id]?.[processorId]

    // Resubmit button is available for a processor if there are any
    // attachments missing reports, or if any reports are resubmittable
    return !reports || reports.length === 0 || reports.some(rep => rep.resubmitAvailable)
  })
}

export function ResubmitButton(props: ResubmitLtiAssetReportsProps) {
  const resubmitMutation = useResubmitLtiAssetReports()
  return (
    <Flex.Item>
      <Button
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
  reportsByAttachment,
  assetProcessors,
  studentId,
  attempt,
}: LtiAssetReportsProps) {
  if (!versionedAttachments || !reportsByAttachment) {
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
                    attachment={attachment}
                    reports={reportsByAttachment[attachment.id]?.[processor.id]}
                  />
                ))}
                {studentId &&
                  shouldShowResubmitButton({
                    processorId: processor.id.toString(),
                    reportsByAttachment,
                    versionedAttachments,
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
