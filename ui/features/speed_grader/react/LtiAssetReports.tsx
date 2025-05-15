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

import {LtiAssetReportsByProcessor} from '../jquery/speed_grader.d'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconArrowOpenDownSolid, IconArrowOpenUpSolid} from '@instructure/ui-icons'
import {ToolIconOrDefault} from '@canvas/lti-apps/components/common/ToolIconOrDefault'
import TruncateWithTooltip from '@canvas/lti-apps/components/common/TruncateWithTooltip'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {buildAPDisplayTitle, ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'
import {LtiAssetReport} from '@canvas/lti/model/AssetReport'
import {QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'
import {LtiAssetReportsCard} from './LtiAssetReports/LtiAssetReportsCard'

type AttachmentAndReports = {
  attachmentName: string
  reportsByProcessor: LtiAssetReportsByProcessor
}

export type LtiAssetReportsProps = {
  attachmentsAndReports: AttachmentAndReports[]
  assetProcessors: ExistingAttachedAssetProcessor[]
}

type LtiAssetReportsProcessorGroupProps = {
  reportsArray: LtiAssetReport[]
  assetProcessor: ExistingAttachedAssetProcessor
}

function LtiAssetReportsCardGroup({
  reportsArray,
  assetProcessor,
}: LtiAssetReportsProcessorGroupProps) {
  return (
    <ToggleDetails
      summary={
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
              <TruncateWithTooltip
                linesAllowed={1}
                backgroundColor={undefined}
                horizontalOffset={0}
              >
                {buildAPDisplayTitle({
                  toolName: assetProcessor.tool_name,
                  toolPlacementLabel: assetProcessor.tool_placement_label,
                  title: assetProcessor.title,
                })}
              </TruncateWithTooltip>
            </Heading>
          </Flex.Item>
        </Flex>
      }
      iconPosition="end"
      icon={() => <IconArrowOpenDownSolid />}
      iconExpanded={() => <IconArrowOpenUpSolid />}
      defaultExpanded
      fluidWidth
    >
      <Flex direction="column" gap="xx-small">
        {reportsArray.map((report, index) => (
          <Flex.Item key={index} margin="x-small 0 0 0">
            <LtiAssetReportsCard report={report} />
          </Flex.Item>
        ))}
      </Flex>
    </ToggleDetails>
  )
}

export function LtiAssetReports({attachmentsAndReports, assetProcessors}: LtiAssetReportsProps) {
  const assetProcessorsById = Object.fromEntries(assetProcessors.map(ap => [ap.id, ap]))
  return (
    <QueryClientProvider client={queryClient}>
      <View as="div" borderColor="primary" borderWidth="none none small none">
        <Flex direction="column" gap="xxx-small">
          {attachmentsAndReports.map(
            ({attachmentName, reportsByProcessor: reportsByProcessor}, index) => (
              <View
                as="div"
                margin="xxx-small none none none"
                padding="small none"
                borderColor="primary"
                borderWidth="small none none none"
                key={`a-${index}`}
              >
                <Flex direction="column" gap="medium" margin="xxx-small none">
                  <Heading level="h4">{attachmentName}</Heading>
                  {Object.keys(reportsByProcessor)
                    .sort()
                    .map((processorId, index) => (
                      <LtiAssetReportsCardGroup
                        key={index}
                        reportsArray={reportsByProcessor[processorId]}
                        assetProcessor={assetProcessorsById[processorId]}
                      />
                    ))}
                </Flex>
              </View>
            ),
          )}
        </Flex>
      </View>
    </QueryClientProvider>
  )
}

/**
 * Lookup each attachment in versionedAttachments (which comes from
 * a HistoricalSubmission) in the table of reports by attachment.
 * Returns undefined if there are no reports for any of the
 * attachments.
 */
export function joinAttachmentsAndReports(
  versionedAttachments: {attachment: {id: string; display_name: string}}[] | undefined,
  reportsByAttachment: Record<string, LtiAssetReportsByProcessor> | undefined,
): AttachmentAndReports[] | undefined {
  if (!versionedAttachments || !reportsByAttachment) {
    return undefined
  }

  const res = versionedAttachments
    .map(a => ({
      attachmentName: a.attachment.display_name,
      reportsByProcessor: reportsByAttachment[a.attachment.id.toString()],
    }))
    .filter(attAndRep => attAndRep.reportsByProcessor)

  return res?.length ? res : undefined
}
