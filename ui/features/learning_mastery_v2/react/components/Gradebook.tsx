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
import React, {useEffect, useState, useCallback} from 'react'
import {DragDropContext} from 'react-dnd'
import ReactDnDHTML5Backend from 'react-dnd-html5-backend'
import {
  GradebookSettings,
  DEFAULT_GRADEBOOK_SETTINGS,
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
import {
  ContributingScoreAlignment,
  ContributingScoresManager,
} from '@canvas/outcomes/react/hooks/useContributingScores'
import {GradebookTable} from './GradebookTable'
import {OutcomeDistribution} from '@canvas/outcomes/react/types/mastery_distribution'

export interface GradebookProps {
  courseId: string
  students: Student[]
  outcomes: Outcome[]
  rollups: StudentRollupData[]
  outcomeDistributions?: Record<string, OutcomeDistribution>
  distributionStudents?: Student[]
  isLoadingDistribution?: boolean
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
  outcomeDistributions,
  distributionStudents,
  isLoadingDistribution = false,
  pagination,
  setCurrentPage,
  sorting,
  gradebookSettings = DEFAULT_GRADEBOOK_SETTINGS,
  onChangeNameDisplayFormat,
  onOutcomesReorder,
  contributingScores,
  onOpenStudentAssignmentTray,
}) => {
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

  return (
    <>
      <GradebookTable
        courseId={courseId}
        students={students}
        outcomes={outcomes}
        rollups={rollups}
        sorting={sorting}
        outcomeDistributions={outcomeDistributions}
        distributionStudents={distributionStudents}
        isLoadingDistribution={isLoadingDistribution}
        gradebookSettings={gradebookSettings}
        onChangeNameDisplayFormat={onChangeNameDisplayFormat}
        contributingScores={contributingScores}
        onOpenStudentAssignmentTray={onOpenStudentAssignmentTray}
        handleOutcomeReorder={handleOutcomeMove}
        handleOutcomeDragEnd={handleOutcomeDragEnd}
        handleOutcomeDragLeave={handleOutcomeDragLeave}
      />
      {pagination && pagination.totalPages > 1 && (
        <GradebookPagination pagination={pagination} onPageChange={setCurrentPage} />
      )}
    </>
  )
}

export const Gradebook = DragDropContext(ReactDnDHTML5Backend)(
  GradebookComponent,
) as React.ComponentType<GradebookProps>
