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
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {withStyle, type WithStyleProps} from '@instructure/emotion'
import type {Theme} from '@instructure/ui-themes'
import './grouped-select.css'

type GroupedSelectEntryOwnProps = {
  variant: 'item' | 'group'
  title: string
  active: boolean
  onClick: () => void
  onFocus: () => void
  tabIndex: number
  forwardedRef: React.Ref<HTMLDivElement>
}

type GroupedSelectEntryStyleProps = {
  primaryColor: string
}

type GroupedSelectEntryProps = GroupedSelectEntryOwnProps &
  WithStyleProps<GroupedSelectEntryStyleProps, GroupedSelectEntryStyleProps>

class ThemedGroupedSelectEntry extends React.Component<GroupedSelectEntryProps> {
  isItem = this.props.variant === 'item'
  className = this.isItem ? 'grouped-select-item' : 'grouped-select-group'

  componentDidMount(): void {
    this.props.makeStyles!()
  }

  handleElementRef = (element: Element | null) => {
    if (typeof this.props.forwardedRef === 'function') {
      this.props.forwardedRef(element as HTMLDivElement | null)
    } else if (this.props.forwardedRef && 'current' in this.props.forwardedRef) {
      ;(this.props.forwardedRef as React.MutableRefObject<HTMLDivElement | null>).current =
        element as HTMLDivElement | null
    }
  }

  render() {
    const {primaryColor} = this.props.styles!
    const {active, onClick, onFocus, title, variant, tabIndex} = this.props
    const isGroupSelected = variant === 'group' && active

    return (
      <View
        as="button"
        type="button"
        background="transparent"
        textAlign="start"
        width="100%"
        borderColor="transparent"
        borderRadius="medium"
        borderWidth={isGroupSelected ? 'none none none large' : 'none'}
        elementRef={this.handleElementRef}
        aria-selected={active}
        className={`${this.className} ${active ? 'selected' : ''}`}
        onClick={onClick}
        onFocus={onFocus}
        tabIndex={tabIndex}
        themeOverride={
          isGroupSelected
            ? {
                borderColorTransparent: primaryColor,
              }
            : undefined
        }
      >
        <Text weight={isGroupSelected ? 'weightImportant' : 'weightRegular'}>{title}</Text>
      </View>
    )
  }
}

const generateStyles = (componentTheme: GroupedSelectEntryStyleProps) =>
  ({
    ...componentTheme,
  }) as GroupedSelectEntryStyleProps

const generateComponentTheme = (theme: Theme): GroupedSelectEntryStyleProps => ({
  primaryColor: theme['ic-brand-primary']!,
})

const StyledGroupedSelectEntry = withStyle(
  generateStyles,
  generateComponentTheme,
)(ThemedGroupedSelectEntry)

export const GroupedSelectEntry = React.forwardRef<
  HTMLDivElement,
  Omit<GroupedSelectEntryOwnProps, 'forwardedRef'>
>((props, ref) => <StyledGroupedSelectEntry {...props} forwardedRef={ref} />)
