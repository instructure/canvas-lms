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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Outcome} from '@canvas/outcomes/react/types/rollup'
import {getTagIcon} from '@canvas/outcomes/react/utils/icons'
import {ScoreDisplayFormat} from '@instructure/outcomes-ui/lib/util/gradebook/constants'
import {findRating} from '@canvas/outcomes/react/utils/ratings'
import {ScoreCellContent} from '@instructure/outcomes-ui/es/components/Gradebook/gradebook-table/ScoreCellContent'
import type {ViewProps} from '@instructure/ui-view'

const I18n = createI18nScope('LearningMasteryGradebook')

export interface StudentOutcomeScoreProps {
  outcome: Outcome
  score?: number
  scoreDisplayFormat?: ScoreDisplayFormat
  background?: ViewProps['background']
  onAction?: () => void
  focus?: boolean
}

const StudentOutcomeScoreComponent: React.FC<StudentOutcomeScoreProps> = ({
  outcome,
  score,
  scoreDisplayFormat = ScoreDisplayFormat.ICON_ONLY,
  background,
  onAction,
  focus,
}) => {
  const rating = score !== undefined ? findRating(outcome.ratings, score) : undefined
  const masteryLevelResult = getTagIcon(rating?.points, outcome.mastery_points)
  const masteryLevel = typeof masteryLevelResult === 'string' ? masteryLevelResult : 'unassessed'

  return (
    <ScoreCellContent
      masteryLevel={masteryLevel}
      score={score ?? 0}
      scoreDisplayFormat={scoreDisplayFormat}
      label={rating?.description || I18n.t('Unassessed')}
      background={background}
      onAction={onAction}
      focus={focus}
    />
  )
}

export const StudentOutcomeScore = React.memo(StudentOutcomeScoreComponent)
