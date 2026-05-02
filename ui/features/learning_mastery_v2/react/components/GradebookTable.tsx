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

import {useScope as createI18nScope} from '@canvas/i18n'
import {
  ContributingScoreAlignment,
  ContributingScoresManager,
} from '@canvas/outcomes/react/hooks/useContributingScores'
import useLMGBContext from '@canvas/outcomes/react/hooks/useLMGBContext'
import {OutcomeDistribution} from '@canvas/outcomes/react/types/mastery_distribution'
import {
  Outcome,
  OutcomeRollup,
  Student,
  StudentRollupData,
} from '@canvas/outcomes/react/types/rollup'
import {Sorting} from '@canvas/outcomes/react/types/shapes'
import {
  COLUMN_PADDING,
  DEFAULT_GRADEBOOK_SETTINGS,
  GradebookSettings,
  STUDENT_COLUMN_RIGHT_PADDING,
  STUDENT_COLUMN_WIDTH,
} from '@canvas/outcomes/react/utils/constants'
import {StudentCell} from '@instructure/outcomes-ui/es/components/Gradebook/gradebook-table/StudentCell'
import {Table} from '@instructure/outcomes-ui/es/components/Gradebook/table/Table'
import type {Column} from '@instructure/outcomes-ui/lib/components/Gradebook/table/Table'
import {
  CELL_HEIGHT,
  COLUMN_WIDTH,
  DisplayFilter,
  NameDisplayFormat,
  SecondaryInfoDisplay,
} from '@instructure/outcomes-ui/lib/util/gradebook/constants'
import {Breakpoints, WithBreakpoints} from '@instructure/platform-with-breakpoints'
import {View} from '@instructure/ui-view'
import {keyBy} from 'es-toolkit'
import React, {useCallback, useMemo} from 'react'
import {BarChartRow} from './grid/BarChartRow'
import {ContributingScoreHeader} from './grid/ContributingScoreHeader'
import {OutcomeHeader} from './grid/OutcomeHeader'
import {StudentCellPopover} from './grid/StudentCellPopover'
import {StudentHeader} from './grid/StudentHeader'
import {StudentOutcomeScore} from './grid/StudentOutcomeScore'
import {ContributingScoreCellContent} from './table/ContributingScoreCellContent'

const I18n = createI18nScope('LearningMasteryGradebook')

interface GradebookTableProps {
  courseId: string
  students: Student[]
  outcomes: Outcome[]
  rollups: StudentRollupData[]
  outcomeDistributions?: Record<string, OutcomeDistribution>
  distributionStudents?: Student[]
  isLoadingDistribution?: boolean
  sorting: Sorting
  gradebookSettings?: GradebookSettings
  onChangeNameDisplayFormat: (format: NameDisplayFormat) => void
  contributingScores: ContributingScoresManager
  onOpenStudentAssignmentTray?: (
    outcome: Outcome,
    student: Student,
    alignmentIndex: number,
    alignments: ContributingScoreAlignment[],
  ) => void
  handleOutcomeReorder?: (draggedId: string | number, hoverIndex: number) => void
  handleOutcomeDragEnd?: () => void
  handleOutcomeDragLeave?: () => void
}

type GradebookTableComponentProps = GradebookTableProps & {breakpoints?: Breakpoints}

interface ExtendedOutcomeRollup extends OutcomeRollup {
  studentId: string | number
}

