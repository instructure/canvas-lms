/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {colors} from '@instructure/canvas-theme'
import {View} from '@instructure/ui-view'
import {IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {rubricSelectedAriaLabel} from './utils/rubricUtils'

const I18n = createI18nScope('rubrics-assessment-tray')

type RatingButtonProps = {
  buttonDisplay: string
  isPreviewMode: boolean
  isSelected: boolean
  isSelfAssessmentSelected: boolean
  selectedArrowDirection: 'up' | 'right'
  onClick: () => void
}
export const RatingButton = ({
  buttonDisplay,
  isPreviewMode,
  isSelected,
  isSelfAssessmentSelected,
  selectedArrowDirection,
  onClick,
}: RatingButtonProps) => {
  const unselectedColor = isPreviewMode ? colors.contrasts.grey1214 : colors.contrasts.green4570
  const selectedText = rubricSelectedAriaLabel(isSelected, isSelfAssessmentSelected)

  return (
    <View
      as="div"
      width="3.625rem"
      height="3.625rem"
      display="block"
      padding="0 0 0 xx-small"
      themeOverride={{paddingXxSmall: '0.313rem'}}
    >
      <View as="div" position="relative">
        <IconButton
          screenReaderLabel={I18n.t('Rating Button %{buttonDisplay} %{selectedText}', {
            buttonDisplay,
            selectedText,
          })}
          size="large"
          color="primary-inverse"
          onClick={onClick}
          readOnly={isPreviewMode}
          data-testid={`rubric-rating-button-${buttonDisplay}`}
          cursor={isPreviewMode ? 'not-allowed' : 'pointer'}
          themeOverride={{
            largeFontSize: '1rem',
            borderWidth: isSelected ? '3px' : '1px',
            primaryInverseBorderColor: isSelected
              ? colors.contrasts.green4570
              : 'rgb(219, 219, 219)',
            primaryInverseColor: isSelected ? colors.contrasts.green4570 : unselectedColor,
          }}
        >
          <Text size="medium">{buttonDisplay}</Text>
          {isSelfAssessmentSelected && <SelectedSelfAssessment buttonDisplay={buttonDisplay} />}
        </IconButton>
        {isSelected && <SelectedRatingArrow direction={selectedArrowDirection} />}
      </View>
    </View>
  )
}

type SelectedRatingArrowProps = {
  direction: 'up' | 'right'
}
const SelectedRatingArrow = ({direction}: SelectedRatingArrowProps) => {
  const outerTriangleStyle: React.CSSProperties = {
    position: 'absolute',
    width: '0',
    height: '0',
  }

  const innerTriangleSmallStyle: React.CSSProperties = {
    position: 'absolute',
    width: '0',
    height: '0',
  }

  if (direction === 'right') {
    outerTriangleStyle.top = '50%'
    outerTriangleStyle.right = '0px'
    outerTriangleStyle.borderTop = '6px solid transparent'
    outerTriangleStyle.borderBottom = '6px solid transparent'
    outerTriangleStyle.borderLeft = `6px solid ${colors.contrasts.green4570}`
    outerTriangleStyle.transform = 'translateY(-50%)'
    innerTriangleSmallStyle.top = '50%'
    innerTriangleSmallStyle.right = '4px'
    innerTriangleSmallStyle.borderTop = '4px solid transparent'
    innerTriangleSmallStyle.borderBottom = '4px solid transparent'
    innerTriangleSmallStyle.borderLeft = '4px solid white'
    innerTriangleSmallStyle.transform = 'translateY(-50%)'
  } else if (direction === 'up') {
    outerTriangleStyle.left = '46%'
    outerTriangleStyle.top = '-5px'
    outerTriangleStyle.borderLeft = '6px solid transparent'
    outerTriangleStyle.borderRight = '6px solid transparent'
    outerTriangleStyle.borderBottom = `6px solid ${colors.contrasts.green4570}`
    outerTriangleStyle.transform = 'translateX(-50%)'
    innerTriangleSmallStyle.left = '46%'
    innerTriangleSmallStyle.top = '-1px'
    innerTriangleSmallStyle.borderLeft = '4px solid transparent'
    innerTriangleSmallStyle.borderRight = '4px solid transparent'
    innerTriangleSmallStyle.borderBottom = '4px solid white'
    innerTriangleSmallStyle.transform = 'translateX(-50%)'
  }

  return (
    <>
      <div style={outerTriangleStyle} data-testid="rubric-rating-button-selected" />
      <div style={innerTriangleSmallStyle} />
    </>
  )
}

const SelectedSelfAssessment = ({buttonDisplay}: {buttonDisplay: string}) => {
  return (
    <div
      data-testid={`rubric-rating-button-self-assessment-selected-${buttonDisplay}`}
      style={{
        position: 'absolute',
        inset: '6px',
        backgroundColor: 'transparent',
        border: `2px dashed ${colors.contrasts.green4570}`,
        borderRadius: '4px',
        pointerEvents: 'none',
      }}
    />
  )
}
