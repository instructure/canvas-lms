/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import I18n from 'i18n!dashboard'
import axios from 'axios'

import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import PopoverMenu from '@instructure/ui-core/lib/components/PopoverMenu'
import { MenuItem, MenuItemGroup, MenuItemSeparator } from '@instructure/ui-core/lib/components/Menu'
import Button from '@instructure/ui-core/lib/components/Button'
import IconMoreLine from 'instructure-icons/lib/Line/IconMoreLine'

export default class DashboardOptionsMenu extends React.Component {
  static propTypes = {
    view: PropTypes.string,
    hide_dashcard_color_overlays: PropTypes.bool,
    planner_enabled: PropTypes.bool,
    onDashboardChange: PropTypes.func.isRequired,
    menuButtonRef: PropTypes.func,
  }

  static defaultProps = {
    hide_dashcard_color_overlays: false,
    planner_enabled: false,
    view: 'cards',
    menuButtonRef: () => {},
  }

  constructor (props) {
    super(props)

    this.state = {
      colorOverlays: props.hide_dashcard_color_overlays ? [] : ['colorOverlays'],
    }
  }

  handleViewOptionSelect = (e, newSelected) => {
    if (newSelected.length === 0) {
      return
    }
    this.props.onDashboardChange(newSelected[0])
  }

  handleColorOverlayOptionSelect = (e, newSelected) => {
    this.setState({
      colorOverlays: newSelected
    }, this.toggleColorOverlays)

    this.postToggleColorOverlays()
  }

  toggleColorOverlays () {
    const dashcardHeaders = Array.from(document.getElementsByClassName('ic-DashboardCard__header'))
    dashcardHeaders.forEach((dashcardHeader) => {
      const dashcardImageHeader = dashcardHeader.getElementsByClassName('ic-DashboardCard__header_image')[0]
      if (dashcardImageHeader) {
        const dashcardOverlay = dashcardImageHeader.getElementsByClassName('ic-DashboardCard__header_hero')[0]
        dashcardOverlay.style.opacity = this.colorOverlays ? 0.6 : 0

        const headerButtonBg = dashcardHeader.getElementsByClassName('ic-DashboardCard__header-button-bg')[0]
        headerButtonBg.style.opacity = this.colorOverlays ? 0 : 1
      }
    })
  }

  postToggleColorOverlays () {
    axios.post('/users/toggle_hide_dashcard_color_overlays');
  }

  get cardView () {
    return this.props.view === 'cards'
  }

  get colorOverlays () {
    return this.state.colorOverlays.includes('colorOverlays')
  }

  render () {
    const { cardView } = this

    return (
      <PopoverMenu
        trigger={
          <Button variant="icon" buttonRef={this.props.menuButtonRef}>
            <ScreenReaderContent>{I18n.t('Dashboard Options')}</ScreenReaderContent>
            <IconMoreLine />
          </Button>
        }
        contentRef={(el) => { this.menuContentRef = el; }}
      >
        <MenuItemGroup
          label={I18n.t('Dashboard View')}
          onSelect={this.handleViewOptionSelect}
          selected={[this.props.view]}
        >
          <MenuItem value="cards">{I18n.t('Card View')}</MenuItem>
          {
            (this.props.planner_enabled) && (
              <MenuItem value="planner">{I18n.t('List View')}</MenuItem>
            )
          }
          <MenuItem value="activity">{I18n.t('Recent Activity')}</MenuItem>
        </MenuItemGroup>
        { cardView && <MenuItemSeparator /> }
        { cardView && (
          <MenuItemGroup
            label={
              <ScreenReaderContent>
                {I18n.t('Toggle course card color overlays')}
              </ScreenReaderContent>
            }
            onSelect={this.handleColorOverlayOptionSelect}
            selected={this.state.colorOverlays}
          >
            <MenuItem value="colorOverlays">
              { I18n.t('Color Overlay') }
            </MenuItem>
          </MenuItemGroup>
        )}
      </PopoverMenu>
    )
  }
}
