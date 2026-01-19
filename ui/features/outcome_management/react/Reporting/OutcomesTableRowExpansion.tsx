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
import {useMemo, useEffect} from 'react'
import type {ContributingScoresManager} from '@canvas/outcomes/react/hooks/useContributingScores'
import {Spinner} from '@instructure/ui-spinner'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('outcome_management')

interface OutcomesTableRowExpansionProps {
  outcomeId: number | string
  studentId: string
  contributingScores: ContributingScoresManager
}

const OutcomesTableRowExpansion = ({
  outcomeId,
  studentId,
  contributingScores,
}: OutcomesTableRowExpansionProps) => {
  const outcomeScores = contributingScores.forOutcome(outcomeId)

  useEffect(() => {
    if (!outcomeScores.isVisible()) {
      outcomeScores.toggleVisibility()
    }
  }, [outcomeId, outcomeScores])

  // Transform contributing scores data to match the expected LMGBScoreReporting format
  const scores: LMGBScoreReporting[] = useMemo(() => {
    if (!outcomeScores.data) return []

    const userScores = outcomeScores.scoresForUser(studentId)
    const alignments = outcomeScores.alignments || []

    const transformedScores: LMGBScoreReporting[] = []

    userScores.forEach((score, index) => {
      if (!score) return
      const alignment = alignments[index]
      if (!alignment) return

      transformedScores.push({
        score: score.score,
        title: alignment.associated_asset_name,
        type: alignment.associated_asset_type,
        submitted_at: score.submitted_or_assessed_at || new Date().toISOString(),
        links: {
          outcome: outcomeId,
        },
      })
    })

    return transformedScores
  }, [outcomeScores, studentId, outcomeId])

  const {canvasRef, sortedScores} = useOutcomesChart(scores)

  useEffect(() => {
    if (outcomeScores.error) {
      showFlashError(I18n.t('Failed to load contributing scores'))()
    }
  }, [outcomeScores.error])

  if (outcomeScores.isLoading) {
    return (
      <View data-testid="outcome-reporting" display="block" textAlign="center">
        <Spinner renderTitle={I18n.t('Loading contributing scores')} size="large" />
      </View>
    )
  }

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
