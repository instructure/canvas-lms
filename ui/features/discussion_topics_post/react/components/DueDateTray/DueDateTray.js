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

import I18n from 'i18n!discussion_posts'

import PropTypes from 'prop-types'
import React from 'react'
import DateHelper from '../../../../../shared/datetime/dateHelper'
import {responsiveQuerySizes} from '../../utils'

import {Text} from '@instructure/ui-text'
import {Table} from '@instructure/ui-table'
import {Responsive} from '@instructure/ui-responsive'

export function DueDateTray({...props}) {
  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          layout: 'stacked',
          textSize: 'small'
        },
        desktop: {
          layout: 'fixed',
          textSize: 'medium'
        }
      }}
      render={responsiveProps => (
        <Table layout={responsiveProps.layout} caption={I18n.t('Due Dates')}>
          <Table.Head>
            <Table.Row>
              <Table.ColHeader id="due_date_tray_header_due_at">
                <Text size={responsiveProps.textSize} weight="bold">
                  {I18n.t('Due')}
                </Text>
              </Table.ColHeader>
              <Table.ColHeader id="due_date_tray_header_for">
                <Text size={responsiveProps.textSize} weight="bold">
                  {I18n.t('For')}
                </Text>
              </Table.ColHeader>
              <Table.ColHeader id="due_date_tray_header_available_from">
                <Text size={responsiveProps.textSize} weight="bold">
                  {I18n.t('Available From')}
                </Text>
              </Table.ColHeader>
              <Table.ColHeader id="due_date_tray_header_until">
                <Text size={responsiveProps.textSize} weight="bold">
                  {I18n.t('Until')}
                </Text>
              </Table.ColHeader>
            </Table.Row>
          </Table.Head>
          <Table.Body>
            {props.assignmentOverrides.map(item => (
              <Table.Row key={item.id} data-testid="assignment-override-row">
                <Table.Cell>
                  <Text size={responsiveProps.textSize}>
                    {item.dueAt
                      ? DateHelper.formatDatetimeForDiscussions(item.dueAt)
                      : I18n.t('No Due Date')}
                  </Text>
                </Table.Cell>
                <Table.Cell>
                  <Text size={responsiveProps.textSize}>
                    {item.title.length < 34 ? item.title : `${item.title.slice(0, 32)}...`}
                  </Text>
                </Table.Cell>
                <Table.Cell>
                  <Text size={responsiveProps.textSize}>
                    {item.unlockAt
                      ? DateHelper.formatDatetimeForDiscussions(item.unlockAt)
                      : I18n.t('No Start Date')}
                  </Text>
                </Table.Cell>
                <Table.Cell>
                  <Text size={responsiveProps.textSize}>
                    {item.lockAt
                      ? DateHelper.formatDatetimeForDiscussions(item.lockAt)
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

DueDateTray.prototype = {
  assignmentOverrides: PropTypes.array,
  tableCaption: PropTypes.string
}
