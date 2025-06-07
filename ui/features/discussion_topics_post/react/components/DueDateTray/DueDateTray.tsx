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
import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import {responsiveQuerySizes} from '../../utils'

import {DueDatesForParticipantList} from '../DueDatesForParticipantList/DueDatesForParticipantList'
import {Responsive} from '@instructure/ui-responsive'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('discussion_posts')

interface AssignmentOverrideType {
  id: string
  _id: string
  dueAt: string | null
  lockAt: string | null
  unlockAt: string | null
  title: string
  set: any
}

interface DueDateTrayProps {
  assignmentOverrides: AssignmentOverrideType[]
  tableCaption?: string
  isAdmin?: boolean
}

export function DueDateTray({assignmentOverrides, isAdmin = true}: DueDateTrayProps) {
  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({tablet: true, desktop: true}) as any}
      props={{
        tablet: {
          layout: 'stacked' as const,
          textSize: 'small' as const,
        },
        desktop: {
          layout: 'fixed' as const,
          textSize: 'medium' as const,
        },
      }}
      render={(responsiveProps: any) => (
        <Table
          layout={responsiveProps.layout}
          caption={I18n.t('Due Dates')}
          data-testid="due-date-table"
        >
          <Table.Head>
            <Table.Row>
              <>
                <Table.ColHeader id="due_date_tray_header_due_at">
                  <Text size={responsiveProps.textSize} weight="bold">
                    {I18n.t('Due')}
                  </Text>
                </Table.ColHeader>
                {isAdmin && (
                  <Table.ColHeader
                    id="due_date_tray_header_for"
                    data-testid="due_date_tray_header_for"
                  >
                    <Text size={responsiveProps.textSize} weight="bold">
                      {I18n.t('For')}
                    </Text>
                  </Table.ColHeader>
                )}
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
              </>
            </Table.Row>
          </Table.Head>
          <Table.Body>
            {assignmentOverrides.map(item => (
              <Table.Row key={item.id} data-testid="assignment-override-row">
                <>
                  <Table.Cell>
                    <Text size={responsiveProps.textSize}>
                      {item.dueAt
                        ? DateHelper.formatDatetimeForDiscussions(item.dueAt)
                        : I18n.t('No Due Date')}
                    </Text>
                  </Table.Cell>
                  {isAdmin && (
                    <Table.Cell>
                      <Text size={responsiveProps.textSize}>
                        <DueDatesForParticipantList assignmentOverride={item} />
                      </Text>
                    </Table.Cell>
                  )}
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
                </>
              </Table.Row>
            ))}
          </Table.Body>
        </Table>
      )}
    />
  )
}
