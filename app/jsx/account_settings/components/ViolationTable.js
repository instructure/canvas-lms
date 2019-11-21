/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React, {useState} from 'react'
import I18n from 'i18n!csp_violation_table'
import {Table} from '@instructure/ui-table'
import FriendlyDatetime from '../../shared/FriendlyDatetime'
import {Button} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {IconAddSolid} from '@instructure/ui-icons'

const HEADERS = [
  {
    get name() {
      return I18n.t('Blocked Domain Name')
    },
    id: 0,
    apiName: 'uri'
  },
  {
    get name() {
      return I18n.t('Requested')
    },
    id: 1,
    apiName: 'count'
  },
  {
    get name() {
      return I18n.t('Last Attempt')
    },
    id: 2,
    apiName: 'latest_hit'
  },
  {
    get name() {
      return I18n.t('Add to Whitelist')
    },
    id: 3,
    apiName: 'add_to_whitelist' // This isn't really an api thing though
  }
]

const getHostname = url => {
  // run against regex
  const matches = url.match(/^https?\:\/\/([^\/?#]+)(?:[\/?#]|$)/i)
  // extract hostname (will be null if no match is found)
  return matches && matches[1]
}

export default function ViolationTable({violations}) {
  const [sortBy, setSortBy] = useState('count') // Default to the most requested on top
  const [ascending, setAscending] = useState(false)
  const direction = ascending ? 'ascending' : 'descending'

  const sortedViolations = [...(violations || [])].sort((a, b) => {
    if (a[sortBy] < b[sortBy]) {
      return -1
    }
    if (a[sortBy] > b[sortBy]) {
      return 1
    }
    return 0
  })

  if (!ascending) {
    sortedViolations.reverse()
  }

  const handleSort = (event, {id}) => {
    if (id === sortBy) {
      setAscending(!ascending)
    } else {
      setSortBy(id)
      setAscending(true)
    }
  }

  return (
    <Table caption={I18n.t('CSP Violations')}>
      <Table.Head>
        <Table.Row>
          {HEADERS.map(header => {
            return (
              <Table.ColHeader
                key={header.id}
                id={header.apiName}
                onRequestSort={header.apiName === 'add_to_whitelist' ? null : handleSort}
                sortDirection={header.apiName === sortBy ? direction : 'none'}
              >
                {header.name}
              </Table.ColHeader>
            )
          })}
        </Table.Row>
      </Table.Head>
      <Table.Body>
        {sortedViolations.map(violation => {
          const hostname = getHostname(violation.uri)
          return (
            <Table.Row key={violation.uri}>
              <Table.RowHeader>{hostname}</Table.RowHeader>
              <Table.Cell>{violation.count}</Table.Cell>
              <Table.Cell>
                <FriendlyDatetime
                  dateTime={violation.latest_hit}
                  showTime={false}
                  format={I18n.t('#date.formats.medium')}
                />
              </Table.Cell>
              <Table.Cell textAlign="center">
                <Button variant="icon" size="small" icon={IconAddSolid}>
                  <ScreenReaderContent>
                    {I18n.t('Add %{hostname} to the whitelist', {hostname})}
                  </ScreenReaderContent>
                </Button>
              </Table.Cell>
            </Table.Row>
          )
        })}
      </Table.Body>
    </Table>
  )
}
