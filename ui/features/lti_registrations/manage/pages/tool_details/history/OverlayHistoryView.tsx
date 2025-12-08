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
import * as tz from '@instructure/moment-utils'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {IconNoLine} from '@instructure/ui-icons'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {RenderApiResult} from '../../../../common/lib/apiResult/RenderApiResult'
import type {AccountId} from '../../../model/AccountId'
import type {LtiRegistrationId} from '../../../model/LtiRegistrationId'
import {useOverlayHistory, HISTORY_DISPLAY_LIMIT} from './useHistory'

const I18n = createI18nScope('lti_registrations')

export type OverlayHistoryViewProps = {
  accountId: AccountId
  registrationId: LtiRegistrationId
}

export const OverlayHistoryView = (props: OverlayHistoryViewProps) => {
  const historyQuery = useOverlayHistory(props.accountId, props.registrationId)

  return (
    <RenderApiResult
      query={historyQuery}
      onSuccess={({data: history}) => {
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
              <Table caption={I18n.t('Configuration Update History')}>
                <Table.Head>
                  <Table.Row>
                    <Table.ColHeader id="Status" width="25%">
                      {I18n.t('Status')}
                    </Table.ColHeader>
                    <Table.ColHeader id="UpdatedOn" width="25%">
                      {I18n.t('Updated On')}
                    </Table.ColHeader>
                    <Table.ColHeader id="UpdatedBy" width="50%">
                      {I18n.t('Updated By')}
                    </Table.ColHeader>
                  </Table.Row>
                </Table.Head>
                <Table.Body>
                  {history.slice(0, HISTORY_DISPLAY_LIMIT).map((entry, index) => {
                    const status = entry.caused_by_reset
                      ? I18n.t('Restored to default')
                      : I18n.t('Updated')
                    const createdAt = entry.created_at
                    const createdBy =
                      entry.created_by === 'Instructure'
                        ? I18n.t('Instructure')
                        : entry.created_by.name
                    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
                    // @ts-ignore - tz.format's third argument (zone) is optional at runtime but required by tsgo
                    const formattedDate = tz.format(createdAt, 'date.formats.full')

                    return (
                      <Table.Row key={index}>
                        <Table.Cell>{status}</Table.Cell>
                        <Table.Cell>{formattedDate}</Table.Cell>
                        <Table.Cell>{createdBy}</Table.Cell>
                      </Table.Row>
                    )
                  })}
                </Table.Body>
              </Table>
              <Flex direction="row" textAlign="center" padding="small 0 0 0">
                <Flex.Item shouldGrow={true}>
                  <Text fontStyle="italic" size="small">
                    {history.length > HISTORY_DISPLAY_LIMIT
                      ? I18n.t('Showing the most recent %{count} updates.', {
                          count: HISTORY_DISPLAY_LIMIT,
                        }) + ' '
                      : undefined}
                    {I18n.t(
                      `Not all changes are shown here. To see which fields are tracked, view the documentation`,
                    )}
                  </Text>
                </Flex.Item>
              </Flex>
            </>
          )
        }
      }}
    />
  )
}
