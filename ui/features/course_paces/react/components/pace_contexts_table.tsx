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

import React, {useEffect, useState} from 'react'
import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Table} from '@instructure/ui-table'
import {
  PaceContext,
  APIPaceContextTypes,
  ResponsiveSizes,
  OrderType,
  SortableColumn,
} from '../types'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Spinner} from '@instructure/ui-spinner'
import Paginator from '@canvas/instui-bindings/react/Paginator'
import {formatTimeAgoDate} from '../utils/date_stuff/date_helpers'
import {paceContextsActions} from '../actions/pace_contexts'
import {generateModalLauncherId} from '../utils/utils'

const I18n = useI18nScope('course_paces_app')

export interface PaceContextsTableProps {
  paceContexts: PaceContext[]
  contextType: APIPaceContextTypes
  pageCount: number
  currentPage: number
  currentSortBy: SortableColumn | null
  currentOrderType: OrderType
  isLoading: boolean
  responsiveSize: ResponsiveSizes
  setPage: (page: number) => void
  setOrderType: typeof paceContextsActions.setOrderType
  handleContextSelect: (paceContext: PaceContext) => void
}

interface Header {
  key: string
  text: string
  width: string
  sortable?: boolean
}

const PACE_TYPES = {
  StudentEnrollment: I18n.t('Individual'),
  CourseSection: I18n.t('Section'),
  Course: I18n.t('Default'),
}

type SortType = {
  [k in OrderType]: 'ascending' | 'descending'
}

const SORT_TYPE: SortType = {
  asc: 'ascending',
  desc: 'descending',
}

const {screenReaderFlashMessage} = $ as any
const {Item: FlexItem} = Flex as any
const {
  Body: TableBody,
  Head: TableHead,
  Row: TableRow,
  Cell: TableCell,
  ColHeader: TableColHeader,
} = Table as any

