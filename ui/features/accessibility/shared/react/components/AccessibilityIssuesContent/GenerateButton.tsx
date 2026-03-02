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
import React, {useState} from 'react'
import {Button} from '@instructure/ui-buttons'
import {IconAiSolid} from '@instructure/ui-icons'

export type ButtonState = 'initial' | 'loading' | 'loaded'
export type ButtonLabelByState = Record<ButtonState, string>

const StableWidthLabel = ({labels, state}: {labels: ButtonLabelByState; state: ButtonState}) => {
  const longestLabel = Object.values(labels).reduce((a, b) => (a.length >= b.length ? a : b))
  const currentLabel = labels[state]

  return (
    <span style={{display: 'inline-grid'}}>
      {longestLabel !== currentLabel && (
        <span
          style={{gridArea: '1/1', visibility: 'hidden', userSelect: 'none', pointerEvents: 'none'}}
          aria-hidden
        >
          {longestLabel}
        </span>
      )}
      <span data-testid={`${state}-label`} style={{gridArea: '1/1', textAlign: 'center'}}>
        {currentLabel}
      </span>
    </span>
  )
}

export interface GenerateButtonProps {
  handleGenerateClick: () => void
  isLoading: boolean
  buttonLabels: ButtonLabelByState
  isDisabled?: boolean
}

export const GenerateButton: React.FC<GenerateButtonProps> = ({
  handleGenerateClick,
  isLoading,
  buttonLabels,
  isDisabled,
}: GenerateButtonProps) => {
  const [hasGenerated, setHasGenerated] = useState(false)
  const buttonState: ButtonState = isLoading ? 'loading' : hasGenerated ? 'loaded' : 'initial'

  const handleOnClick = () => {
    if (isLoading) return
    handleGenerateClick()
    setHasGenerated(true)
  }

  return (
    <Button
      color="ai-primary"
      renderIcon={() => <IconAiSolid />}
      onClick={handleOnClick}
      interaction={isDisabled ? 'disabled' : 'enabled'}
      aria-disabled={isLoading || isDisabled}
      aria-busy={isLoading}
      data-testid="generate-button"
    >
      <StableWidthLabel labels={buttonLabels} state={buttonState} />
    </Button>
  )
}
