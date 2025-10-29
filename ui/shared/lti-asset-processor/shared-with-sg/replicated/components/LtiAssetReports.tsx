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
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useFormatDateTime, useResubmitLtiAssetReports} from '../../dependenciesShims'
import {
  type LtiAssetReportGroup,
  reportsForAssetsByProcessors,
} from '../lib/reportsForAssetsByProcessors'
import {buildAPDisplayTitle} from '../lib/util'
import {
  type ResubmitLtiAssetReportsParams,
  resubmitPath,
} from '../mutations/resubmitLtiAssetReports'
import type {LtiAssetProcessor} from '../types/LtiAssetProcessors'
import type {AssetReportCompatibleSubmissionType, LtiAssetReport} from '../types/LtiAssetReports'
import {LtiAssetReportsCard, LtiAssetReportsMissingReportsCard} from './LtiAssetReportsCard'
import {ToolIconOrDefault} from './ToolIconOrDefault'
import TruncateWithTooltip from './TruncateWithTooltip'

const I18n = createI18nScope('lti_asset_processor')

export type Attachment = {
  _id: string
  displayName: string
}

export type LtiAssetReportsProps = {
  attachments?: Attachment[]
  reports: LtiAssetReport[]
  assetProcessors: LtiAssetProcessor[]
  attempt: string
  submissionType: AssetReportCompatibleSubmissionType

  // Leave blank to disallow resubmission (e.g. student view page)
  studentIdForResubmission?: string
  // Document display name is not shown in some scenarios (e.g. student view
  // page with there is only one attachment)
  showDocumentDisplayName: boolean
  // Whether there are more than 100 reports available
  hasNextPage?: boolean
}

function ltiAssetProcessorHeader(assetProcessor: LtiAssetProcessor) {
  return (
    <Flex direction="row" gap="small" margin="0 0 small 0">
      <Flex.Item>
        <ToolIconOrDefault
          size={24}
          toolId={assetProcessor.externalTool._id}
          toolName={assetProcessor.externalTool.name}
          iconUrl={assetProcessor.iconOrToolIconUrl}
        />
      </Flex.Item>
      <Flex.Item padding="0 large 0 0">
        <Heading level="h4">
          <TruncateWithTooltip linesAllowed={1} backgroundColor={undefined} horizontalOffset={0}>
            {buildAPDisplayTitle({
              toolName: assetProcessor.externalTool.name,
              toolPlacementLabel: assetProcessor.externalTool.labelFor,
              title: assetProcessor.title,
            })}
          </TruncateWithTooltip>
        </Heading>
      </Flex.Item>
    </Flex>
  )
}

type LtiAssetReportsCardGroupProps = {
  displayName: string
  showDisplayName: boolean
  reports: LtiAssetReport[]
}

function LtiAssetReportsCardGroup({
  displayName,
  showDisplayName,
  reports,
}: LtiAssetReportsCardGroupProps) {
  return (
    <Flex direction="column" gap="x-small" margin="xx-small 0 0 0">
      {showDisplayName && displayName && (
        <View as="div" maxWidth="80%">
          <Heading level="h4">
            <TruncateWithTooltip linesAllowed={1} backgroundColor={undefined} horizontalOffset={0}>
              {displayName}
            </TruncateWithTooltip>
          </Heading>
        </View>
      )}
      {reports.length ? (
        reports.map(r => <LtiAssetReportsCard key={r._id} report={r} />)
      ) : (
        <LtiAssetReportsMissingReportsCard />
      )}
    </Flex>
  )
}

function shouldShowResubmitButton(reportGroups: LtiAssetReportGroup[]): boolean {
  const hasResubmittableReports = (reportsList: LtiAssetReport[] | undefined) =>
    !reportsList || reportsList.length === 0 || reportsList.some(rep => rep.resubmitAvailable)

  return reportGroups.some(group => hasResubmittableReports(group.reports))
}

export function ResubmitButton(props: ResubmitLtiAssetReportsParams): JSX.Element {
  const resubmitMutation = useResubmitLtiAssetReports()

  const pendingOrAlreadyDone =
    !resubmitMutation.isIdle &&
    !resubmitMutation.isError &&
    resubmitMutation.variables &&
    resubmitPath(resubmitMutation.variables) === resubmitPath(props)

  return (
    <Flex.Item>
      <Button
        id="asset-processor-resubmit-notices"
        size="small"
        disabled={pendingOrAlreadyDone}
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
  attachments,
  assetProcessors,
  reports,
  studentIdForResubmission,
  attempt,
  submissionType,
  showDocumentDisplayName,
  hasNextPage,
}: LtiAssetReportsProps): JSX.Element | null {
  const assetSelector = {
    submissionType,
    attachments: attachments || [],
    attempt,
  }
  const formatDateTime = useFormatDateTime()
  const groupedReports = reportsForAssetsByProcessors(
    reports,
    assetProcessors,
    assetSelector,
    formatDateTime,
  )

  return (
    <View as="div">
      <Flex direction="column" gap="small">
        {groupedReports.map(({processor, reportGroups}) => (
          <View as="div" padding="small none" key={processor._id}>
            {ltiAssetProcessorHeader(processor)}
            <Flex direction="column" gap="small">
              {reportGroups.map(({key, displayName, reports}) => (
                <LtiAssetReportsCardGroup
                  key={key}
                  displayName={displayName}
                  reports={reports}
                  showDisplayName={showDocumentDisplayName}
                />
              ))}
              {submissionType !== 'discussion_topic' &&
                studentIdForResubmission &&
                shouldShowResubmitButton(reportGroups) && (
                  <ResubmitButton
                    processorId={processor._id}
                    studentId={studentIdForResubmission}
                    attempt={attempt}
                  />
                )}
            </Flex>
          </View>
        ))}
        {hasNextPage && (
          <View as="div" textAlign="center">
            <Text color="warning">
              {I18n.t('Too many results, not all reports are being displayed')}
            </Text>
          </View>
        )}
      </Flex>
    </View>
  )
}
