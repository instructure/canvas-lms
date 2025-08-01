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

import SVGWrapper from '@canvas/svg-wrapper'
import {Flex} from '@instructure/ui-flex'
import React, {Component} from 'react'
import {withStyle, WithStyleProps} from '@instructure/emotion'
import type {Theme} from '@instructure/ui-themes'
import {Text} from '@instructure/ui-text'

type BarIconStyleProps = {
  selectedColor: string
  secondaryColor: string
}

type BarIconOwnProps = {
  svgPath: React.ReactNode
  title: string
  selected: boolean
}

export type BarIconProps = BarIconOwnProps & WithStyleProps<BarIconStyleProps, BarIconStyleProps>

class BarIcon extends Component<BarIconProps> {
  componentDidMount() {
    this.props.makeStyles!()
  }

  render() {
    const {selectedColor, secondaryColor} = this.props.styles!
    return (
      <Flex direction="column" alignItems="center" gap="xxx-small">
        <SVGWrapper
          fillColor={this.props.selected ? selectedColor : secondaryColor}
          url={this.props.svgPath}
        />
        <Text color={this.props.selected ? 'brand' : 'primary'}>{this.props.title}</Text>
      </Flex>
    )
  }
}

const generateStyles = (componentTheme: BarIconStyleProps) =>
  ({
    ...componentTheme,
  }) as BarIconStyleProps

const generateComponentTheme = (theme: Theme) =>
  ({
    selectedColor: theme['ic-brand-primary']!,
    secondaryColor: theme['ic-brand-font-color-dark']!,
  }) as BarIconStyleProps

export const BlockContentPreviewSelectorBarIcon = withStyle(
  generateStyles,
  generateComponentTheme,
)(BarIcon) as React.ComponentType<BarIconProps>
