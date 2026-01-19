/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {
  BAR_CHART_HEIGHT,
  COLUMN_PADDING,
  COLUMN_WIDTH,
  STUDENT_COLUMN_RIGHT_PADDING,
  STUDENT_COLUMN_WIDTH,
} from '@canvas/outcomes/react/utils/constants'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import React, {Fragment} from 'react'
import {MasteryDistributionChart} from '../charts'
import {
  ContributingScoreAlignment,
  ContributingScoresManager,
} from '@canvas/outcomes/react/hooks/useContributingScores'
import {Outcome, Student, StudentRollupData} from '@canvas/outcomes/react/types/rollup'
import {colors} from '@instructure/canvas-theme'
import {getScoresForOutcome, getScoresForAlignment} from '../../utils/scoreUtils'

export interface BarChartRowProps {
  barChartRowRef: React.MutableRefObject<HTMLElement | null>
  outcomes: Outcome[]
  rollups: StudentRollupData[]
  students: Student[]
  contributingScores: ContributingScoresManager
}

export const BarChartRow: React.FC<BarChartRowProps> = ({
  outcomes,
  rollups,
  students,
  contributingScores,
  barChartRowRef,
}) => {
  return (
    <Flex>
      <Flex.Item
        as="div"
        size={`${STUDENT_COLUMN_WIDTH + STUDENT_COLUMN_RIGHT_PADDING}px`}
        height={`${BAR_CHART_HEIGHT}px`}
      />
      <View
        padding="medium none none none"
        as="div"
        display="flex"
        overflowX="hidden"
        overflowY="hidden"
        elementRef={el => {
          if (el instanceof HTMLElement) {
            barChartRowRef.current = el
          }
        }}
      >
        {outcomes.map(outcome => {
          const contributingScoreForOutcome = contributingScores.forOutcome(outcome.id)
          return (
            <Fragment key={outcome.id}>
              <div
                key={`outcomes-chart-${outcome.id}`}
                style={{
                  width: `${COLUMN_WIDTH + COLUMN_PADDING}px`,
                  boxShadow: `-2px 0 0 0 ${colors.contrasts.grey1214} inset`,
                }}
              >
                <MasteryDistributionChart
                  outcome={outcome}
                  scores={getScoresForOutcome(rollups, outcome.id)}
                  height={BAR_CHART_HEIGHT}
                  width={COLUMN_WIDTH + COLUMN_PADDING}
                  isPreview={true}
                />
              </div>
              {contributingScoreForOutcome.isVisible() &&
                (contributingScoreForOutcome.alignments || []).map(
                  (alignment: ContributingScoreAlignment) => (
                    <div
                      key={`alignment-chart-${alignment.alignment_id}`}
                      style={{
                        width: `${COLUMN_WIDTH + COLUMN_PADDING}px`,
                        boxShadow: `-2px 0 0 0 ${colors.contrasts.grey1214} inset`,
                      }}
                    >
                      <MasteryDistributionChart
                        outcome={outcome}
                        scores={getScoresForAlignment(
                          contributingScores,
                          students,
                          outcome.id,
                          alignment.alignment_id,
                        )}
                        height={BAR_CHART_HEIGHT}
                        width={COLUMN_WIDTH + COLUMN_PADDING}
                        isPreview={true}
                      />
                    </div>
                  ),
                )}
            </Fragment>
          )
        })}
      </View>
    </Flex>
  )
}
