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
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {ScoreDisplayFormat} from '@canvas/outcomes/react/utils/constants'

export interface ScoreWithLabelProps {
  score?: number
  scoreDisplayFormat?: ScoreDisplayFormat
  icon?: React.ReactNode
  label?: string
}

interface LabelProps {
  scoreDisplayFormat: ScoreDisplayFormat
  score?: number
  text?: string
}

const Label: React.FC<LabelProps> = ({scoreDisplayFormat, score, text}) => {
  if (scoreDisplayFormat === ScoreDisplayFormat.ICON_AND_LABEL) {
    return <Text size="legend">{text}</Text>
  }

  if (scoreDisplayFormat === ScoreDisplayFormat.ICON_AND_POINTS) {
    return <Text size="legend">{score}</Text>
  }

  return <ScreenReaderContent>{text}</ScreenReaderContent>
}

export const ScoreWithLabel: React.FC<ScoreWithLabelProps> = ({
  icon,
  score,
  label,
  scoreDisplayFormat = ScoreDisplayFormat.ICON_ONLY,
}) => {
  const justifyItems = scoreDisplayFormat === ScoreDisplayFormat.ICON_ONLY ? 'center' : 'start'

  return (
    <Flex
      width="100%"
      height="100%"
      alignItems="center"
      gap="small"
      padding="none medium-small"
      justifyItems={justifyItems}
    >
      {icon}
      <Label scoreDisplayFormat={scoreDisplayFormat} score={score} text={label} />
    </Flex>
  )
}
