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
import React, {useMemo, Fragment} from 'react'
import {keyBy} from 'es-toolkit/compat'
import {Flex} from '@instructure/ui-flex'
import {StudentOutcomeScore} from './StudentOutcomeScore'
import {Student, Outcome, StudentRollupData, OutcomeRollup} from '../../types/rollup'
import {ScoreDisplayFormat} from '../../utils/constants'
import {
  ContributingScoreAlignment,
  ContributingScoresManager,
} from '../../hooks/useContributingScores'
import {CellWithAction} from './CellWithAction'
import {FocusableCell} from './FocusableCell'

export interface ScoresGridProps {
  students: Student[]
  outcomes: Outcome[]
  rollups: StudentRollupData[]
  scoreDisplayFormat?: ScoreDisplayFormat
  contributingScores: ContributingScoresManager
  onOpenStudentAssignmentTray?: (
    outcome: Outcome,
    student: Student,
    alignmentIndex: number,
    alignments: ContributingScoreAlignment[],
  ) => void
}

interface ExtendedOutcomeRollup extends OutcomeRollup {
  studentId: string | number
}

interface ContributingScoreCellsProps {
  scoreDisplayFormat: ScoreDisplayFormat
  student: Student
  contributingScores: ContributingScoresManager
  outcome: Outcome
  onScoreClick?: (
    outcome: Outcome,
    student: Student,
    alignmentIndex: number,
    alignments: ContributingScoreAlignment[],
  ) => void
}

const ContributingScoreCells: React.FC<ContributingScoreCellsProps> = ({
  contributingScores,
  student,
  outcome,
  scoreDisplayFormat,
  onScoreClick,
}) => {
  const contributingScoresForOutcome = contributingScores.forOutcome(outcome.id)
  const isVisible = contributingScoresForOutcome.isVisible()
  const scores = contributingScoresForOutcome.scoresForUser(student.id)
  return (
    <Fragment>
      {isVisible &&
        scores.map((score, alignmentIndex) => (
          <CellWithAction
            data-testid={`contributing-score-${student.id}-${outcome.id}-${alignmentIndex}`}
            key={`contributing-score-${student.id}-${outcome.id}-${alignmentIndex}`}
            background="secondary"
            actionLabel="View Contributing Score Details"
            onAction={
              onScoreClick
                ? () => {
                    if (!contributingScoresForOutcome.alignments) return
                    if (
                      alignmentIndex >= 0 &&
                      alignmentIndex < contributingScoresForOutcome.alignments.length
                    ) {
                      onScoreClick(
                        outcome,
                        student,
                        alignmentIndex,
                        contributingScoresForOutcome.alignments,
                      )
                    }
                  }
                : undefined
            }
          >
            <StudentOutcomeScore
              score={score?.score}
              outcome={outcome}
              scoreDisplayFormat={scoreDisplayFormat}
            />
          </CellWithAction>
        ))}
    </Fragment>
  )
}

const ScoresGridComponent: React.FC<ScoresGridProps> = ({
  students,
  outcomes,
  rollups,
  scoreDisplayFormat = ScoreDisplayFormat.ICON_ONLY,
  contributingScores,
  onOpenStudentAssignmentTray,
}) => {
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

  return (
    <Flex direction="column" role="grid">
      {students.map(student => (
        <Flex direction="row" key={student.id} role="row">
          {outcomes.map((outcome, index) => (
            <Fragment key={`${student.id}-${outcome.id}-${index}`}>
              <FocusableCell data-testid={`student-outcome-score-${student.id}-${outcome.id}`}>
                <StudentOutcomeScore
                  score={rollupsByStudentAndOutcome[`${student.id}_${outcome.id}`]?.score}
                  outcome={outcome}
                  scoreDisplayFormat={scoreDisplayFormat}
                />
              </FocusableCell>
              <ContributingScoreCells
                contributingScores={contributingScores}
                student={student}
                outcome={outcome}
                scoreDisplayFormat={scoreDisplayFormat}
                onScoreClick={onOpenStudentAssignmentTray}
              />
            </Fragment>
          ))}
        </Flex>
      ))}
    </Flex>
  )
}

export const ScoresGrid = React.memo(ScoresGridComponent)
