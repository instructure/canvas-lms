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
import {ContributingScoresManager} from '../../hooks/useContributingScores'
import {Cell} from './Cell'

export interface ScoresGridProps {
  students: Student[]
  outcomes: Outcome[]
  rollups: StudentRollupData[]
  scoreDisplayFormat?: ScoreDisplayFormat
  contributingScores: ContributingScoresManager
  onOpenStudentAssignmentTray?: (outcome: Outcome) => void
}

interface ExtendedOutcomeRollup extends OutcomeRollup {
  studentId: string | number
}

interface ContributingScoreCellsProps {
  scoreDisplayFormat: ScoreDisplayFormat
  student: Student
  contributingScores: ContributingScoresManager
  outcome: Outcome
  onScoreClick?: () => void
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
        scores.map((score, scoreIndex) => (
          <Cell
            background="secondary"
            data-testid={`contributing-score-${student.id}-${outcome.id}-${scoreIndex}`}
            key={`contributing-score-${student.id}-${outcome.id}-${scoreIndex}`}
          >
            <StudentOutcomeScore
              score={score}
              outcome={outcome}
              scoreDisplayFormat={scoreDisplayFormat}
              onScoreClick={onScoreClick}
            />
          </Cell>
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
    <Flex direction="column">
      {students.map(student => (
        <Flex direction="row" key={student.id}>
          {outcomes.map((outcome, index) => (
            <Fragment key={`${student.id}-${outcome.id}-${index}`}>
              <Cell data-testid={`student-outcome-score-${student.id}-${outcome.id}`}>
                <StudentOutcomeScore
                  score={rollupsByStudentAndOutcome[`${student.id}_${outcome.id}`]?.score}
                  outcome={outcome}
                  scoreDisplayFormat={scoreDisplayFormat}
                />
              </Cell>
              <ContributingScoreCells
                contributingScores={contributingScores}
                student={student}
                outcome={outcome}
                scoreDisplayFormat={scoreDisplayFormat}
                onScoreClick={
                  onOpenStudentAssignmentTray
                    ? () => onOpenStudentAssignmentTray(outcome)
                    : undefined
                }
              />
            </Fragment>
          ))}
        </Flex>
      ))}
    </Flex>
  )
}

export const ScoresGrid = React.memo(ScoresGridComponent)
