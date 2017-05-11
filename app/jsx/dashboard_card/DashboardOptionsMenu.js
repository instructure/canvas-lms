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
import I18n from 'i18n!dashboard'
import axios from 'axios'

import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent'
import PopoverMenu from 'instructure-ui/lib/components/PopoverMenu'
import { MenuItem, MenuItemGroup, MenuItemSeparator } from 'instructure-ui/lib/components/Menu'
import Button from 'instructure-ui/lib/components/Button'
import IconSettings2Solid from 'instructure-icons/react/Solid/IconSettings2Solid'

export default class DashboardOptionsMenu extends React.Component {
  static propTypes = {
    recent_activity_dashboard: React.PropTypes.bool.isRequired,
    hide_dashcard_color_overlays: React.PropTypes.bool,
    planner_enabled: React.PropTypes.bool,
    planner_selected: React.PropTypes.bool
  }

  static defaultProps = {
    hide_dashcard_color_overlays: false,
    planner_enabled: false,
    planner_selected: false
  }

  constructor (props) {
    super(props)

    let view;
    if (props.planner_enabled && props.planner_selected) {
      view = ['planner']
    } else if (props.recent_activity_dashboard) {
      view = ['activity']
    } else {
      view = ['cards']
    }

    this.state = {
      view,
      colorOverlays: props.hide_dashcard_color_overlays ? [] : ['colorOverlays']
    }
  }

  handleViewOptionSelect = (e, newSelected) => {
    if (newSelected.length === 0) {
      return
    }
    this.setState({view: newSelected}, () => {
      this.toggleDashboardView(this.state.view)
      this.postDashboardToggle()
    })
  }

  handleColorOverlayOptionSelect = (e, newSelected) => {
    this.setState({
      colorOverlays: newSelected
    }, this.toggleColorOverlays)

    this.postToggleColorOverlays()
  }

  toggleDashboardView (newView) {
    const fakeObj = {
      style: {}
    }
    const dashboardPlanner = document.getElementById('dashboard-planner') || fakeObj
    const dashboardPlannerHeader = document.getElementById('dashboard-planner-header') || fakeObj
    const dashboardActivity = document.getElementById('dashboard-activity')
    const dashboardCards = document.getElementById('DashboardCard_Container')

    if (newView[0] === 'planner') {
      dashboardPlanner.style.display = 'block'
      dashboardPlannerHeader.style.display = 'block'
      dashboardActivity.style.display = 'none'
      dashboardCards.style.display = 'none'
    } else if (newView[0] === 'activity') {
      dashboardPlanner.style.display = 'none'
      dashboardPlannerHeader.style.display = 'none'
      dashboardActivity.style.display = 'block'
      dashboardCards.style.display = 'none'
    } else {
      dashboardPlanner.style.display = 'none'
      dashboardPlannerHeader.style.display = 'none'
      dashboardActivity.style.display = 'none'
      dashboardCards.style.display = 'block'
    }
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

  postDashboardToggle () {
    axios.put('/dashboard/view', {
      dashboard_view: this.state.view[0]
    })
  }

  postToggleColorOverlays () {
    axios.post('/users/toggle_hide_dashcard_color_overlays');
  }

  get cardView () {
    return this.state.view.includes('cards')
  }

  get colorOverlays () {
    return this.state.colorOverlays.includes('colorOverlays')
  }

  render () {
    const cardView = this.cardView

    return (
      <PopoverMenu
        trigger={
          <Button variant="icon">
            <ScreenReaderContent>{I18n.t('Dashboard Options')}</ScreenReaderContent>
            <IconSettings2Solid />
          </Button>
        }
        contentRef={(el) => { this.menuContentRef = el; }}
      >
        <MenuItemGroup
          label={I18n.t('Dashboard View')}
          onSelect={this.handleViewOptionSelect}
          selected={this.state.view}
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
