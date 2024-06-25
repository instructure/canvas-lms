/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {useParams} from 'react-router-dom'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {Rubric} from '@canvas/rubrics/react/types/rubric'
import {Table} from '@instructure/ui-table'
import {Link} from '@instructure/ui-link'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {RubricPopover} from './RubricPopover'
import {Pill} from '@instructure/ui-pill'

const I18n = useI18nScope('rubrics-list-table')

const {Head, Row, Cell, ColHeader, Body} = Table

export type RubricTableProps = {
  canManageRubrics: boolean
  rubrics: Rubric[]
  onLocationsClick: (rubricId: string) => void
  onPreviewClick: (rubricId: string) => void
  handleArchiveRubricChange: (rubricId: string) => void
  active: boolean
}

export const RubricTable = ({
  canManageRubrics,
  rubrics,
  handleArchiveRubricChange,
  active,
  onLocationsClick,
  onPreviewClick,
}: RubricTableProps) => {
  const {accountId, courseId} = useParams()
  const [sortDirection, setSortDirection] = useState<'ascending' | 'descending' | 'none'>('none')
  const [sortedColumn, setSortedColumn] = useState<string>() // Track the column being sorted

  const handleSort = (columnId: string) => {
    if (sortedColumn === columnId) {
      setSortDirection(sortDirection === 'ascending' ? 'descending' : 'ascending')
    } else {
      setSortedColumn(columnId)
      setSortDirection('ascending')
    }
  }

  const sortedRubrics = [...rubrics].sort((a, b) => {
    if (sortedColumn === 'Title') {
      return sortDirection === 'ascending'
        ? a.title.localeCompare(b.title)
        : b.title.localeCompare(a.title)
    } else if (sortedColumn === 'TotalPoints') {
      return sortDirection === 'ascending'
        ? a.pointsPossible - b.pointsPossible
        : b.pointsPossible - a.pointsPossible
    } else if (sortedColumn === 'Criterion') {
      return sortDirection === 'ascending'
        ? a.criteriaCount - b.criteriaCount
        : b.criteriaCount - a.criteriaCount
    } else if (sortedColumn === 'LocationUsed') {
      return sortDirection === 'ascending'
        ? a.hasRubricAssociations
          ? -1
          : 1
        : a.hasRubricAssociations
        ? 1
        : -1
    } else {
      // Default sorting by ID if no specific column is selected
      return a.id.localeCompare(b.id)
    }
  })

  return (
    <Table caption={I18n.t('Rubrics')}>
      <Head renderSortLabel={<ScreenReaderContent>{I18n.t('Sort by')}</ScreenReaderContent>}>
        <Row>
          <ColHeader
            id="Title"
            stackedSortByLabel={I18n.t('Rubric Name')}
            onRequestSort={() => handleSort('Title')}
            sortDirection={sortedColumn === 'Title' ? sortDirection : undefined}
            data-testid="rubric-name-header"
          >
            {I18n.t('Rubric Name')}
          </ColHeader>
          <ColHeader
            id="TotalPoints"
            stackedSortByLabel={I18n.t('Total Points')}
            onRequestSort={() => handleSort('TotalPoints')}
            sortDirection={sortedColumn === 'TotalPoints' ? sortDirection : undefined}
            data-testid="rubric-points-header"
          >
            {I18n.t('Total Points')}
          </ColHeader>
          <ColHeader
            id="Criterion"
            stackedSortByLabel={I18n.t('Criterion')}
            onRequestSort={() => handleSort('Criterion')}
            sortDirection={sortedColumn === 'Criterion' ? sortDirection : undefined}
            data-testid="rubric-criterion-header"
          >
            {I18n.t('Criterion')}
          </ColHeader>
          <ColHeader
            id="LocationUsed"
            stackedSortByLabel={I18n.t('Location Used')}
            onRequestSort={() => handleSort('LocationUsed')}
            sortDirection={sortedColumn === 'LocationUsed' ? sortDirection : undefined}
            data-testid="rubric-locations-header"
          >
            {I18n.t('Location Used')}
          </ColHeader>
          <ColHeader id="Actions" tabIndex={0} data-testid="rubric-actions-header">
            {I18n.t('Actions')}
          </ColHeader>
        </Row>
      </Head>
      <Body>
        {sortedRubrics.map((rubric, index) => (
          <Row key={rubric.id} data-testid={`rubric-row-${rubric.id}`}>
            <Cell data-testid={`rubric-title-${index}`}>
              <Link
                forceButtonRole={true}
                isWithinText={false}
                data-testid={`rubric-title-preview-${rubric.id}`}
                onClick={() => onPreviewClick(rubric.id)}
              >
                {rubric.title}
              </Link>
              {rubric.workflowState === 'draft' && <Pill margin="x-small">{I18n.t('Draft')}</Pill>}
            </Cell>
            <Cell data-testid={`rubric-points-${index}`}>{rubric.pointsPossible}</Cell>
            <Cell data-testid={`rubric-criterion-count-${index}`}>{rubric.criteriaCount}</Cell>
            <Cell data-testid={`rubric-locations-${index}`}>
              {rubric.hasRubricAssociations ? (
                <Link
                  forceButtonRole={true}
                  isWithinText={false}
                  onClick={() => onLocationsClick(rubric.id)}
                >
                  {I18n.t('courses and assignments')}
                </Link>
              ) : (
                '-'
              )}
            </Cell>
            <Cell data-testid={`rubric-options-${rubric.id}`}>
              {canManageRubrics && (
                <RubricPopover
                  id={rubric.id}
                  title={rubric.title}
                  accountId={accountId}
                  courseId={courseId}
                  hidePoints={rubric.hidePoints}
                  criteria={rubric.criteria}
                  pointsPossible={rubric.pointsPossible}
                  buttonDisplay={rubric.buttonDisplay}
                  ratingOrder={rubric.ratingOrder}
                  freeFormCriterionComments={rubric.freeFormCriterionComments}
                  hasRubricAssociations={rubric.hasRubricAssociations}
                  onArchiveRubricChange={() => handleArchiveRubricChange(rubric.id)}
                  active={active}
                />
              )}
            </Cell>
          </Row>
        ))}
      </Body>
    </Table>
  )
}
