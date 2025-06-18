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

// Inst ui imports (same as in SG2)
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {IconInfoSolid, IconWarningSolid} from '@instructure/ui-icons'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Tooltip} from '@instructure/ui-tooltip'

// Canvas-specific imports:
import {useScope as createI18nScope} from '@canvas/i18n'
import {LtiAssetReport} from '@canvas/lti/model/AssetReport'

const I18n = createI18nScope('speed_grader')
const t = I18n.t.bind(I18n)

// Code after this point should be the same as in SG2 except where otherwise noted

function errorDescription(errorCode: string | undefined | null) {
  switch (errorCode) {
    case 'UNSUPPORTED_ASSET_TYPE':
      return t('Unable to process: Invalid file type.')
    case 'ASSET_TOO_LARGE':
      return t('Unable to process: File is too large.')
    case 'ASSET_TOO_SMALL':
      return t('Unable to process: File is too small.')
    case 'EULA_NOT_ACCEPTED':
      return t('Unable to process: EULA not accepted.')
    case 'DOWNLOAD_FAILED':
      return t('Unable to process: Could not retrieve file.')
    default:
      return t('The content could not be processed, or the processing failed.')
  }
}

function reportCommentAndInfoText(report: LtiAssetReport) {
  const progress = report.processingProgress
  if (progress === 'Processed' || progress === 'Failed') {
    // Show comment (no "icon" info) if there is one. No default info text --
    // there will at least be a button to launch or an error message.
    return {comment: report.comment || undefined}
  }
  // Any other state will show the comment (or, if none, a progress-specific
  // default description) with an "info" icon
  return {infoText: report.comment || defaultInfoText(progress)}
}

function defaultInfoText(progress: LtiAssetReport['processingProgress']) {
  switch (progress) {
    case 'Processed':
    case 'Failed':
      throw 'Unreachable'

    case 'Processing':
      return t('The content is being processed and the final report being generated.')
    case 'Pending':
      return t('The content is not currently being processed, and does not require intervention.')
    case 'PendingManual':
      return t(
        'Manual intervention is required to start or complete the processing of the content.',
      )
    case 'NotProcessed':
      return t(
        'The content will not be processed, and this is expected behavior for the current processor. ',
      )
    default:
      // NotReady, or anything unrecognized which spec says should be interpreted as NotReady
      return t('There is no processing occurring by the tool.')
  }
}

function TooltipIfTruncated({
  full,
  truncated,
}: {full: string; truncated: string | undefined | null}) {
  if (truncated && full !== truncated) {
    return (
      <Tooltip renderTip={full}>
        <Text as="div" size="small" style={{verticalAlign: 'middle'}}>
          {truncated}
        </Text>
      </Tooltip>
    )
  }
  return (
    <Text as="div" size="small" style={{verticalAlign: 'middle'}}>
      {full}
    </Text>
  )
}

export function LtiAssetReportsMissingReportsCard() {
  return (
    <View
      as="div"
      borderColor="primary"
      borderRadius="medium"
      borderWidth="small"
      padding="small"
      aria-label={t('No reports from Document Processing App')}
    >
      <Flex direction="column" gap="xx-small">
        <Flex.Item>
          <Text as="div" size="small">
            <IconInfoSolid inline={true} style={{paddingRight: '0.3em'}} />
            {t('The document processor has not returned any reports for this file.')}
          </Text>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export function LtiAssetReportsCard({report}: {report: LtiAssetReport}) {
  const {comment, infoText} = reportCommentAndInfoText(report)

  return (
    <View
      as="div"
      borderColor="primary"
      borderRadius="medium"
      borderWidth="small"
      padding="small"
      aria-label={report.title || t('Report from Document Processing App')}
    >
      <Flex direction="column" gap="xx-small">
        {report.title && (
          <Flex.Item>
            <Heading level="h4">{report.title}</Heading>
          </Flex.Item>
        )}
        {comment && (
          <Flex.Item>
            <Text size="small">
              <TruncateText maxLines={4} ignore={[' ', '.', ',']}>
                {comment}
              </TruncateText>
            </Text>
          </Flex.Item>
        )}
        {report.indicationAlt != null || report.result != null ? (
          <Flex.Item>
            <Flex direction="row" gap="x-small">
              {report.indicationColor != null ? (
                <div
                  title={report.indicationAlt || undefined}
                  aria-label={report.indicationAlt || undefined}
                  style={{
                    backgroundColor: report.indicationColor,
                    borderRadius: '50%',
                    width: '1.15em',
                    height: '1.15em',
                    verticalAlign: 'middle',
                  }}
                />
              ) : undefined}
              {report.result ? (
                <TooltipIfTruncated full={report.result} truncated={report.resultTruncated} />
              ) : null}
            </Flex>
          </Flex.Item>
        ) : undefined}
        {report.processingProgress === 'Failed' && (
          <Flex.Item>
            <Text as="div" size="small" color="danger">
              <IconWarningSolid
                color="error"
                inline={true}
                style={{verticalAlign: 'middle', paddingRight: '0.3em'}}
              />
              <span style={{verticalAlign: 'middle'}}>{errorDescription(report.errorCode)}</span>
            </Text>
          </Flex.Item>
        )}
        {infoText && (
          <Flex.Item>
            <Text as="div" size="small">
              <TruncateText maxLines={4} ignore={[' ', '.', ',']}>
                <IconInfoSolid inline={true} style={{paddingRight: '0.3em'}} />
                {infoText}
              </TruncateText>
            </Text>
          </Flex.Item>
        )}
        {
          // without overflowY, there's a scrollbar in Chrome, no idea why...
          report.launchUrlPath && (
            <Flex.Item overflowY="visible">
              <Button
                id="asset-processor-view-report-button"
                size="small"
                onClick={() =>
                  // TS/biome complain without the || ""
                  window.open(report.launchUrlPath || '', '_blank')
                }
              >
                {t('View Report')}
              </Button>
            </Flex.Item>
          )
        }
      </Flex>
    </View>
  )
}