const GradebookTableComponent: React.FC<GradebookTableComponentProps> = ({
  courseId,
  students,
  outcomes,
  rollups,
  outcomeDistributions,
  distributionStudents,
  isLoadingDistribution,
  sorting,
  gradebookSettings = DEFAULT_GRADEBOOK_SETTINGS,
  onChangeNameDisplayFormat,
  contributingScores,
  onOpenStudentAssignmentTray,
  handleOutcomeReorder,
  handleOutcomeDragEnd,
  handleOutcomeDragLeave,
  breakpoints = {},
}) => {
  const isMobile = breakpoints?.mobileOnly
  const {lmgbStudentReportingFF} = useLMGBContext()

  const rollupsByStudentAndOutcome = useMemo(() => {
    const outcomeRollups = rollups.flatMap(r =>
      r.outcomeRollups.map(or => ({
        studentId: r.studentId,
        ...or,
      })),
    ) as ExtendedOutcomeRollup[]

    return keyBy(
      outcomeRollups,
      ({studentId, outcomeId}: ExtendedOutcomeRollup) => `${studentId}_${outcomeId}`,
    )
  }, [rollups])

  const tableData = useMemo(() => {
    return students.map(student => {
      const row: Record<string, any> = {
        student: student,
      }

      outcomes.forEach(outcome => {
        row[`outcome-${outcome.id}`] = {
          rollup: rollupsByStudentAndOutcome[`${student.id}_${outcome.id}`],
          outcome: outcome,
        }

        const contributingScoreForOutcome = contributingScores.forOutcome(outcome.id)
        if (contributingScoreForOutcome.isVisible()) {
          const scores = contributingScoreForOutcome.scoresForUser(student.id)

          contributingScoreForOutcome.alignments?.forEach((alignment, alignment_index) => {
            row[`contributing-score-${outcome.id}-${alignment.alignment_id}`] = {
              rollup: scores[alignment_index],
              outcome: outcome,
              alignment: alignment,
            }
          })
        }
      })

      return row
    })
  }, [students, outcomes, contributingScores, rollupsByStudentAndOutcome])

  const renderStudentHeader = useCallback(
    () => (
      <StudentHeader
        sorting={sorting}
        nameDisplayFormat={gradebookSettings.nameDisplayFormat}
        onChangeNameDisplayFormat={onChangeNameDisplayFormat}
      />
    ),
    [sorting, gradebookSettings.nameDisplayFormat, onChangeNameDisplayFormat],
  )

  const renderStudentCell = useCallback(
    (cellData: any) => {
      const student = cellData
      const studentName =
        gradebookSettings.nameDisplayFormat === NameDisplayFormat.LAST_FIRST
          ? student.sortable_name
          : student.display_name
      const studentGradesUrl = lmgbStudentReportingFF
        ? `/courses/${courseId}/outcomes?student_id=${student.id}#reporting`
        : `/courses/${courseId}/grades/${student.id}#tab-outcomes`

      const secondaryInfo = {
        [SecondaryInfoDisplay.SIS_ID]: student.sis_id,
        [SecondaryInfoDisplay.INTEGRATION_ID]: student.integration_id,
        [SecondaryInfoDisplay.LOGIN_ID]: student.login_id,
        [SecondaryInfoDisplay.NONE]: undefined,
      }[gradebookSettings.secondaryInfoDisplay]

      return (
        <StudentCell
          student={{
            id: String(student.id),
            displayName: student.display_name,
            sortableName: student.sortable_name,
            avatarUrl: student.avatar_url,
            status: student.status,
          }}
          studentPopover={
            <StudentCellPopover
              key={student.id}
              student={student}
              studentName={studentName}
              studentGradesUrl={studentGradesUrl}
              courseId={courseId}
              outcomes={outcomes}
              rollups={rollups}
            />
          }
          secondaryInfo={secondaryInfo}
          showStudentAvatar={gradebookSettings.displayFilters.includes(
            DisplayFilter.SHOW_STUDENT_AVATARS,
          )}
          nameDisplayFormat={gradebookSettings.nameDisplayFormat}
        />
      )
    },
    [courseId, gradebookSettings, outcomes, rollups],
  )

  const renderOutcomeHeader = useCallback(
    (outcome: Outcome, contributingScoreForOutcome: any) => () => {
      return (
        <OutcomeHeader
          outcome={outcome}
          outcomeDistribution={outcomeDistributions?.[outcome.id.toString()]}
          distributionStudents={distributionStudents}
          courseId={courseId}
          sorting={sorting}
          contributingScoresForOutcome={contributingScoreForOutcome}
        />
      )
    },
    [sorting, outcomeDistributions, distributionStudents, courseId],
  )

  const renderOutcomeCell = useCallback(
    (outcome: Outcome) => (cellData: any, rowData: any) => {
      return (
        <View as="div" data-testid={`student-outcome-score-${rowData['student'].id}-${outcome.id}`}>
          <StudentOutcomeScore
            outcome={outcome}
            score={cellData.rollup?.score}
            scoreDisplayFormat={gradebookSettings.scoreDisplayFormat}
          />
        </View>
      )
    },
    [gradebookSettings.scoreDisplayFormat],
  )

  const renderContributingScoreHeader = useCallback(
    (alignment: ContributingScoreAlignment) => () => (
      <ContributingScoreHeader alignment={alignment} courseId={courseId} sorting={sorting} />
    ),
    [courseId, sorting],
  )

  const renderContributingScoreCell = useCallback(
    (outcome: Outcome, alignment: ContributingScoreAlignment, contributingScoreForOutcome: any) =>
      (cellData: any, rowData: any, focus?: boolean) => {
        const student = rowData.student
        const alignmentIndex = contributingScoreForOutcome.alignments?.indexOf(alignment) ?? -1
        const rollup = cellData.rollup
        const onAction = onOpenStudentAssignmentTray
          ? () => {
              if (!contributingScoreForOutcome.alignments) return
              if (
                alignmentIndex >= 0 &&
                alignmentIndex < contributingScoreForOutcome.alignments.length
              ) {
                onOpenStudentAssignmentTray(
                  outcome,
                  student,
                  alignmentIndex,
                  contributingScoreForOutcome.alignments,
                )
              }
            }
          : undefined
        return (
          <ContributingScoreCellContent
            alignment={alignment}
            outcome={outcome}
            student={student}
            scoreDisplayFormat={gradebookSettings.scoreDisplayFormat}
            score={rollup?.score}
            onAction={onAction}
            focus={focus}
          />
        )
      },
    [gradebookSettings.scoreDisplayFormat, onOpenStudentAssignmentTray],
  )

  const columns = useMemo(() => {
    const columns = []
    const commonColHeaderProps = {
      borderWidth: 'large 0 medium 0',
      background: 'secondary',
      height: CELL_HEIGHT,
    }

    columns.push({
      key: 'student',
      header: renderStudentHeader,
      render: renderStudentCell,
      isSticky: !isMobile,
      isRowHeader: true,
      colHeaderProps: {
        'data-testid': 'student-header',
        'aria-label': I18n.t('Students'),
        width: STUDENT_COLUMN_WIDTH + STUDENT_COLUMN_RIGHT_PADDING,

        ...commonColHeaderProps,
      },
      cellProps: {
        height: CELL_HEIGHT,
        padding: '0 0 0 small',
      },
    } as Column)

    {
      outcomes.map(outcome => {
        const contributingScoreForOutcome = contributingScores.forOutcome(outcome.id)
        columns.push({
          key: `outcome-${outcome.id}`,
          header: renderOutcomeHeader(outcome, contributingScoreForOutcome),
          render: renderOutcomeCell(outcome),
          draggable: true,
          dragLabel: outcome.title,
          data: {outcome},
          colHeaderProps: {
            'data-testid': `outcome-header-${outcome.id}`,
            'aria-label': I18n.t('Outcome, %{title}', {title: outcome.title}),
            width: COLUMN_WIDTH + COLUMN_PADDING,
            ...commonColHeaderProps,
          },
          cellProps: {
            height: CELL_HEIGHT,
          },
        } as Column)

        if (contributingScoreForOutcome.isVisible()) {
          ;(contributingScoreForOutcome.alignments || []).forEach(
            (alignment: ContributingScoreAlignment) => {
              columns.push({
                key: `contributing-score-${outcome.id}-${alignment.alignment_id}`,
                header: renderContributingScoreHeader(alignment),
                render: renderContributingScoreCell(
                  outcome,
                  alignment,
                  contributingScoreForOutcome,
                ),
                data: {outcome, alignment, contributingScoreForOutcome},
                cellProps: {
                  padding: '0',
                  overflowX: 'hidden',
                  overflowY: 'hidden',
                  height: CELL_HEIGHT,
                },
                colHeaderProps: {
                  'data-testid': `contributing-score-header-${outcome.id}-${alignment.alignment_id}`,
                  'aria-label': I18n.t('Assignment, %{name}', {
                    name: alignment.associated_asset_name,
                  }),
                  width: COLUMN_WIDTH + COLUMN_PADDING,
                  ...commonColHeaderProps,
                },
              } as Column)
            },
          )
        }
      })
    }

    return columns
  }, [
    outcomes,
    contributingScores,
    renderStudentHeader,
    renderStudentCell,
    renderOutcomeHeader,
    renderOutcomeCell,
    renderContributingScoreHeader,
    renderContributingScoreCell,
    isMobile,
  ])

  const renderAboveHeaderCallback = useCallback(
    (
      _columns: any,
      handleKeyDown: (event: React.KeyboardEvent, rowIndex: number, colIndex: number) => void,
    ) => {
      return (
        <BarChartRow
          columns={_columns}
          outcomeDistributions={outcomeDistributions}
          distributionStudents={distributionStudents}
          courseId={courseId}
          isLoading={isLoadingDistribution}
          handleKeyDown={handleKeyDown}
          isMobile={isMobile}
        />
      )
    },
    [outcomeDistributions, distributionStudents, courseId, isLoadingDistribution, isMobile],
  )

  const handleColumnMove = useCallback(
    (draggedId: string | number, hoverIndex: number) => {
      if (!handleOutcomeReorder) return
      const outcomeId = draggedId.toString().replace('outcome-', '')
      handleOutcomeReorder(outcomeId, hoverIndex)
    },
    [handleOutcomeReorder],
  )

  const dragDropConfig = useMemo(
    () =>
      handleOutcomeReorder
        ? {
            type: 'outcome-header',
            enabled: true,
            onMove: handleColumnMove,
            onDragEnd: handleOutcomeDragEnd,
            onDragLeave: handleOutcomeDragLeave,
          }
        : undefined,
    [handleOutcomeReorder, handleColumnMove, handleOutcomeDragEnd, handleOutcomeDragLeave],
  )

  return (
    <Table
      id="learning-mastery-gradebook-table"
      renderAboveHeader={renderAboveHeaderCallback}
      columns={columns}
      data={tableData}
      caption={I18n.t('Learning Mastery Gradebook')}
      dragDropConfig={dragDropConfig}
      margin="medium none none none"
    />
  )
}

export const GradebookTable = WithBreakpoints(
  GradebookTableComponent,
) as React.ComponentType<GradebookTableProps>
