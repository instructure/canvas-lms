/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import {Table} from '@instructure/ui-table'
import React from 'react'
import {Responsive} from '@instructure/ui-responsive'
import {Link} from '@instructure/ui-link'
import {InfoColumn, GroupedInfoColumnHeader} from './InfoColumn'

const I18n = useI18nScope('jobs_v2')

export default function GroupsTable({groups, type, bucket, caption, onClickGroup}) {
  return (
    <div>
      <Responsive
        query={{
          small: {maxWidth: '60rem'},
          large: {minWidth: '60rem'}
        }}
        props={{
          small: {layout: 'stacked'},
          large: {layout: 'auto'}
        }}
      >
        {props => (
          <Table caption={caption} {...props}>
            <Table.Head>
              <Table.Row>
                <Table.ColHeader id="group">
                  {type === 'tag' ? I18n.t('Tag') : I18n.t('Strand')}
                </Table.ColHeader>
                <Table.ColHeader id="count">{I18n.t('Count')}</Table.ColHeader>
                <Table.ColHeader id="info">
                  <GroupedInfoColumnHeader bucket={bucket} />
                </Table.ColHeader>
              </Table.Row>
            </Table.Head>
            <Table.Body>
              {groups.map(group => {
                const tag_or_strand = group[type]
                return (
                  <Table.Row key={tag_or_strand}>
                    <Table.Cell>
                      <Link onClick={() => onClickGroup(tag_or_strand)}>{tag_or_strand}</Link>
                    </Table.Cell>
                    <Table.Cell>{group.count}</Table.Cell>
                    <Table.Cell>
                      <InfoColumn bucket={bucket} info={group.info} />
                    </Table.Cell>
                  </Table.Row>
                )
              })}
            </Table.Body>
          </Table>
        )}
      </Responsive>
    </div>
  )
}
