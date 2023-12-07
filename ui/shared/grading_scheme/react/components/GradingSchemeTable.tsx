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
import {Alert} from '@instructure/ui-alerts'
import {
  IconDuplicateLine,
  IconEditLine,
  IconTrashLine,
  IconArchiveLine,
} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import type {GradingScheme, GradingSchemeCardData} from '../../gradingSchemeApiModel'
import {Link} from '@instructure/ui-link'
import {TruncateText} from '@instructure/ui-truncate-text'

const I18n = useI18nScope('GradingSchemeManagement')

type Props = {
  caption: string
  gradingSchemeCards: GradingSchemeCardData[]
  editGradingScheme: (gradingSchemeId: string) => void
  openGradingScheme: (gradingScheme: GradingScheme) => void
  viewUsedLocations: (gradingScheme: GradingScheme) => void
  openDuplicateModal: (gradingScheme: GradingScheme) => void
  openDeleteModal: (gradingScheme: GradingScheme) => void
  defaultScheme?: boolean
}
export const GradingSchemeTable = ({
  caption,
  gradingSchemeCards,
  editGradingScheme,
  openGradingScheme,
  viewUsedLocations,
  openDuplicateModal,
  openDeleteModal,
  defaultScheme = false,
}: Props) => {
  const [ascending, setAscending] = useState(true)
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
  const header = (
    <Table.Row>
      <Table.ColHeader
        id="name"
        key="name"
        width="35%"
        stackedSortByLabel="Grading Scheme Name"
        onRequestSort={handleSort}
        sortDirection={direction}
      >
        {I18n.t('Grading Scheme Name')}
      </Table.ColHeader>
      <Table.ColHeader
        id="locationsUsed"
        key="locationsUsed"
        width="45%"
        stackedSortByLabel="Locations Used"
      >
        {I18n.t('Locations Used')}
      </Table.ColHeader>
      <Table.ColHeader id="actions" key="actions" width="20%" />
    </Table.Row>
  )

  return (
    <Responsive
      query={{
        small: {maxWidth: '40rem'},
        large: {minWidth: '41rem'},
      }}
      props={{
        small: {layout: 'stacked'},
        large: {layout: 'auto'},
      }}
    >
      {props => (
        <div>
          <Table
            caption={`${caption}: sorted by grading scheme name in ${direction} order`}
            {...props}
          >
            <Table.Head renderSortLabel="Sort by">{header}</Table.Head>
            <Table.Body>
              {sortedSchemes.map(gradingSchemeCard => (
                <Table.Row key={gradingSchemeCard.gradingScheme.id}>
                  <Table.Cell key="gradingSchemeName">
                    <Link
                      onClick={() => openGradingScheme(gradingSchemeCard.gradingScheme)}
                      isWithinText={false}
                    >
                      <TruncateText>{gradingSchemeCard.gradingScheme.title}</TruncateText>
                    </Link>
                  </Table.Cell>
                  <Table.Cell key="locationsUsed">
                    {gradingSchemeCard.gradingScheme.used_locations ? (
                      <Link
                        isWithinText={false}
                        onClick={() => viewUsedLocations(gradingSchemeCard.gradingScheme)}
                      >
                        {' '}
                        {I18n.t('Show courses and assignments')}
                      </Link>
                    ) : (
                      ''
                    )}
                  </Table.Cell>
                  <Table.Cell key="actions" textAlign="end">
                    <IconButton
                      withBorder={false}
                      withBackground={false}
                      screenReaderLabel={I18n.t('Duplicate Grading Scheme')}
                      onClick={() => openDuplicateModal(gradingSchemeCard.gradingScheme)}
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
                        >
                          <IconEditLine />
                        </IconButton>
                        <IconButton
                          withBorder={false}
                          withBackground={false}
                          screenReaderLabel={I18n.t('Archive Grading Scheme')}
                        >
                          <IconArchiveLine />
                        </IconButton>
                        <IconButton
                          withBorder={false}
                          withBackground={false}
                          screenReaderLabel={I18n.t('Delete Grading Scheme')}
                          onClick={() => openDeleteModal(gradingSchemeCard.gradingScheme)}
                        >
                          <IconTrashLine />
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
          <Alert
            liveRegion={() => document.getElementById('flash-messages') || document.body}
            liveRegionPoliteness="polite"
            screenReaderOnly={true}
          >
            {`Sorted by grading scheme name in ${direction} order`}
          </Alert>
        </div>
      )}
    </Responsive>
  )
}