const PaceContextsTable = ({
  currentPage,
  currentSortBy,
  currentOrderType,
  paceContexts = [],
  contextType,
  pageCount,
  setPage,
  setOrderType,
  handleContextSelect,
  isLoading,
  responsiveSize,
}: PaceContextsTableProps) => {
  const [headers, setHeaders] = useState<Header[]>([])
  const paceType = contextType === 'student_enrollment' ? 'student' : 'section'
  const tableCaption = I18n.t('%{paceType} paces: sorted by %{sortBy} in %{orderType} order', {
    paceType,
    sortBy: currentSortBy,
    orderType: SORT_TYPE[currentOrderType],
  })

  useEffect(() => {
    setHeaders(getHeaderByContextType())
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [contextType])

  const formatDate = (date: string) => {
    if (!date) return '--'

    return formatTimeAgoDate(date)
  }

  const getHeaderByContextType = () => {
    let headerCols: Header[] = []
    switch (contextType) {
      case 'section':
        headerCols = [
          {key: 'name', text: I18n.t('Section'), width: '35%', sortable: true},
          {key: 'size', text: I18n.t('Section Size'), width: '25%'},
          {key: 'paceType', text: I18n.t('Pace Type'), width: '20%'},
          {key: 'modified', text: I18n.t('Last Modified'), width: '20%'},
        ]
        break
      case 'student_enrollment':
        headerCols = [
          {key: 'name', text: I18n.t('Student'), width: '35%', sortable: true},
          {key: 'pace', text: I18n.t('Assigned Pace'), width: '25%'},
          {key: 'paceType', text: I18n.t('Pace Type'), width: '20%'},
          {key: 'modified', text: I18n.t('Last Modified'), width: '20%'},
        ]
        break
      default:
        headerCols = []
    }
    return headerCols
  }

  const renderContextLink = (paceContext: PaceContext) => (
    <Link
      id={generateModalLauncherId(paceContext)}
      isWithinText={false}
      onClick={() => handleContextSelect(paceContext)}
    >
      <TruncateText>{paceContext.name}</TruncateText>
    </Link>
  )

  const getValuesByContextType = (paceContext: PaceContext) => {
    let values: string[] = []
    const appliedPace = paceContext?.applied_pace
    const appliedPaceType = paceContext?.applied_pace?.type || ''
    switch (contextType) {
      case 'section': {
        const studentCountText = I18n.t(
          {
            one: '1 Student',
            other: '%{count} Students',
          },
          {count: paceContext.associated_student_count}
        )
        values = [
          renderContextLink(paceContext),
          studentCountText.toString(),
          PACE_TYPES[appliedPaceType] || appliedPaceType,
          formatDate(appliedPace?.last_modified || ''),
        ]
        break
      }
      case 'student_enrollment':
        values = [
          renderContextLink(paceContext),
          appliedPace?.name,
          PACE_TYPES[appliedPaceType] || appliedPaceType,
          formatDate(appliedPace?.last_modified || ''),
        ]
        break
      default:
        values = []
    }
    return values
  }

  const handleSort = () => {
    const newOrderType = currentOrderType === 'asc' ? 'desc' : 'asc'
    const message = I18n.t('Sorted by %{sortBy} in %{orderType} order', {
      sortBy: currentSortBy,
      orderType: SORT_TYPE[newOrderType],
    })

    setOrderType(newOrderType)
    screenReaderFlashMessage(message)
  }

  const renderHeader = () => {
    const sortingProps = {
      onRequestSort: handleSort,
      sortDirection: currentSortBy ? SORT_TYPE[currentOrderType] : 'none',
    }
    return (
      <TableHead renderSortLabel={I18n.t('Sort By')}>
        <TableRow>
          {headers.map(header => (
            <TableColHeader
              id={`header-table-${header.key}`}
              key={`contexts-header-table-${header.key}`}
              width={header.width}
              theme={{padding: '0.75rem'}}
              {...(header.sortable && {
                ...sortingProps,
                'data-testid': `sortable-column-${header.key}`,
              })}
            >
              <View display="inline-block">
                <Text weight="bold">{header.text}</Text>
              </View>
            </TableColHeader>
          ))}
        </TableRow>
      </TableHead>
    )
  }

  const renderRow = (paceContext: PaceContext) => {
    const rowCells = getValuesByContextType(paceContext)
    return (
      <TableRow data-testid="course-pace-row" key={paceContext.item_id}>
        {rowCells.map((cell, index) => (
          <TableCell
            data-testid="course-pace-item"
            // eslint-disable-next-line react/no-array-index-key
            key={`contexts-table-cell-${index}`}
            theme={{padding: '0.75rem'}}
          >
            {cell}
          </TableCell>
        ))}
      </TableRow>
    )
  }

  const renderMobileRow = (paceContext: PaceContext) => {
    const values = getValuesByContextType(paceContext)
    return (
      <View
        key={`context-row-${paceContext.item_id}`}
        as="div"
        background="secondary"
        padding="xx-small small"
        margin="none none small none"
      >
        {headers.map(({text: title}, index) => (
          // eslint-disable-next-line react/no-array-index-key
          <Flex key={`mobile-context-row-${index}`} as="div" width="100%" margin="medium 0">
            <FlexItem size="50%">
              <Text weight="bold">{title}</Text>
            </FlexItem>
            <FlexItem size="50%">{values[index]}</FlexItem>
          </Flex>
        ))}
      </View>
    )
  }

  const loadingView = () => (
    <View as="div" textAlign="center">
      <Spinner size="large" renderTitle={I18n.t('Waiting for results to load')} />
    </View>
  )

  return (
    <>
      {responsiveSize === 'small' ? (
        !isLoading && (
          <View data-testid="pace-contexts-mobile-view">
            {paceContexts.map((paceContext: PaceContext) => renderMobileRow(paceContext))}
          </View>
        )
      ) : (
        <View as="div" margin="none none large none" borderWidth="small small none small">
          <Table
            data-testid="course-pace-context-table"
            caption={tableCaption}
            themeOverride={{
              border: '2px solid black',
            }}
          >
            {renderHeader()}
            {!isLoading && (
              <TableBody>
                {paceContexts.map((paceContext: PaceContext) => renderRow(paceContext))}
              </TableBody>
            )}
          </Table>
        </View>
      )}
      {isLoading
        ? loadingView()
        : pageCount > 1 && (
            <Paginator
              data-testid="context-table-paginator"
              loadPage={setPage}
              page={currentPage}
              pageCount={pageCount}
            />
          )}
    </>
  )
}

export default PaceContextsTable
