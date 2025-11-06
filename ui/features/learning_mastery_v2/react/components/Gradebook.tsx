/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import React, {useRef, useEffect} from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {StudentCell} from './grid/StudentCell'
import {OutcomeHeader} from './grid/OutcomeHeader'
import {StudentHeader} from './grid/StudentHeader'
import {ScoresGrid} from './grid/ScoresGrid'
import {
  COLUMN_WIDTH,
  STUDENT_COLUMN_WIDTH,
  STUDENT_COLUMN_RIGHT_PADDING,
  COLUMN_PADDING,
  CELL_HEIGHT,
  GradebookSettings,
  DEFAULT_GRADEBOOK_SETTINGS,
  DisplayFilter,
  NameDisplayFormat,
} from '../utils/constants'
import {Student, Outcome, StudentRollupData, Pagination as PaginationType} from '../types/rollup'
import {GradebookPagination} from './pagination/GradebookPagination'
import {Sorting} from '../types/shapes'

export interface GradebookProps {
  courseId: string
  students: Student[]
  outcomes: Outcome[]
  rollups: StudentRollupData[]
  pagination?: PaginationType
  setCurrentPage: (page: number) => void
  sorting: Sorting
  gradebookSettings?: GradebookSettings
  onChangeNameDisplayFormat: (format: NameDisplayFormat) => void
}

export const Gradebook: React.FC<GradebookProps> = ({
  courseId,
  students,
  outcomes,
  rollups,
  pagination,
  setCurrentPage,
  sorting,
  gradebookSettings = DEFAULT_GRADEBOOK_SETTINGS,
  onChangeNameDisplayFormat,
}) => {
  const headerRow = useRef<HTMLElement | null>(null)
  const gridRef = useRef<HTMLElement | null>(null)

  useEffect(() => {
    const handleGridScroll = (e: Event) => {
      if (headerRow.current && e.target instanceof HTMLElement) {
        headerRow.current.scrollLeft = e.target.scrollLeft
      }
    }

    if (gridRef.current) {
      gridRef.current.addEventListener('scroll', handleGridScroll)
    }

    return function cleanup() {
      if (gridRef.current) {
        gridRef.current.removeEventListener('scroll', handleGridScroll)
      }
    }
  }, [])

  return (
    <>
      <Flex padding="medium 0 0 0">
        <Flex.Item>
          <View borderWidth="large 0 medium 0">
            <StudentHeader
              sorting={sorting}
              nameDisplayFormat={gradebookSettings.nameDisplayFormat}
              onChangeNameDisplayFormat={onChangeNameDisplayFormat}
            />
          </View>
        </Flex.Item>
        <Flex.Item size={`${STUDENT_COLUMN_RIGHT_PADDING}px`} />
        <View
          as="div"
          display="flex"
          id="outcomes-header"
          overflowX="hidden"
          elementRef={el => {
            if (el instanceof HTMLElement) {
              headerRow.current = el
            }
          }}
        >
          {outcomes.map((outcome, index) => (
            <Flex.Item size={`${COLUMN_WIDTH + COLUMN_PADDING}px`} key={`${outcome.id}.${index}`}>
              <OutcomeHeader outcome={outcome} sorting={sorting} />
            </Flex.Item>
          ))}
        </View>
      </Flex>
      <View display="flex">
        <View as="div" minWidth={STUDENT_COLUMN_WIDTH + STUDENT_COLUMN_RIGHT_PADDING}>
          {students.map(student => (
            <View
              key={student.id}
              as="div"
              overflowX="auto"
              background="primary"
              borderWidth="0 0 small 0"
              height={CELL_HEIGHT}
              width={STUDENT_COLUMN_WIDTH}
            >
              <StudentCell
                courseId={courseId}
                student={student}
                secondaryInfoDisplay={gradebookSettings.secondaryInfoDisplay}
                showStudentAvatar={gradebookSettings.displayFilters.includes(
                  DisplayFilter.SHOW_STUDENT_AVATARS,
                )}
                nameDisplayFormat={gradebookSettings.nameDisplayFormat}
                outcomes={outcomes}
                rollups={rollups}
              />
            </View>
          ))}
        </View>
        <View
          as="div"
          overflowX="auto"
          overflowY="auto"
          elementRef={el => {
            if (el instanceof HTMLElement) {
              gridRef.current = el
            }
          }}
          width={outcomes.length * COLUMN_WIDTH}
        >
          <ScoresGrid students={students} outcomes={outcomes} rollups={rollups} />
        </View>
      </View>
      {pagination && pagination.totalPages > 1 && (
        <GradebookPagination pagination={pagination} onPageChange={setCurrentPage} />
      )}
    </>
  )
}
