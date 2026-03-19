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

import React from 'react'
import {StudentOutcomeScore} from '../grid/StudentOutcomeScore'
import {View, ViewProps} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {ContributingScoreAlignment} from '@canvas/outcomes/react/hooks/useContributingScores'
import {Outcome, Student} from '@canvas/outcomes/react/types/rollup'
import {IconExpandStartLine} from '@instructure/ui-icons'
import {ScoreDisplayFormat} from '@canvas/outcomes/react/utils/constants'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('learning_mastery_gradebook')

export type ContributingScoreCellContentProps = Omit<ViewProps, 'children'> & {
  alignment: ContributingScoreAlignment
  outcome: Outcome
  student: Student
  scoreDisplayFormat: ScoreDisplayFormat
  score?: number
  onAction?: () => void
  focus?: boolean
}

export const ContributingScoreCellContent: React.FC<ContributingScoreCellContentProps> = ({
  alignment,
  outcome,
  student,
  scoreDisplayFormat,
  score,
  onAction,
  focus,
}: ContributingScoreCellContentProps) => {
  const buttonLabel = I18n.t('View Contributing Score Details for %{student} %{assignment}', {
    student: student.name,
    assignment: alignment.associated_asset_name,
  })

  return (
    <View
      as="div"
      background="secondary"
      height="100%"
      data-testid={`student-outcome-score-${student.id}-${outcome.id}-${alignment.alignment_id}`}
    >
      <Flex alignItems="center" width="100%" height="100%">
        <StudentOutcomeScore
          score={score}
          outcome={outcome}
          scoreDisplayFormat={scoreDisplayFormat}
        />
        <div
          style={{
            opacity: focus ? 1 : 0,
            pointerEvents: focus ? 'auto' : 'none',
          }}
        >
          <IconButton
            aria-haspopup="dialog"
            withBackground={false}
            withBorder={false}
            size="small"
            margin="xx-small small"
            renderIcon={<IconExpandStartLine />}
            screenReaderLabel={buttonLabel}
            onClick={onAction}
            disabled={!onAction}
          />
        </div>
      </Flex>
    </View>
  )
}
