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
import {useScope as createI18nScope} from '@canvas/i18n'
import axios from '@canvas/axios'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Menu} from '@instructure/ui-menu'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconMoreLine, IconArrowOpenDownLine} from '@instructure/ui-icons'

const I18n = createI18nScope('dashboard')

export default class DashboardOptionsMenu extends React.Component {
  static propTypes = {
    view: PropTypes.string,
    planner_enabled: PropTypes.bool,
    onDashboardChange: PropTypes.func.isRequired,
    menuButtonRef: PropTypes.func,
    canEnableElementaryDashboard: PropTypes.bool,
    responsiveSize: PropTypes.string,
  }

  static defaultProps = {
    planner_enabled: false,
    view: 'cards',
    menuButtonRef: () => {},
    canEnableElementaryDashboard: false,
  }

  state = {
    showColorOverlays: !(ENV && ENV.PREFERENCES && ENV.PREFERENCES.hide_dashcard_color_overlays),
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
          this.props.responsiveSize == 'small' ? (
            <Button
              elementRef={this.props.menuButtonRef}
              screenReaderLabel={I18n.t('Dashboard Options')}
              display="block"
              data-testid="dashboard-options-button"
            >
              More <IconArrowOpenDownLine size="x-small" />
            </Button>
          ) : (
            <IconButton
              renderIcon={IconMoreLine}
              withBackground={ENV.FEATURES?.instui_header}
              withBorder={ENV.FEATURES?.instui_header}
              elementRef={this.props.menuButtonRef}
              screenReaderLabel={I18n.t('Dashboard Options')}
              data-testid="dashboard-options-button"
            />
          )
        }
        contentRef={el => (this.menuContentRef = el)}
      >
        <Menu.Group
          label={I18n.t('Dashboard View')}
          onSelect={this.handleViewOptionSelect}
          selected={[this.props.view]}
          data-testid="dashboard-view-group"
        >
          <Menu.Item value="cards" data-testid="card-view-menu-item">
            {I18n.t('Card View')}
          </Menu.Item>
          {this.props.planner_enabled && (
            <Menu.Item value="planner" data-testid="list-view-menu-item">
              {I18n.t('List View')}
            </Menu.Item>
          )}
          <Menu.Item value="activity" data-testid="recent-activity-menu-item">
            {I18n.t('Recent Activity')}
          </Menu.Item>
          {this.props.canEnableElementaryDashboard && (
            <Menu.Item value="elementary" data-testid="homeroom-view-menu-item">
              {I18n.t('Homeroom View')}
            </Menu.Item>
          )}
        </Menu.Group>
        {cardView && <Menu.Separator />}
        {cardView && (
          <Menu.Group
            label={
              <ScreenReaderContent>
                {I18n.t('Toggle course card color overlays')}
              </ScreenReaderContent>
            }
            data-testid="color-overlay-group"
          >
            <Menu.Item
              onSelect={(_e, _, isSelected) => this.handleColorOverlayOptionSelect(isSelected)}
              selected={this.state.showColorOverlays}
              data-testid="color-overlay-menu-item"
            >
              {I18n.t('Color Overlay')}
            </Menu.Item>
          </Menu.Group>
        )}
      </Menu>
    )
  }
}
