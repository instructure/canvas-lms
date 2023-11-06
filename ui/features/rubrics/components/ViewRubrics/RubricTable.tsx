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
import {useScope as useI18nScope} from '@canvas/i18n'
import type {Rubric} from '@canvas/rubrics/react/types/rubric'
import {Table} from '@instructure/ui-table'
import {IconButton} from '@instructure/ui-buttons'
import {IconMoreLine} from '@instructure/ui-icons'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Link} from '@instructure/ui-link'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('rubrics-list-table')

const {Head, Row, Cell, ColHeader, Body} = Table

export type RubricTableProps = {
  rubrics: Rubric[]
}

export const RubricTable = ({rubrics}: RubricTableProps) => {
  const navigate = useNavigate()

  return (
    <Table caption="Set text-align for columns">
      <Head renderSortLabel={<ScreenReaderContent>{I18n.t('Sort by')}</ScreenReaderContent>}>
        <Row>
          <ColHeader
            id="Rank"
            stackedSortByLabel={I18n.t('Rubric Name')}
            onRequestSort={() => {}}
            sortDirection="none"
          >
            {I18n.t('Rubric Name')}
          </ColHeader>
          <ColHeader
            id="Title"
            stackedSortByLabel={I18n.t('Total Points')}
            onRequestSort={() => {}}
            sortDirection="none"
          >
            {I18n.t('Total Points')}
          </ColHeader>
          <ColHeader
            id="Year"
            stackedSortByLabel={I18n.t('Criterion')}
            onRequestSort={() => {}}
            sortDirection="none"
          >
            {I18n.t('Criterion')}
          </ColHeader>
          <ColHeader
            id="Rating"
            stackedSortByLabel={I18n.t('Location Used')}
            onRequestSort={() => {}}
            sortDirection="none"
          >
            {I18n.t('Location Used')}
          </ColHeader>
          <ColHeader id="Rating" />
        </Row>
      </Head>
      <Body>
        {rubrics.map(rubric => (
          <Row key={rubric.id}>
            <Cell data-testid={`rubric-title-${rubric.id}`}>
              <Link
                forceButtonRole={true}
                isWithinText={false}
                onClick={() => navigate(`./${rubric.id}`)}
              >
                {rubric.title}
              </Link>
            </Cell>
            <Cell data-testid={`rubric-points-${rubric.id}`}>{rubric.pointsPossible}</Cell>
            <Cell data-testid={`rubric-criterion-count-${rubric.id}`}>{rubric.criteriaCount}</Cell>
            <Cell data-testid={`rubric-locations-${rubric.id}`}>
              {rubric.locations.length > 0 ? (
                <Link forceButtonRole={true} isWithinText={false} onClick={() => {}}>
                  <TruncateText>{rubric.locations.join(', ')}...</TruncateText>
                </Link>
              ) : (
                '-'
              )}
            </Cell>
            <Cell data-testid={`rubric-options-${rubric.id}`}>
              <IconButton
                withBackground={false}
                withBorder={false}
                screenReaderLabel={I18n.t('Rubric Options')}
              >
                <IconMoreLine />
              </IconButton>
            </Cell>
          </Row>
        ))}
      </Body>
    </Table>
  )
}
