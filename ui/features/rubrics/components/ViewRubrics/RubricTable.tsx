/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React from 'react'
import {useNavigate} from 'react-router-dom'
import {Table} from '@instructure/ui-table'
import {IconButton} from '@instructure/ui-buttons'
import {IconMoreLine} from '@instructure/ui-icons'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Link} from '@instructure/ui-link'

const {Head, Row, Cell, ColHeader, Body} = Table

export type RubricTableProps = {
  rubrics: {
    id: string
    name: string
    points: number
    criterion: number
    locations: string[]
  }[]
}

export const RubricTable = ({rubrics}: RubricTableProps) => {
  const navigate = useNavigate()

  return (
    <Table caption="Set text-align for columns">
      <Head>
        <Row>
          <ColHeader
            id="Rank"
            stackedSortByLabel="Rubric Name"
            onRequestSort={() => {}}
            sortDirection="none"
          >
            Rubric Name
          </ColHeader>
          <ColHeader
            id="Title"
            stackedSortByLabel="Total Points"
            onRequestSort={() => {}}
            sortDirection="none"
          >
            Total Points
          </ColHeader>
          <ColHeader
            id="Year"
            stackedSortByLabel="Criterion"
            onRequestSort={() => {}}
            sortDirection="none"
          >
            Criterion
          </ColHeader>
          <ColHeader
            id="Rating"
            stackedSortByLabel="Location Used"
            onRequestSort={() => {}}
            sortDirection="none"
          >
            Location Used
          </ColHeader>
          <ColHeader id="Rating" />
        </Row>
      </Head>
      <Body>
        {rubrics.map(rubric => (
          <Row key={rubric.id}>
            <Cell>
              <Link
                forceButtonRole={true}
                isWithinText={false}
                onClick={() => navigate(`./${rubric.id}`)}
              >
                {rubric.name}
              </Link>
            </Cell>
            <Cell>{rubric.points}</Cell>
            <Cell>{rubric.criterion}</Cell>
            <Cell>
              {rubric.locations.length > 0 ? (
                <Link forceButtonRole={true} isWithinText={false} onClick={() => {}}>
                  <TruncateText>{rubric.locations.join(', ')}...</TruncateText>
                </Link>
              ) : (
                '-'
              )}
            </Cell>
            <Cell>
              <IconButton withBackground={false} withBorder={false} screenReaderLabel="">
                <IconMoreLine />
              </IconButton>
            </Cell>
          </Row>
        ))}
      </Body>
    </Table>
  )
}
