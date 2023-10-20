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
import React, {useCallback} from 'react'
import {Responsive} from '@instructure/ui-responsive'
import {Link} from '@instructure/ui-link'
import {InfoColumn, GroupedInfoColumnHeader} from './InfoColumn'
import SortColumnHeader from './SortColumnHeader'
import OrphanedStrandIndicator from './OrphanedStrandIndicator'

const I18n = useI18nScope('jobs_v2')

export default function GroupsTable({
  groups,
  type,
  typeCaption,
  bucket,
  caption,
  sortColumn,
  onClickGroup,
  onClickHeader,
  onUnblock,
  timeZone,
}) {
  const renderColHeader = useCallback(
    (attr, width, content) => {
      return (
        <Table.ColHeader id={attr} width={width}>
          <SortColumnHeader
            bucket={bucket}
            attr={attr}
            content={content}
            sortColumn={sortColumn}
            onClickHeader={onClickHeader}
          />
        </Table.ColHeader>
      )
    },
    [bucket, sortColumn, onClickHeader]
  )

  return (
    <div>
      <Responsive
        query={{
          small: {maxWidth: '719px'},
          large: {minWidth: '720px'},
        }}
        props={{
          small: {layout: 'stacked'},
          large: {layout: 'auto'},
        }}
      >
        {props => (
          <Table caption={caption} {...props}>
            <Table.Head>
              <Table.Row>
                {renderColHeader('group', '', typeCaption)}
                {renderColHeader('count', '6em', I18n.t('Count'))}
                {renderColHeader('info', '11em', <GroupedInfoColumnHeader bucket={bucket} />)}
              </Table.Row>
            </Table.Head>
            <Table.Body>
              {groups.map(group => {
                const tag_or_strand = group[type]
                return (
                  <Table.Row key={tag_or_strand}>
                    <Table.Cell>
                      {group.orphaned ? (
                        <OrphanedStrandIndicator
                          name={tag_or_strand}
                          type={type}
                          onComplete={onUnblock}
                        />
                      ) : null}
                      <Link onClick={() => onClickGroup(tag_or_strand)}>{tag_or_strand}</Link>
                    </Table.Cell>
                    <Table.Cell>{group.count}</Table.Cell>
                    <Table.Cell>
                      <InfoColumn timeZone={timeZone} bucket={bucket} info={group.info} />
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
