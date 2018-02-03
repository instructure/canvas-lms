/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React from 'react';
import I18n from 'i18n!dashboard'
import DashboardOptionsMenu from '../dashboard_card/DashboardOptionsMenu';
import { bool } from 'prop-types';

/**
 * This component renders the header for the user dashboard.
 */
class DashboardHeader extends React.Component {

  constructor (props) {
    super(props);

    let currentDashboard;

    if (props.show_planner) {
      currentDashboard = 'planner';
    } else if (props.show_recent_activity) {
      currentDashboard = 'activity';
    } else {
      currentDashboard = 'cards';
    }

    this.state = { currentDashboard };
  }

  render () {
    return (
      <div className="ic-Dashboard-header__layout">
        <h1 className="ic-Dashboard-header__title">{I18n.t('Dashboard')}</h1>
        <div className="ic-Dashboard-header__actions">
          {this.props.planner_enabled && (
            <div
              id="dashboard-planner-header"
              className="CanvasPlanner__HeaderContainer"
              style={{ display: (this.props.planner_selected) ? 'block' : 'none' }}
            />
          )}
          <div id="DashboardOptionsMenu_Container">
            <DashboardOptionsMenu
              recent_activity_dashboard={this.props.recent_activity_dashboard}
              hide_dashcard_color_overlays={this.props.hide_dashcard_color_overlays}
              planner_enabled={this.props.planner_enabled}
              planner_selected={this.props.planner_selected}
              onDashboardChange={(newDashboard) => {
                this.setState({ currentDashboard: newDashboard }, function afterDashboardChange () {
                  if (this.state.currentDashboard === 'planner') {
                    document.body.classList.add('dashboard-is-planner');
                  } else if (document.body.classList.contains('dashboard-is-planner')) {
                    document.body.classList.remove('dashboard-is-planner');
                  }
                });
              }}
            />
          </div>
        </div>
      </div>
    );
  }
}

DashboardHeader.propTypes = {
  recent_activity_dashboard: bool,
  hide_dashcard_color_overlays: bool,
  planner_enabled: bool.isRequired,
  planner_selected: bool.isRequired
}

DashboardHeader.defaultProps = {
  recent_activity_dashboard: false,
  hide_dashcard_color_overlays: false
}

export default DashboardHeader;
