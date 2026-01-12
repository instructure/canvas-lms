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

import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Table} from '@instructure/ui-table'
import {LMGBScoreReporting} from './types'
import {useOutcomesChart} from './hooks/useOutcomesChart'

const I18n = createI18nScope('outcome_management')

/**
 * Mock function to generate sample scores data
 * In production, this would come from the API mapped to each outcome
 */
const getMockScores = (outcomeId: number | string): LMGBScoreReporting[] => {
  // Generate 4-11 mock scores with varying dates
  const scoreCount = Math.floor(Math.random() * 8) + 4
  const mockScores: LMGBScoreReporting[] = []
  const today = new Date()

  for (let i = 0; i < scoreCount; i++) {
    const daysAgo = (scoreCount - i) * 7 // Space out by ~1 week
    const date = new Date(today)
    date.setDate(date.getDate() - daysAgo)

    mockScores.push({
      score: Math.random() * 4, // Random score between 0-4
      title: `Assignment ${i + 1}`,
      submitted_at: date.toISOString(),
      count: 1,
      links: {
        outcome: String(outcomeId),
      },
    })
  }

  return mockScores
}

interface OutcomesTableRowExpansionProps {
  outcomeId: number | string
}

const OutcomesTableRowExpansion = ({outcomeId}: OutcomesTableRowExpansionProps) => {
  const scores = getMockScores(outcomeId)
  const {canvasRef, sortedScores} = useOutcomesChart(scores)

  if (scores.length === 0) {
    return (
      <View as="div" padding="medium" textAlign="center">
        <Text>{I18n.t('No assessment data available')}</Text>
      </View>
    )
  }

  return (
    <View as="div" padding="0 0 small small">
      <Flex direction="column" gap="small">
        <Flex.Item>
          <View
            as="div"
            height="16rem"
            width="calc(100% / 3)"
            position="relative"
            borderWidth="small"
            borderRadius="large"
            padding="0 0 0 medium"
          >
            <canvas
              ref={canvasRef}
              role="img"
              aria-label={I18n.t('Outcome scores over time chart')}
              aria-describedby="outcome-scores-table"
              data-testid="outcome-scores-chart"
            />
            {/* Accessible data table for screen readers */}
            <ScreenReaderContent>
              <Table caption={I18n.t('Outcome scores over time')} id="outcome-scores-table">
                <Table.Head>
                  <Table.Row>
                    <Table.ColHeader id="assignment">{I18n.t('Assignment')}</Table.ColHeader>
                    <Table.ColHeader id="date">{I18n.t('Date')}</Table.ColHeader>
                    <Table.ColHeader id="score">{I18n.t('Score')}</Table.ColHeader>
                  </Table.Row>
                </Table.Head>
                <Table.Body>
                  {sortedScores.map((score, index) => (
                    <Table.Row key={index}>
                      <Table.Cell>{score.title}</Table.Cell>
                      <Table.Cell>
                        {new Date(score.submitted_at).toLocaleDateString(I18n.currentLocale())}
                      </Table.Cell>
                      <Table.Cell>{score.score.toFixed(2)}</Table.Cell>
                    </Table.Row>
                  ))}
                </Table.Body>
              </Table>
            </ScreenReaderContent>
          </View>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default OutcomesTableRowExpansion
