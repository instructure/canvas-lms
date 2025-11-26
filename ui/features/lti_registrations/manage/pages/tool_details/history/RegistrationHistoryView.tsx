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

import React, {useCallback, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import * as tz from '@instructure/moment-utils'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {IconNoLine} from '@instructure/ui-icons'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {AccountId} from '../../../model/AccountId'
import type {LtiRegistrationId} from '../../../model/LtiRegistrationId'
import {useRegistrationHistory} from './useHistory'
import {HistoryDiffModal} from './HistoryDiffModal'
import {LtiHistoryEntryWithDiff} from './differ'
import {RenderInfiniteApiResult} from '../../../../common/lib/apiResult/RenderInfiniteApiResult'
import {Button} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('lti_registrations')

export type RegistrationHistoryViewProps = {
  accountId: AccountId
  registrationId: LtiRegistrationId
}

/**
 * Generate a summary of affected fields for display in the table
 */
const getAffectedFieldsSummary = (diff: LtiHistoryEntryWithDiff): string => {
  if ('deploymentDiffs' in diff) {
    return I18n.t('Availability & Exceptions')
  }

  const categories: string[] = []
  if (diff.internalConfig?.launchSettings) categories.push(I18n.t('Launch Settings'))
  if (diff.internalConfig?.permissions) categories.push(I18n.t('Permissions'))
  if (diff.internalConfig?.privacyLevel) categories.push(I18n.t('Privacy Level'))
  if (diff.internalConfig?.placements) categories.push(I18n.t('Placements'))
  if (diff.internalConfig?.naming) categories.push(I18n.t('Naming'))
  if (diff.internalConfig?.icons) categories.push(I18n.t('Icons'))

  if (categories.length === 0) {
    return I18n.t('Unknown')
  }

  const formatter = new Intl.ListFormat(I18n.currentLocale(), {
    style: 'narrow',
    type: 'conjunction',
  })
  return formatter.format(categories)
}

export const RegistrationHistoryView = (props: RegistrationHistoryViewProps) => {
  const historyQuery = useRegistrationHistory(props.accountId, props.registrationId)
  const [selectedEntry, setSelectedEntry] = useState<LtiHistoryEntryWithDiff | null>(null)

  const handleOpenModal = useCallback(
    (entry: LtiHistoryEntryWithDiff) => {
      setSelectedEntry(entry)
    },
    [setSelectedEntry],
  )

  const handleCloseModal = useCallback(() => {
    setSelectedEntry(null)
  }, [setSelectedEntry])

  return (
    <RenderInfiniteApiResult
      query={historyQuery}
      onSuccess={({pages, fetchingMore, hasNextPage}) => {
        const history = pages.flat()

        if (history.length === 0) {
          return (
            <Flex direction="column" alignItems="center" padding="large 0">
              <IconNoLine size="medium" color="secondary" />
              <View margin="small 0 0">
                <Text size="large">{I18n.t('No configuration updates found')}</Text>
              </View>
              <Alert
                liveRegion={() =>
                  document.getElementById('flash_screenreader_holder') as HTMLElement
                }
                liveRegionPoliteness="assertive"
                screenReaderOnly={true}
              >
                {I18n.t('No configuration updates found')}
              </Alert>
            </Flex>
          )
        } else {
          return (
            <>
              <HistoryDiffModal
                entry={selectedEntry}
                isOpen={selectedEntry !== null}
                onClose={handleCloseModal}
              />
              <Table caption={I18n.t('Configuration Update History')}>
                <Table.Head>
                  <Table.Row>
                    <Table.ColHeader id="Status" width="20%">
                      {I18n.t('Status')}
                    </Table.ColHeader>
                    <Table.ColHeader id="UpdatedOn" width="20%">
                      {I18n.t('Updated On')}
                    </Table.ColHeader>
                    <Table.ColHeader id="UpdatedBy" width="30%">
                      {I18n.t('Updated By')}
                    </Table.ColHeader>
                    <Table.ColHeader id="AffectedFields" width="30%">
                      {I18n.t('Affected Fields')}
                    </Table.ColHeader>
                  </Table.Row>
                </Table.Head>
                <Table.Body>
                  {history.map(entry => (
                    <TableRow
                      key={entry.id}
                      entry={entry}
                      onAffectedFieldsClick={handleOpenModal}
                    />
                  ))}
                </Table.Body>
              </Table>
              {hasNextPage && !fetchingMore && (
                <Button onClick={() => historyQuery.fetchNextPage()}>{I18n.t('Load More')}</Button>
              )}
              {fetchingMore && (
                <Flex direction="column" alignItems="center" padding="large 0">
                  <Spinner renderTitle={I18n.t('Loading')} />
                </Flex>
              )}
            </>
          )
        }
      }}
    />
  )
}

const TableRow = React.memo(
  ({
    entry,
    onAffectedFieldsClick,
  }: {
    entry: LtiHistoryEntryWithDiff
    onAffectedFieldsClick: (entry: LtiHistoryEntryWithDiff) => void
  }) => {
    const status = I18n.t('Updated')
    const createdAt = entry.created_at
    const createdBy =
      entry.created_by === 'Instructure' ? I18n.t('Instructure') : entry.created_by.name

    const affectedFields = getAffectedFieldsSummary(entry)

    return (
      <Table.Row>
        <Table.Cell>{status}</Table.Cell>
        <Table.Cell>{tz.format(createdAt, 'date.formats.full')}</Table.Cell>
        <Table.Cell>{createdBy}</Table.Cell>
        <Table.Cell>
          <Link onClick={() => onAffectedFieldsClick(entry)}>{affectedFields}</Link>
        </Table.Cell>
      </Table.Row>
    )
  },
)
