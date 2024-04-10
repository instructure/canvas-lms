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

import React, {useState} from 'react'
import {Table} from '@instructure/ui-table'
import {Responsive} from '@instructure/ui-responsive'
import {useScope as useI18nScope} from '@canvas/i18n'
import {
  IconDuplicateLine,
  IconEditLine,
  IconTrashLine,
  IconArchiveLine,
  IconUnarchiveLine,
} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import type {GradingScheme, GradingSchemeCardData} from '../../gradingSchemeApiModel'
import {Link} from '@instructure/ui-link'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {Pagination} from '@instructure/ui-pagination'

const I18n = useI18nScope('GradingSchemeManagement')

export type GradingSchemeTableProps = {
  caption: string
  gradingSchemeCards: GradingSchemeCardData[]
  showUsedLocations: boolean
  editGradingScheme: (gradingSchemeId: string) => void
  openGradingScheme: (gradingScheme: GradingScheme) => void
  viewUsedLocations: (gradingScheme: GradingScheme) => void
  openDuplicateModal: (gradingScheme: GradingScheme) => void
  openDeleteModal: (gradingScheme: GradingScheme) => void
  archiveOrUnarchiveScheme: (gradingScheme: GradingScheme) => void
  defaultScheme?: boolean
  archivedSchemes?: boolean
}
export const GradingSchemeTable = ({
  caption,
  gradingSchemeCards,
  showUsedLocations,
  editGradingScheme,
  openGradingScheme,
  viewUsedLocations,
  openDuplicateModal,
  openDeleteModal,
  archiveOrUnarchiveScheme,
  defaultScheme = false,
  archivedSchemes = false,
}: GradingSchemeTableProps) => {
  const [ascending, setAscending] = useState(true)
  const [currentPage, setCurrentPage] = useState<number>(0)
  const direction = ascending ? 'ascending' : 'descending'
  const sortedSchemes = gradingSchemeCards.sort((a, b) =>
    a.gradingScheme.title.localeCompare(b.gradingScheme.title)
  )
  if (!ascending) {
    sortedSchemes.reverse()
  }
  const handleSort = (_event: React.SyntheticEvent<Element, Event>, _param: {id: string}) => {
    setAscending(!ascending)
  }
  const currentPageSchemes = sortedSchemes.slice(currentPage * 10, currentPage * 10 + 10)
  const pages = [...Array(Math.ceil(sortedSchemes.length / 10)).keys()].map((v, index) => (
    <Pagination.Page
      data-testid={`scheme-table-page-${index}`}
      key={v}
      onClick={() => setCurrentPage(index)}
      current={index === currentPage}
    >
      {index + 1}{' '}
    </Pagination.Page>
  ))
  const header = (
    <Table.Row>
      <Table.ColHeader
        id="name"
        key="name"
        width="35%"
        stackedSortByLabel="Grading Scheme Name"
        data-testid="grading-scheme-name-header"
        onRequestSort={handleSort}
        sortDirection={direction}
      >
        {I18n.t('Grading Scheme Name')}
      </Table.ColHeader>
      {showUsedLocations && (
        <Table.ColHeader
          id="locationsUsed"
          key="locationsUsed"
          width="45%"
          stackedSortByLabel="Locations Used"
        >
          {I18n.t('Locations Used')}
        </Table.ColHeader>
      )}
      <Table.ColHeader id="actions" key="actions" width="20%" />
    </Table.Row>
  )
  if (gradingSchemeCards.length === 0) {
    return (
      <>
        {archivedSchemes
          ? I18n.t('You have no archived grading schemes.')
          : I18n.t('You have no active grading schemes.')}
      </>
    )
  }
  return (
    <>
      <Responsive
        query={{
          large: {minWidth: '41rem'},
        }}
        props={{
          large: {layout: 'auto'},
        }}
      >
        {props => (
          <div>
            <Table
              caption={`${caption}: sorted by grading scheme name in ${direction} order`}
              data-testid={`grading-scheme-table-${
                archivedSchemes ? 'archived' : defaultScheme ? 'default' : 'active'
              }`}
              {...props}
            >
              <Table.Head renderSortLabel="Sort by">{header}</Table.Head>
              <Table.Body>
                {currentPageSchemes.map(gradingSchemeCard => (
                  <Table.Row
                    key={gradingSchemeCard.gradingScheme.id}
                    data-testid={`grading-scheme-row-${gradingSchemeCard.gradingScheme.id}`}
                  >
                    <Table.Cell>
                      <Link
                        onClick={() => openGradingScheme(gradingSchemeCard.gradingScheme)}
                        isWithinText={false}
                        data-testid={`grading-scheme-${gradingSchemeCard.gradingScheme.id}-name`}
                      >
                        <TruncateText>{gradingSchemeCard.gradingScheme.title}</TruncateText>
                      </Link>
                    </Table.Cell>
                    {showUsedLocations && (
                      <Table.Cell>
                        {gradingSchemeCard.gradingScheme.assessed_assignment ? (
                          <Link
                            isWithinText={false}
                            onClick={() => viewUsedLocations(gradingSchemeCard.gradingScheme)}
                            data-testid={`grading-scheme-${gradingSchemeCard.gradingScheme.id}-view-locations-button`}
                          >
                            {I18n.t('Show courses and assignments')}
                          </Link>
                        ) : (
                          ''
                        )}
                      </Table.Cell>
                    )}
                    <Table.Cell textAlign="end">
                      <IconButton
                        withBorder={false}
                        withBackground={false}
                        screenReaderLabel={I18n.t('Duplicate Grading Scheme')}
                        onClick={() => openDuplicateModal(gradingSchemeCard.gradingScheme)}
                        data-testid={`grading-scheme-${gradingSchemeCard.gradingScheme.id}-duplicate-button`}
                      >
                        <IconDuplicateLine />
                      </IconButton>
                      {!defaultScheme ? (
                        <>
                          <IconButton
                            withBorder={false}
                            withBackground={false}
                            onClick={() => editGradingScheme(gradingSchemeCard.gradingScheme.id)}
                            screenReaderLabel={I18n.t('Edit Grading Scheme')}
                            data-testid={`grading-scheme-${gradingSchemeCard.gradingScheme.id}-edit-button`}
                          >
                            <IconEditLine />
                          </IconButton>
                          <IconButton
                            withBorder={false}
                            withBackground={false}
                            screenReaderLabel={
                              archivedSchemes
                                ? I18n.t('Unarchive Grading Scheme')
                                : I18n.t('Archive Grading Scheme')
                            }
                            onClick={() =>
                              archiveOrUnarchiveScheme(gradingSchemeCard.gradingScheme)
                            }
                            data-testid={`grading-scheme-${gradingSchemeCard.gradingScheme.id}-archive-button`}
                          >
                            {archivedSchemes ? <IconUnarchiveLine /> : <IconArchiveLine />}
                          </IconButton>

                          <IconButton
                            withBorder={false}
                            withBackground={false}
                            screenReaderLabel={I18n.t('Delete Grading Scheme')}
                            onClick={() => openDeleteModal(gradingSchemeCard.gradingScheme)}
                            data-testid={`grading-scheme-${gradingSchemeCard.gradingScheme.id}-delete-button`}
                            disabled={gradingSchemeCard.gradingScheme.assessed_assignment}
                          >
                            {gradingSchemeCard.gradingScheme.assessed_assignment ? (
                              <Tooltip
                                renderTip={I18n.t(
                                  "You can't delete this grading scheme because it is in use."
                                )}
                              >
                                <IconTrashLine />
                              </Tooltip>
                            ) : (
                              <IconTrashLine />
                            )}
                          </IconButton>
                        </>
                      ) : (
                        <></>
                      )}
                    </Table.Cell>
                  </Table.Row>
                ))}
              </Table.Body>
            </Table>
          </div>
        )}
      </Responsive>
      {pages.length > 1 && (
        <Pagination
          as="nav"
          margin="small"
          variant="compact"
          labelNext={I18n.t('Next Page')}
          labelPrev={I18n.t('Previous Page')}
          data-testid="grading-scheme-table-pagination"
        >
          {pages}
        </Pagination>
      )}
    </>
  )
}
