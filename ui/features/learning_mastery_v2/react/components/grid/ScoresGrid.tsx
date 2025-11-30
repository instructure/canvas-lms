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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {StudentOutcomeScore} from './StudentOutcomeScore'
import {Student, Outcome, StudentRollupData, OutcomeRollup} from '../../types/rollup'
import {COLUMN_WIDTH, COLUMN_PADDING, CELL_HEIGHT, ScoreDisplayFormat} from '../../utils/constants'
import {ContributingScoresManager} from '../../hooks/useContributingScores'

export interface ScoresGridProps {
  students: Student[]
  outcomes: Outcome[]
  rollups: StudentRollupData[]
  scoreDisplayFormat?: ScoreDisplayFormat
  contributingScores: ContributingScoresManager
}

interface ExtendedOutcomeRollup extends OutcomeRollup {
  studentId: string | number
}

interface ContributingScoreCellsProps {
  scoreDisplayFormat: ScoreDisplayFormat
  student: Student
  contributingScores: ContributingScoresManager
  outcome: Outcome
}

const ContributingScoreCells: React.FC<ContributingScoreCellsProps> = ({
  contributingScores,
  student,
  outcome,
  scoreDisplayFormat,
}) => {
  const contributingScoresForOutcome = contributingScores.forOutcome(outcome.id)
  const isVisible = contributingScoresForOutcome.isVisible()
  const scores = contributingScoresForOutcome.scoresForUser(student.id)
  return (
    <Fragment>
      {isVisible &&
        scores.map((score, scoreIndex) => (
          <Flex.Item
            size={`${COLUMN_WIDTH + COLUMN_PADDING}px`}
            data-testid={`contributing-score-${student.id}-${outcome.id}-${scoreIndex}`}
            key={`contributing-score-${student.id}-${outcome.id}-${scoreIndex}`}
          >
            <View
              as="div"
              height={CELL_HEIGHT}
              borderWidth="0 0 small 0"
              width={COLUMN_WIDTH}
              overflowX="auto"
              background="secondary"
            >
              <StudentOutcomeScore
                score={score}
                outcome={outcome}
                scoreDisplayFormat={scoreDisplayFormat}
              />
            </View>
          </Flex.Item>
        ))}
    </Fragment>
  )
}

export const ScoresGrid: React.FC<ScoresGridProps> = ({
  students,
  outcomes,
  rollups,
  scoreDisplayFormat = ScoreDisplayFormat.ICON_ONLY,
  contributingScores,
}) => {
  const rollupsByStudentAndOutcome = useMemo(() => {
    const outcomeRollups = rollups.flatMap(r =>
      r.outcomeRollups.map(or => ({
        studentId: r.studentId,
        ...or,
      })),
    ) as ExtendedOutcomeRollup[]

    return keyBy(outcomeRollups, ({studentId, outcomeId}) => `${studentId}_${outcomeId}`)
  }, [rollups])

  return (
    <Flex direction="column">
      {students.map(student => (
        <Flex direction="row" key={student.id}>
          {outcomes.map((outcome, index) => (
            <Fragment key={`${student.id}-${outcome.id}-${index}`}>
              <Flex.Item
                size={`${COLUMN_WIDTH + COLUMN_PADDING}px`}
                data-testid={`student-outcome-score-${student.id}-${outcome.id}`}
              >
                <View
                  as="div"
                  height={CELL_HEIGHT}
                  borderWidth="0 0 small 0"
                  width={COLUMN_WIDTH}
                  overflowX="auto"
                >
                  <StudentOutcomeScore
                    score={rollupsByStudentAndOutcome[`${student.id}_${outcome.id}`]?.score}
                    outcome={outcome}
                    scoreDisplayFormat={scoreDisplayFormat}
                  />
                </View>
              </Flex.Item>
              <ContributingScoreCells
                contributingScores={contributingScores}
                student={student}
                outcome={outcome}
                scoreDisplayFormat={scoreDisplayFormat}
              />
            </Fragment>
          ))}
        </Flex>
      ))}
    </Flex>
  )
}
