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

import React, {Component} from 'react'
import {IconAddSolid} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import type {Theme} from '@instructure/ui-themes'
import {withStyle, WithStyleProps} from '@instructure/emotion'
import {useScope as createI18nScope} from '@canvas/i18n'
import {FocusHandler} from '../../../hooks/useFocusElement'
import {getContrastingColors, type ContrastingColors} from '../../../utilities/getContrastingColors'

const I18n = createI18nScope('block_content_editor')

type AddButtonOwnProps = {
  onClick: () => void
  focusHandler?: FocusHandler | false
}

type AddButtonStyleProps = ContrastingColors

type AddButtonProps = AddButtonOwnProps & WithStyleProps<AddButtonStyleProps, AddButtonStyleProps>

class ThemedAddButton extends Component<AddButtonProps> {
  componentDidMount() {
    this.props.makeStyles!()
  }

  handleKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      this.props.onClick()
    }
  }

  render() {
    const {foreground, background} = this.props.styles!

    return (
      <View
        as="button"
        type="button"
        background="primary"
        borderWidth="small"
        borderColor="primary"
        aria-label={I18n.t('Select to initiate file upload')}
        elementRef={element => this.props.focusHandler && this.props.focusHandler(element)}
        onKeyDown={this.handleKeyDown}
        onClick={this.props.onClick}
        themeOverride={{
          backgroundPrimary: background,
          borderColorPrimary: foreground,
        }}
        className="image-block-add-button"
      >
        <IconAddSolid size="medium" style={{color: `${foreground}`}} />
      </View>
    )
  }
}

const generateStyles = (componentTheme: AddButtonStyleProps) =>
  ({
    ...componentTheme,
  }) as AddButtonStyleProps

const generateComponentTheme = (theme: Theme): AddButtonStyleProps => {
  const brandColor = theme['ic-brand-primary']!
  const {foreground, background} = getContrastingColors(brandColor)

  return {
    foreground,
    background,
  }
}

export const AddButton = withStyle(
  generateStyles,
  generateComponentTheme,
)(ThemedAddButton) as React.ComponentType<AddButtonProps>
