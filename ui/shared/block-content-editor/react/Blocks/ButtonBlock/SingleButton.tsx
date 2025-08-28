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

import {Button} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {SingleButtonProps} from './types'
import {alpha} from '@instructure/ui-color-utils'
import {BaseButtonTheme} from '@instructure/shared-types'
import {getAdjustedColor} from './getAdjustedColor'

const I18n = createI18nScope('block_content_editor')

export const SingleButton = ({
  button,
  isFullWidth,
  onButtonClick,
  focusHandler,
}: SingleButtonProps) => {
  const buttonText = button.text.trim() || I18n.t('Button')

  const url = button.url.trim()
  const shouldUseLink = !onButtonClick && url
  const isNewTabLink = button.linkOpenMode === 'new-tab'
  const href = shouldUseLink ? url : undefined

  const boxShadow = 'inset 0 0 0.1875rem 0.0625rem'

  const adjustedPrimaryColor = getAdjustedColor(button.primaryColor)
  const adjustedBoxShadow = `${boxShadow} ${alpha(adjustedPrimaryColor, 28)}`

  const themeOverride = (): Partial<BaseButtonTheme> => {
    return {
      secondaryActiveBackground: adjustedPrimaryColor,
      secondaryActiveBoxShadow: adjustedBoxShadow,
      secondaryBackground: button.primaryColor,
      secondaryBorderColor: button.primaryColor,
      secondaryColor: button.secondaryColor,
      secondaryHoverBackground: adjustedPrimaryColor,
      secondaryGhostColor: adjustedPrimaryColor,
      secondaryGhostBorderColor: adjustedPrimaryColor,
      secondaryGhostHoverBackground: `${alpha(adjustedPrimaryColor, 10)}`,
      secondaryGhostActiveBoxShadow: adjustedBoxShadow,
    }
  }

  const buttonActionProps = onButtonClick
    ? {onClick: onButtonClick as () => void}
    : {
        href,
        target: isNewTabLink ? '_blank' : undefined,
        rel: isNewTabLink ? 'noopener noreferrer' : undefined,
      }

  return (
    <Button
      elementRef={el => focusHandler?.(el as HTMLElement)}
      display={isFullWidth ? 'block' : 'inline-block'}
      withBackground={button.style == 'filled'}
      themeOverride={themeOverride}
      {...buttonActionProps}
      data-singlebutton
    >
      {buttonText}
    </Button>
  )
}
