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

import {useScope as createI18nScope} from '@canvas/i18n'
import {LtiAssetReportsByProcessor} from '../jquery/speed_grader.d'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {
  IconArrowOpenDownSolid,
  IconArrowOpenUpSolid,
  IconInfoSolid,
  IconWarningSolid,
} from '@instructure/ui-icons'
import {ToolIconOrDefault} from '@canvas/lti-apps/components/common/ToolIconOrDefault'
import TruncateWithTooltip from '@canvas/lti-apps/components/common/TruncateWithTooltip'
import {TruncateText} from '@instructure/ui-truncate-text'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {
  buildAPDisplayTitle,
  ExistingAttachedAssetProcessor,
  LtiAssetReport,
} from '@canvas/lti/model/AssetProcessor'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useMutation, QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'

const I18n = createI18nScope('speed_grader')

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

function errorDescription(errorCode: string | undefined) {
  switch (errorCode) {
    case 'UNSUPPORTED_ASSET_TYPE':
      return I18n.t('Unable to process: Invalid file type.')
    case 'ASSET_TOO_LARGE':
      return I18n.t('Unable to process: File is too large.')
    case 'ASSET_TOO_SMALL':
      return I18n.t('Unable to process: File is too small.')
    case 'EULA_NOT_ACCEPTED':
      return I18n.t('Unable to process: EULA not accepted.')
    case 'DOWNLOAD_FAILED':
      return I18n.t('Unable to process: Could not retrieve file.')
    default:
      return I18n.t('The content could not be processed, or the processing failed.')
  }
}

function reportCommentAndInfoText(report: LtiAssetReport): {
  comment?: string | undefined
  infoText?: string
} {
  const progress = report.processing_progress
  if (progress == 'Processed' || progress == 'Failed') {
    // Show comment (no "icon" info) if there is one. No default info text --
    // there will at least be a button to launch or an error message.
    return {comment: report.comment}
  } else {
    // Any other state will show the comment (or, if none, a progress-specific
    // default description) with an "info" icon
    return {infoText: report.comment || defaultInfoText(progress)}
  }
}

function defaultInfoText(progress: LtiAssetReport['processing_progress']) {
  switch (progress) {
    case 'Processed':
    case 'Failed':
      throw 'Unreacheable'

    case 'Processing':
      return I18n.t('The content is being processed and the final report being generated.')
    case 'Pending':
      return I18n.t(
        'The content is not currently being processed, and does not require intervention.',
      )
    case 'PendingManual':
      return I18n.t(
        'Manual intervention is required to start or complete the processing of the content.',
      )
    case 'NotProcessed':
      return I18n.t(
        'The content will not be processed, and this is expected behavior for the current processor. ',
      )
    default:
      // NotReady, or anything unrecognized which spec says should be interpreted as NotReady
      return I18n.t('There is no processing occurring by the tool.')
  }
}

const resubmit = async function (url: string) {
  return await doFetchApi({
    path: url,
    method: 'POST',
  })
}

function LtiAssetReportsCard({report}: {report: LtiAssetReport}) {
  const {comment, infoText} = reportCommentAndInfoText(report)

  const resubmitMutation = useMutation({
    mutationFn: resubmit,
    onSuccess: () => showFlashSuccess(I18n.t('Resubmitted to Document Processing App'))(),
    onError: () => showFlashError(I18n.t('Resubmission failed'))(),
  })

  return (
    <View
      as="div"
      borderColor="primary"
      borderRadius="medium"
      borderWidth="small"
      padding="small"
      role="group"
      aria-label={report.title || I18n.t('Report from Document Processing App')}
    >
      <Flex direction="column" gap="xx-small">
        {report.title && (
          <Flex.Item>
            <Heading>{report.title}</Heading>
          </Flex.Item>
        )}
        {comment && (
          <Flex.Item>
            <Text size="small">
              <TruncateText maxLines={4} ignore={[' ', '.', ',']} ellipsis=" ...">
                {comment}
              </TruncateText>
            </Text>
          </Flex.Item>
        )}
        {report.indication_alt != null || report.score_given != null ? (
          <Flex.Item>
            <Flex direction="row" gap="x-small">
              {report.indication_color != null ? (
                <div
                  title={report.indication_alt}
                  aria-label={report.indication_alt}
                  style={{
                    backgroundColor: report.indication_color,
                    borderRadius: '50%',
                    width: '1.15em',
                    height: '1.15em',
                    verticalAlign: 'middle',
                  }}
                />
              ) : undefined}
              {report.score_given != null ? (
                <Text as="div" size="small" style={{verticalAlign: 'middle'}}>
                  {I18n.t('%{scoreGiven} / %{scoreMaximum}', {
                    scoreGiven: report.score_given,
                    scoreMaximum: report.score_maximum || I18n.t('n/a'),
                  })}
                </Text>
              ) : undefined}
            </Flex>
          </Flex.Item>
        ) : undefined}
        {report.processing_progress === 'Failed' && (
          <Flex.Item>
            <Text as="div" size="small" color="danger">
              <IconWarningSolid
                color="error"
                inline={true}
                style={{verticalAlign: 'middle', paddingRight: '0.3em'}}
              />
              <span style={{verticalAlign: 'middle'}}>{errorDescription(report.error_code)}</span>
            </Text>
          </Flex.Item>
        )}
        {infoText && (
          <Flex.Item>
            <Text as="div" size="small">
              <TruncateText maxLines={4} ignore={[' ', '.', ',']} ellipsis=" ...">
                <IconInfoSolid inline={true} style={{paddingRight: '0.3em'}} />
                {infoText}
              </TruncateText>
            </Text>
          </Flex.Item>
        )}
        {
          // without overflowY, there's a scrollbar in Chrome, no idea why...
          report.launch_url_path && (
            <Flex.Item overflowY="visible">
              <Button size="small" onClick={() => window.open(report.launch_url_path, '_blank')}>
                {I18n.t('View Report')}
              </Button>
            </Flex.Item>
          )
        }
        {report.resubmit_url_path && !resubmitMutation.isSuccess && (
          <Flex.Item overflowY="visible">
            <Button
              data-pendo="asset-processor-resubmit-notice"
              size="small"
              onClick={() => resubmitMutation.mutate(report.resubmit_url_path!)}
            >
              {I18n.t('Resubmit')}
            </Button>
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
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
