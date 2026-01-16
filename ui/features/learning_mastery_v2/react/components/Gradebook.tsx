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
import React, {useRef, useEffect, useState, useCallback, Fragment} from 'react'
import {DragDropContext} from 'react-dnd'
import ReactDnDHTML5Backend from 'react-dnd-html5-backend'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {StudentCell} from './grid/StudentCell'
import {StudentHeader} from './grid/StudentHeader'
import {ScoresGrid} from './grid/ScoresGrid'
import {OutcomeHeader} from './grid/OutcomeHeader'
import {OutcomeHeadersContainer} from './grid/OutcomeHeadersContainer'
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
} from '@canvas/outcomes/react/utils/constants'
import {
  Student,
  Outcome,
  StudentRollupData,
  Pagination as PaginationType,
} from '@canvas/outcomes/react/types/rollup'
import {GradebookPagination} from './pagination/GradebookPagination'
import {Sorting} from '@canvas/outcomes/react/types/shapes'
import DragDropWrapper from './grid/DragDropWrapper'
import {ContributingScoreAlignment, ContributingScoresManager} from '../hooks/useContributingScores'
import {ContributingScoreHeader} from './grid/ContributingScoreHeader'
import {BarChartRow} from './grid/BarChartRow'

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
  onOutcomesReorder?: (orderedOutcomes: Outcome[]) => void
  contributingScores: ContributingScoresManager
  onOpenStudentAssignmentTray?: (
    outcome: Outcome,
    student: Student,
    alignmentIndex: number,
    alignments: ContributingScoreAlignment[],
  ) => void
}

const GradebookComponent: React.FC<GradebookProps> = ({
  courseId,
  students,
  outcomes: initialOutcomes,
  rollups,
  pagination,
  setCurrentPage,
  sorting,
  gradebookSettings = DEFAULT_GRADEBOOK_SETTINGS,
  onChangeNameDisplayFormat,
  onOutcomesReorder,
  contributingScores,
  onOpenStudentAssignmentTray,
}) => {
  const headerRow = useRef<HTMLElement | null>(null)
  const barChartRow = useRef<HTMLElement | null>(null)
  const gridRef = useRef<HTMLElement | null>(null)
  const [outcomes, setOutcomes] = useState<Outcome[]>(initialOutcomes)

  useEffect(() => {
    setOutcomes(initialOutcomes)
  }, [initialOutcomes])

  const handleOutcomeMove = useCallback((outcomeId: string | number, hoverIndex: number) => {
    setOutcomes(prevOutcomes => {
      const dragIndex = prevOutcomes.findIndex(o => o.id.toString() === outcomeId.toString())
      if (dragIndex === -1 || dragIndex === hoverIndex) return prevOutcomes

      const reorderedOutcomes = [...prevOutcomes]
      const [draggedOutcome] = reorderedOutcomes.splice(dragIndex, 1)
      reorderedOutcomes.splice(hoverIndex, 0, draggedOutcome)

      return reorderedOutcomes
    })
  }, [])

  const handleOutcomeDragEnd = useCallback(() => {
    onOutcomesReorder?.(outcomes)
  }, [outcomes, onOutcomesReorder])

  const handleOutcomeDragLeave = useCallback(() => {
    setOutcomes(initialOutcomes)
  }, [initialOutcomes])

  useEffect(() => {
    const handleGridScroll = (e: Event) => {
      if (headerRow.current && e.target instanceof HTMLElement) {
        headerRow.current.scrollLeft = e.target.scrollLeft
      }

      if (barChartRow.current && e.target instanceof HTMLElement) {
        barChartRow.current.scrollLeft = e.target.scrollLeft
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
      <BarChartRow
        outcomes={outcomes}
        rollups={rollups}
        students={students}
        contributingScores={contributingScores}
        barChartRowRef={barChartRow}
      />
      <Flex>
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
        <OutcomeHeadersContainer onDragLeave={handleOutcomeDragLeave}>
          {connectDropTarget => (
            <View
              as="div"
              display="flex"
              id="outcomes-header"
              overflowX="hidden"
              elementRef={el => {
                if (el instanceof HTMLElement) {
                  headerRow.current = el
                  connectDropTarget(el)
                }
              }}
            >
              {outcomes.map((outcome, index) => {
                const contributingScoreForOutcome = contributingScores.forOutcome(outcome.id)
                return (
                  <Fragment key={outcome.id}>
                    <Flex.Item size={`${COLUMN_WIDTH + COLUMN_PADDING}px`}>
                      <DragDropWrapper
                        component={OutcomeHeader}
                        type="outcome-header"
                        itemId={outcome.id}
                        index={index}
                        outcome={outcome}
                        sorting={sorting}
                        contributingScoresForOutcome={contributingScoreForOutcome}
                        onMove={handleOutcomeMove}
                        onDragEnd={handleOutcomeDragEnd}
                      />
                    </Flex.Item>

                    {contributingScoreForOutcome.isVisible() &&
                      (contributingScoreForOutcome.alignments || []).map(
                        (alignment: ContributingScoreAlignment) => (
                          <Flex.Item
                            key={`alignment-${alignment.alignment_id}`}
                            size={`${COLUMN_WIDTH + COLUMN_PADDING}px`}
                          >
                            <ContributingScoreHeader
                              alignment={alignment}
                              courseId={courseId}
                              sorting={sorting}
                            />
                          </Flex.Item>
                        ),
                      )}
                  </Fragment>
                )
              })}
            </View>
          )}
        </OutcomeHeadersContainer>
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
        >
          <ScoresGrid
            students={students}
            outcomes={outcomes}
            rollups={rollups}
            scoreDisplayFormat={gradebookSettings.scoreDisplayFormat}
            contributingScores={contributingScores}
            onOpenStudentAssignmentTray={onOpenStudentAssignmentTray}
          />
        </View>
      </View>
      {pagination && pagination.totalPages > 1 && (
        <GradebookPagination pagination={pagination} onPageChange={setCurrentPage} />
      )}
    </>
  )
}

export const Gradebook = DragDropContext(ReactDnDHTML5Backend)(
  GradebookComponent,
) as React.ComponentType<GradebookProps>
