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

import React, {useMemo, useEffect} from 'react'
import {Flex, FlexItem} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {Outcome, StudentRollupData} from '@canvas/outcomes/react/types/rollup'
import {ScoreDisplayFormat} from '@canvas/outcomes/react/utils/constants'
import {useOutcomeAlignments} from '../../../hooks/useOutcomeAlignments'
import {StudentOutcomeScore} from '../../grid/StudentOutcomeScore'

const I18n = createI18nScope('LearningMasteryGradebook')

export interface OutcomeResultSectionProps {
  courseId: string
  studentId: string
  assignmentId: string
  rollups: StudentRollupData[]
  outcomes: Outcome[]
}

export const OutcomeResultSection: React.FC<OutcomeResultSectionProps> = ({
  courseId,
  studentId,
  assignmentId,
  rollups,
  outcomes,
}) => {
  const {
    data: alignments,
    isLoading,
    error,
  } = useOutcomeAlignments({
    courseId,
    studentId,
    assignmentId,
  })

  const studentRollup = useMemo(
    () => rollups.find(r => r.studentId === studentId),
    [rollups, studentId],
  )

  const outcomeScoresMap = useMemo(() => {
    if (!studentRollup) return new Map()
    return new Map(
      studentRollup.outcomeRollups.map(outcomeRollup => [
        String(outcomeRollup.outcomeId),
        outcomeRollup,
      ]),
    )
  }, [studentRollup])

  const alignedOutcomes = useMemo(() => {
    if (!alignments || alignments.length === 0) return []

    const alignedOutcomeIds = new Set(
      alignments.map(a => String(a.learning_outcome_id)).filter(Boolean),
    )

    return outcomes.filter(outcome => alignedOutcomeIds.has(String(outcome.id)))
  }, [alignments, outcomes])

  useEffect(() => {
    if (error) {
      showFlashAlert({
        type: 'error',
        message: I18n.t('Failed to load outcome alignments'),
      })
    }
  }, [error])

  if (error) {
    return null
  }

  if (isLoading) {
    return (
      <View as="div" padding="medium" textAlign="center">
        <Spinner size="small" renderTitle={I18n.t('Loading outcome alignments')} />
      </View>
    )
  }

  return (
    <View as="div">
      <Flex direction="column" gap="small">
        <FlexItem>
          <Text weight="bold">{I18n.t('Aligned Outcomes')}</Text>
        </FlexItem>
        <FlexItem>
          <Flex direction="column" gap="small">
            {alignedOutcomes.map(outcome => {
              const outcomeScore = outcomeScoresMap.get(String(outcome.id))
              return (
                <FlexItem key={`${studentId}-${assignmentId}-${outcome.id}`}>
                  <Flex direction="row" alignItems="center" justifyItems="space-between">
                    <FlexItem shouldShrink={true}>
                      <Flex direction="column">
                        <FlexItem>
                          <TruncateText>
                            <Text weight="bold">{outcome.title}</Text>
                          </TruncateText>
                        </FlexItem>
                        <FlexItem>
                          <TruncateText>
                            <Text size="small">{outcome.display_name}</Text>
                          </TruncateText>
                        </FlexItem>
                      </Flex>
                    </FlexItem>
                    <Flex direction="row">
                      <FlexItem size="2rem">
                        <StudentOutcomeScore
                          outcome={outcome}
                          score={outcomeScore ? outcomeScore.score : undefined}
                          scoreDisplayFormat={ScoreDisplayFormat.ICON_ONLY}
                        />
                      </FlexItem>
                      <FlexItem width="2rem">
                        <Text>{outcomeScore ? outcomeScore.score.toFixed(1) : ''}</Text>
                      </FlexItem>
                    </Flex>
                  </Flex>
                </FlexItem>
              )
            })}
          </Flex>
        </FlexItem>
      </Flex>
    </View>
  )
}
