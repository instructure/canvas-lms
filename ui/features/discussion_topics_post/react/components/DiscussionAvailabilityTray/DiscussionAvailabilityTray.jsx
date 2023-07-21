/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import DateHelper from '@canvas/datetime/dateHelper'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import {responsiveQuerySizes} from '../../utils'

import {Responsive} from '@instructure/ui-responsive'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('discussion_posts')

export function DiscussionAvailabilityTray({...props}) {
  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({tablet: true, desktop: true})}
      props={{
        tablet: {
          layout: 'stacked',
          textSize: 'small',
        },
        desktop: {
          layout: 'fixed',
          textSize: 'medium',
        },
      }}
      render={responsiveProps => (
        <Table
          data-testid="availability-table"
          layout={responsiveProps.layout}
          caption={I18n.t('Availability')}
        >
          <Table.Head>
            <Table.Row>
              <Table.ColHeader id="discussion_availability_tray_header_for">
                <Text size={responsiveProps.textSize} weight="bold">
                  {I18n.t('For')}
                </Text>
              </Table.ColHeader>
              <Table.ColHeader id="discussion_availability_tray_header_students">
                <Text size={responsiveProps.textSize} weight="bold">
                  {I18n.t('Students')}
                </Text>
              </Table.ColHeader>
              <Table.ColHeader id="discussion_availability_tray_header_available_from">
                <Text size={responsiveProps.textSize} weight="bold">
                  {I18n.t('Available From')}
                </Text>
              </Table.ColHeader>
              <Table.ColHeader id="discussion_availability_tray_header_until">
                <Text size={responsiveProps.textSize} weight="bold">
                  {I18n.t('Until')}
                </Text>
              </Table.ColHeader>
            </Table.Row>
          </Table.Head>
          <Table.Body>
            {props.availabilities.map(item => (
              <Table.Row key={item.id} data-testid="availabilities-row">
                <Table.Cell>
                  <Text size={responsiveProps.textSize}>{item.name}</Text>
                </Table.Cell>
                <Table.Cell>
                  <Text size={responsiveProps.textSize}>{item.userCount}</Text>
                </Table.Cell>
                <Table.Cell>
                  <Text size={responsiveProps.textSize}>
                    {props.delayedPostAt
                      ? DateHelper.formatDatetimeForDiscussions(props.delayedPostAt)
                      : I18n.t('No Start Date')}
                  </Text>
                </Table.Cell>
                <Table.Cell>
                  <Text size={responsiveProps.textSize}>
                    {props.lockAt
                      ? DateHelper.formatDatetimeForDiscussions(props.lockAt)
                      : I18n.t('No End Date')}
                  </Text>
                </Table.Cell>
              </Table.Row>
            ))}
          </Table.Body>
        </Table>
      )}
    />
  )
}

DiscussionAvailabilityTray.propTypes = {
  availabilities: PropTypes.array,
  lockAt: PropTypes.string,
  delayedPostAt: PropTypes.string,
}
