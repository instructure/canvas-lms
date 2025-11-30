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
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import SVGWrapper from '@canvas/svg-wrapper'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Outcome, Rating} from '../../types/rollup'
import {svgUrl} from '../../utils/icons'
import {ScoreDisplayFormat} from '../../utils/constants'
import {findRating} from '../../utils/ratings'

const I18n = createI18nScope('learning_mastery_gradebook')

export interface StudentOutcomeScoreProps {
  outcome: Outcome
  score?: number
  scoreDisplayFormat?: ScoreDisplayFormat
}

interface RenderLabelProps {
  scoreDisplayFormat: ScoreDisplayFormat
  score?: number
  rating?: Rating
}

const StudentOutcomeScoreLabel: React.FC<RenderLabelProps> = ({
  scoreDisplayFormat,
  score,
  rating,
}) => {
  if (scoreDisplayFormat === ScoreDisplayFormat.ICON_AND_LABEL) {
    return <Text size="legend">{rating?.description || I18n.t('Unassessed')}</Text>
  }

  if (scoreDisplayFormat === ScoreDisplayFormat.ICON_AND_POINTS) {
    return <Text size="legend">{score}</Text>
  }

  return <ScreenReaderContent>{rating?.description || I18n.t('Unassessed')}</ScreenReaderContent>
}

export const StudentOutcomeScore: React.FC<StudentOutcomeScoreProps> = ({
  outcome,
  score,
  scoreDisplayFormat = ScoreDisplayFormat.ICON_ONLY,
}) => {
  const justifyItems = scoreDisplayFormat === ScoreDisplayFormat.ICON_ONLY ? 'center' : 'start'

  // Find the appropriate rating based on the score
  const rating = score !== undefined ? findRating(outcome.ratings, score) : undefined

  return (
    <Flex
      width="100%"
      height="100%"
      alignItems="center"
      justifyItems={justifyItems}
      gap="small"
      padding="none medium-small"
    >
      <SVGWrapper
        fillColor={rating?.color}
        url={svgUrl(rating?.points, outcome.mastery_points)}
        style={{display: 'flex', alignItems: 'center', justifyItems: 'center', padding: '0px'}}
      />
      <StudentOutcomeScoreLabel
        scoreDisplayFormat={scoreDisplayFormat}
        score={score}
        rating={rating}
      />
    </Flex>
  )
}
