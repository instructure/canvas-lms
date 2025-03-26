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

const I18n = createI18nScope('rubrics-assessment-tray')

type SelfAssessmentRatingButtonProps = {
  buttonDisplay: string
  isPreviewMode: boolean
  isSelected: boolean
  onClick: () => void
}
export const SelfAssessmentRatingButton = ({
  buttonDisplay,
  isPreviewMode,
  isSelected,
  onClick,
}: SelfAssessmentRatingButtonProps) => {
  const selectedText = isSelected ? I18n.t('Selected') : ''

  return (
    <View
      data-testid={isSelected ? 'rubric-self-assessment-rating-button-selected' : ''}
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
          data-testid={`rubric-self-assessment-rating-button-${buttonDisplay}`}
          cursor={isPreviewMode ? 'not-allowed' : 'pointer'}
        >
          <div
            style={
              isSelected
                ? {
                    height: '30px',
                    width: '30px',
                    backgroundColor: '#F3F9F6',
                    color: colors.contrasts.green4570,
                    border: '2px dashed #03893D',
                    borderRadius: '4px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }
                : {
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: 'black',
                  }
            }
          >
            <Text size="medium">{buttonDisplay}</Text>
          </div>
        </IconButton>
      </View>
    </View>
  )
}
