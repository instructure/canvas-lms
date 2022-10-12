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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Table} from '@instructure/ui-table'
import {PaceContext, APIPaceContextTypes, PaceContextTypes, ResponsiveSizes} from '../types'
import {dateString} from '@canvas/datetime/date-functions'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Link} from '@instructure/ui-link'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Spinner} from '@instructure/ui-spinner'
import Paginator from '@canvas/instui-bindings/react/Paginator'

const I18n = useI18nScope('course_paces_app')

export interface PaceContextsTableProps {
  paceContexts: PaceContext[]
  contextType: APIPaceContextTypes
  pageCount: number
  currentPage: number
  isLoading: boolean
  responsiveSize: ResponsiveSizes
  setPage: (page: number) => void
  handleContextSelect: (contextType: PaceContextTypes, contextId: string) => void
}

interface Header {
  text: string
  width: string
}

const PACE_TYPES = {
  StudentEnrollment: I18n.t('Individual'),
  CourseSection: I18n.t('Section'),
  Course: I18n.t('Default'),
}

export const CONTEXT_TYPE_MAP: {[k in APIPaceContextTypes]: PaceContextTypes} = {
  course: 'Course',
  section: 'Section',
  student_enrollment: 'Enrollment',
}

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
  paceContexts = [],
  contextType,
  pageCount,
  setPage,
  handleContextSelect,
  isLoading,
  responsiveSize,
}: PaceContextsTableProps) => {
  const [headers, setHeaders] = useState<Header[]>([])

  useEffect(() => {
    setHeaders(getHeaderByContextType())
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [contextType])

  const formatDate = (date: string) => {
    if (!date) return '--'

    return dateString(date, {format: 'full'})
  }

  const getHeaderByContextType = () => {
    let headerCols: Header[] = []
    switch (contextType) {
      case 'section':
        headerCols = [
          {text: I18n.t('Section'), width: '35%'},
          {text: I18n.t('Section Size'), width: '25%'},
          {text: I18n.t('Pace Type'), width: '20%'},
          {text: I18n.t('Last Modified'), width: '20%'},
        ]
        break
      case 'student_enrollment':
        headerCols = [
          {text: I18n.t('Student'), width: '35%'},
          {text: I18n.t('Assigned Pace'), width: '25%'},
          {text: I18n.t('Pace Type'), width: '20%'},
          {text: I18n.t('Last Modified'), width: '20%'},
        ]
        break
      default:
        headerCols = []
    }
    return headerCols
  }

  const renderContextLink = (paceContext: PaceContext) => (
    <Link
      isWithinText={false}
      onClick={() => handleContextSelect(CONTEXT_TYPE_MAP[contextType], paceContext.item_id)}
    >
      <TruncateText>{paceContext.name}</TruncateText>
    </Link>
  )

  const getValuesByContextType = (paceContext: PaceContext) => {
    let values: string[] = []
    const appliedPace = paceContext?.applied_pace
    const appliedPaceType = paceContext?.applied_pace?.type || ''
    switch (contextType) {
      case 'section':
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

  const renderHeader = () => (
    <TableHead>
      <TableRow>
        {headers.map((headerTitle, i) => (
          <TableColHeader
            id={`header-table-${i}`}
            key={`contexts-header-table-${i}`}
            width={headerTitle.width}
            theme={{padding: '0.75rem'}}
          >
            <View display="inline-block" minWidth="50%">
              <Text weight="bold">{headerTitle.text}</Text>
            </View>
          </TableColHeader>
        ))}
      </TableRow>
    </TableHead>
  )

  const renderRow = (paceContext: PaceContext) => {
    const rowCells = getValuesByContextType(paceContext)
    return (
      <TableRow key={paceContext.item_id}>
        {rowCells.map((cell, index) => (
          <TableCell key={`contexts-table-cell-${index}`} theme={{padding: '0.75rem'}}>
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

  if (isLoading)
    return (
      <View as="div" textAlign="center">
        <Spinner size="large" renderTitle={I18n.t('Waiting for results to load')} />
      </View>
    )

  return (
    <>
      {responsiveSize === 'small' ? (
        <View data-testid="pace-contexts-mobile-view">
          {paceContexts.map((paceContext: PaceContext) => renderMobileRow(paceContext))}
        </View>
      ) : (
        <View as="div" margin="large none" borderWidth="small small none small">
          <Table
            caption={I18n.t('Course Paces Table')}
            themeOverride={{
              border: '2px solid black',
            }}
          >
            {renderHeader()}
            <TableBody>
              {paceContexts.map((paceContext: PaceContext) => renderRow(paceContext))}
            </TableBody>
          </Table>
        </View>
      )}
      {pageCount > 1 && <Paginator loadPage={setPage} page={currentPage} pageCount={pageCount} />}
    </>
  )
}

export default PaceContextsTable
