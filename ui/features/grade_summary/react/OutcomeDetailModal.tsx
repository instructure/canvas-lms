/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {raw} from '@instructure/html-escape'
import {ProgressBar} from '@instructure/ui-progress'
import numberFormat from '@canvas/i18n/numberFormat'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useQuery} from '@tanstack/react-query'
import {Spinner} from '@instructure/ui-spinner'
import {Fragment} from 'react/jsx-runtime'
import {ComponentProps} from 'react'
import {Alert} from '@instructure/ui-alerts'

const I18n = createI18nScope('outcome_detail')

interface OutcomeResult {
  id: string
  percent: number
  possible: number
  score: number
  links: {
    alignment: string
  }
  submitted_or_assessed_at: string
}

interface Alignment {
  name: string
  id: string
}

interface OutcomeResultsResponse {
  outcome_results: Array<OutcomeResult>
  linked: {
    alignments: Array<Alignment>
  }
}

const fetchOutcomeResults = async ({
  courseId,
  userId,
  outcomeId,
}: {
  courseId: string
  userId: string
  outcomeId: string
}) => {
  try {
    const data = await doFetchApi<OutcomeResultsResponse>({
      path: `/api/v1/courses/${courseId}/outcome_results`,
      params: {
        user_ids: [userId],
        outcome_ids: [outcomeId],
        include: ['alignments'],
        per_page: 100,
      },
    })

    data.json?.outcome_results.sort((a, b) => {
      const dateA = new Date(a.submitted_or_assessed_at).getTime()
      const dateB = new Date(b.submitted_or_assessed_at).getTime()
      return dateB - dateA
    })

    return data.json
  } catch (error) {
    console.error('Error fetching outcome results:', error)

    throw error
  }
}

export interface OutcomeDetailModalProps {
  outcome: {
    id: string
    friendly_name: string
    score?: number
    description?: string
    mastery_points?: number
    points_possible: number
    percent?: number
  }
  courseId: string
  courseName: string
  userId: string
  onClose: () => void
}

function OutcomeDetailModal({
  outcome,
  courseId,
  courseName,
  userId,
  onClose,
}: OutcomeDetailModalProps) {
  const {data, isLoading, isError} = useQuery({
    queryKey: ['outcomeResults', outcome.id, courseId, userId],
    queryFn: () => fetchOutcomeResults({courseId, userId, outcomeId: outcome.id}),
  })
  const outcomeResults = data?.outcome_results || []
  const alignments = data?.linked?.alignments || []
  const alignmentIdNameMap = alignments.reduce(
    (acc, alignment) => {
      acc[alignment.id] = alignment.name
      return acc
    },
    {} as Record<string, string>,
  )
  const closeText = I18n.t('Close')

  const renderOutcomeResults = () => {
    if (isLoading) {
      return (
        <Flex justifyItems="center">
          <Spinner renderTitle={I18n.t('Loading alignments')} />
        </Flex>
      )
    } else if (isError) {
      return <Alert variant="error">{I18n.t('Failed to load alignments')}</Alert>
    } else if (outcomeResults.length) {
      return (
        <Flex direction="column">
          <hr style={{margin: '0'}} />
          {outcomeResults.map(({id, percent, possible, score, links}) => (
            <Fragment key={id}>
              <Flex padding="x-small 0" justifyItems="space-between">
                <Text weight="bold">{alignmentIdNameMap[links?.alignment]}</Text>
                <OutcomeProgressBar
                  mastery_points={outcome.mastery_points}
                  points_possible={possible}
                  percent={percent}
                  score={score}
                />
              </Flex>
              <hr style={{margin: '0'}} />
            </Fragment>
          ))}
        </Flex>
      )
    } else {
      return <Text>{I18n.t('No items.')}</Text>
    }
  }

  return (
    <Modal
      open={true}
      onDismiss={onClose}
      size="medium"
      label={courseName}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={closeText}
        />
        <Heading>{courseName}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Flex direction="column" gap="small">
          <Flex direction="column">
            <Flex justifyItems="space-between">
              <Text weight="bold">{outcome.friendly_name}</Text>
              <OutcomeProgressBar
                mastery_points={outcome.mastery_points}
                points_possible={outcome.points_possible}
                score={outcome.score}
              />
            </Flex>
            <Flex direction="column">
              {outcome.description && (
                <span dangerouslySetInnerHTML={{__html: raw(outcome.description)}} />
              )}
            </Flex>
          </Flex>
          {renderOutcomeResults()}
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Button color="secondary" onClick={onClose}>
          {closeText}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

type OutcomeProgressBarProps = Pick<
  OutcomeDetailModalProps['outcome'],
  'score' | 'mastery_points' | 'points_possible' | 'percent'
>

function OutcomeProgressBar({
  mastery_points,
  points_possible,
  score,
  percent,
}: OutcomeProgressBarProps) {
  const parsedScore = score != null && !isNaN(score) ? numberFormat.outcomeScore(score) : null
  const parsedMasteryPoints =
    mastery_points != null && !isNaN(mastery_points)
      ? numberFormat.outcomeScore(mastery_points)
      : null

  const calculatePercentage = () => {
    if (!score || !parsedScore) {
      return 0
    }

    if (percent) {
      return percent * 100
    } else {
      return (score / points_possible) * 100
    }
  }

  const determineMeterColor = (): ComponentProps<typeof ProgressBar>['meterColor'] => {
    if (!score || !parsedScore || !mastery_points) {
      return 'info'
    }

    if (score >= mastery_points) {
      return 'success'
    } else if (score >= mastery_points / 2) {
      return 'info'
    } else {
      return 'warning'
    }
  }

  return (
    <Flex gap="small">
      <Flex gap="small">
        <Text color="secondary">
          <Text weight="bold" color="primary">
            {parsedScore ? parsedScore : '-'}
          </Text>
          {' / '}
          <Text>{parsedMasteryPoints ? parsedMasteryPoints : '-'}</Text>
        </Text>
      </Flex>
      <View background="primary-inverse" as="div">
        <ProgressBar
          size="small"
          width={300}
          screenReaderLabel={I18n.t('Outcome progress')}
          color="primary-inverse"
          meterColor={determineMeterColor()}
          valueNow={calculatePercentage()}
        />
      </View>
    </Flex>
  )
}

export default OutcomeDetailModal
