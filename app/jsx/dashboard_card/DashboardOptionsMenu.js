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

import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import Menu, {
  MenuItem,
  MenuItemGroup,
  MenuItemSeparator
} from '@instructure/ui-menu/lib/components/Menu'
import Button from '@instructure/ui-buttons/lib/components/Button'
import IconMoreLine from '@instructure/ui-icons/lib/Line/IconMore'

export default class DashboardOptionsMenu extends React.Component {
  static propTypes = {
    view: PropTypes.string,
    planner_enabled: PropTypes.bool,
    onDashboardChange: PropTypes.func.isRequired,
    menuButtonRef: PropTypes.func
  }

  static defaultProps = {
    planner_enabled: false,
    view: 'cards',
    menuButtonRef: () => {}
  }

  state = {
    showColorOverlays: !(ENV && ENV.PREFERENCES && ENV.PREFERENCES.hide_dashcard_color_overlays)
  }

  handleViewOptionSelect = (e, [newlySelectedView]) => {
    if (this.props.view === newlySelectedView) return
    this.props.onDashboardChange(newlySelectedView)
  }

  handleColorOverlayOptionSelect = showColorOverlays => {
    if (showColorOverlays === this.state.showColorOverlays) return

    this.setState({showColorOverlays}, () => {
      this.toggleColorOverlays()
      this.postToggleColorOverlays()
    })
  }

  toggleColorOverlays() {
    document.querySelectorAll('.ic-DashboardCard__header').forEach(dashcardHeader => {
      const dashcardImageHeader = dashcardHeader.querySelector('.ic-DashboardCard__header_image')
      if (dashcardImageHeader) {
        const dashcardOverlay = dashcardImageHeader.querySelector('.ic-DashboardCard__header_hero')
        dashcardOverlay.style.opacity = this.state.showColorOverlays ? 0.6 : 0

        const headerButtonBg = dashcardHeader.querySelector('.ic-DashboardCard__header-button-bg')
        headerButtonBg.style.opacity = this.state.showColorOverlays ? 0 : 1
      }
    })
  }

  postToggleColorOverlays() {
    axios.post('/users/toggle_hide_dashcard_color_overlays')
  }

  render() {
    const cardView = this.props.view === 'cards'

    return (
      <Menu
        trigger={
          <Button variant="icon" icon={IconMoreLine} buttonRef={this.props.menuButtonRef}>
            <ScreenReaderContent>{I18n.t('Dashboard Options')}</ScreenReaderContent>
          </Button>
        }
        contentRef={el => (this.menuContentRef = el)}
      >
        <MenuItemGroup
          label={I18n.t('Dashboard View')}
          onSelect={this.handleViewOptionSelect}
          selected={[this.props.view]}
        >
          <MenuItem value="cards">{I18n.t('Card View')}</MenuItem>
          {this.props.planner_enabled && <MenuItem value="planner">{I18n.t('List View')}</MenuItem>}
          <MenuItem value="activity">{I18n.t('Recent Activity')}</MenuItem>
        </MenuItemGroup>
        {cardView && <MenuItemSeparator />}
        {cardView && (
          <MenuItemGroup
            label={
              <ScreenReaderContent>
                {I18n.t('Toggle course card color overlays')}
              </ScreenReaderContent>
            }
          >
            <MenuItem
              onSelect={(_e, _, isSelected) => this.handleColorOverlayOptionSelect(isSelected)}
              selected={this.state.showColorOverlays}
            >
              {I18n.t('Color Overlay')}
            </MenuItem>
          </MenuItemGroup>
        )}
      </Menu>
    )
  }
}
