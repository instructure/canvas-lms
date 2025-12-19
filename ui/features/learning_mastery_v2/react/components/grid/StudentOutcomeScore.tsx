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
import SVGWrapper from '@canvas/svg-wrapper'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Outcome} from '@canvas/outcomes/react/types/rollup'
import {svgUrl} from '@canvas/outcomes/react/utils/icons'
import {ScoreDisplayFormat} from '@canvas/outcomes/react/utils/constants'
import {findRating} from '@canvas/outcomes/react/utils/ratings'
import {ScoreWithLabel} from './ScoreWithLabel'

const I18n = createI18nScope('learning_mastery_gradebook')

export interface StudentOutcomeScoreProps {
  outcome: Outcome
  score?: number
  scoreDisplayFormat?: ScoreDisplayFormat
}

const StudentOutcomeScoreComponent: React.FC<StudentOutcomeScoreProps> = ({
  outcome,
  score,
  scoreDisplayFormat = ScoreDisplayFormat.ICON_ONLY,
}) => {
  const rating = score !== undefined ? findRating(outcome.ratings, score) : undefined

  return (
    <ScoreWithLabel
      icon={
        <SVGWrapper
          fillColor={rating?.color}
          url={svgUrl(rating?.points, outcome.mastery_points)}
          style={{display: 'flex', alignItems: 'center', justifyItems: 'center', padding: '0px'}}
        />
      }
      score={score}
      scoreDisplayFormat={scoreDisplayFormat}
      label={rating?.description || I18n.t('Unassessed')}
    />
  )
}

export const StudentOutcomeScore = React.memo(StudentOutcomeScoreComponent)
