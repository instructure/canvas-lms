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
import {isConfigChangeHistoryEntry, LtiHistoryEntryWithDiff} from './differ'
import {RenderInfiniteApiResult} from '../../../../common/lib/apiResult/RenderInfiniteApiResult'
import {Button} from '@instructure/ui-buttons'
import {Spinner} from '@instructure/ui-spinner'
import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('lti_registrations')

export type RegistrationHistoryViewProps = {
  accountId: AccountId
  registrationId: LtiRegistrationId
}

const possibleConfigFields = [
  'launchSettings',
  'permissions',
  'privacyLevel',
  'placements',
  'naming',
  'icons',
  'locked',
  'workflowState',
] as const

type AffectedField = (typeof possibleConfigFields)[number] | 'availability' | 'unknown'

const affectedFieldLabels: Record<AffectedField, string> = {
  launchSettings: I18n.t('Launch Settings'),
  permissions: I18n.t('Permissions'),
  privacyLevel: I18n.t('Privacy Level'),
  placements: I18n.t('Placements'),
  naming: I18n.t('Naming'),
  icons: I18n.t('Icons'),
  availability: I18n.t('Availability & Exceptions'),
  locked: I18n.t('Lock Status'),
  workflowState: I18n.t('Activation State'),
  unknown: I18n.t('Unknown'),
}

const translateAffectedFields = (
  fields: AffectedField[],
  entry: LtiHistoryEntryWithDiff,
): string => {
  const formatter = new Intl.ListFormat(I18n.currentLocale(), {
    style: 'narrow',
    type: 'conjunction',
  })

  const translatedArray = fields.map(f => {
    if (f === 'workflowState' && isConfigChangeHistoryEntry(entry)) {
      if (
        entry.old_configuration.registration.workflow_state === 'inactive' &&
        entry.new_configuration.registration.workflow_state === 'active'
      ) {
        return I18n.t('Turned On')
      } else if (
        entry.old_configuration.registration.workflow_state === 'active' &&
        entry.new_configuration.registration.workflow_state === 'inactive'
      ) {
        return I18n.t('Turned Off')
      } else {
        // There are only three possible states, "active", "inactive", and "deleted", so if we didn't hit either
        // of the other two branches and the differ says this field changed, the registration must have
        // been deleted.
        return I18n.t('Deleted')
      }
    } else {
      return affectedFieldLabels[f]
    }
  })
  return formatter.format(translatedArray)
}

/**
 * Generate a summary of affected fields for display in the table
 */
const getEntrySummary = (diff: LtiHistoryEntryWithDiff): AffectedField[] => {
  if ('deploymentDiffs' in diff) {
    return ['availability']
  }

  const categories: AffectedField[] = []
  possibleConfigFields.forEach(field => {
    if (diff.internalConfig?.[field]) categories.push(field)
  })

  if (categories.length === 0) {
    return ['unknown']
  } else {
    return categories
  }
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
                    <Table.ColHeader id="UpdatedOn" width="25%">
                      {I18n.t('Updated On')}
                    </Table.ColHeader>
                    <Table.ColHeader id="UpdatedBy" width="35%">
                      {I18n.t('Updated By')}
                    </Table.ColHeader>
                    <Table.ColHeader id="AffectedFields" width="40%">
                      {I18n.t('Summary')}
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
    const createdAt = entry.created_at
    const createdBy =
      entry.created_by === 'Instructure' ? I18n.t('Instructure') : entry.created_by.name
    const formattedDate = tz.format(createdAt, 'date.formats.full')

    const affectedFields = getEntrySummary(entry)

    return (
      <Table.Row>
        <Table.Cell>{formattedDate}</Table.Cell>
        <Table.Cell>{createdBy}</Table.Cell>
        <Table.Cell>
          {/**
           * When locked from the UI, the only change should be the workflow state and there's no
           * need to show a modal. However, it's possible using the API to modify lock status and
           * multiple other fields at the same time.
           */}
          {affectedFields.every(f => f === 'workflowState') ? (
            <Text>{translateAffectedFields(affectedFields, entry)}</Text>
          ) : (
            <Link
              onClick={() => {
                onAffectedFieldsClick(entry)
              }}
            >
              {translateAffectedFields(affectedFields, entry)}
            </Link>
          )}
        </Table.Cell>
      </Table.Row>
    )
  },
)
