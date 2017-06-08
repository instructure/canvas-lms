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
import DashboardOptionsMenu from 'jsx/dashboard_card/DashboardOptionsMenu';
import { bool } from 'prop-types';

/**
 * This component renders the header for the user dashboard.
 */
const DashboardHeader = props => (
  <div className="grid-row bottom-xs">
    <div className="col-xs-9">
      <h1 className="ic-Dashboard-header_title">{I18n.t('Dashboard')}</h1>
    </div>
    <div className="col-xs-3 end-xs ic-Dashboard-content--align-right">
      {props.planner_enabled && (
        <div
          id="dashboard-planner-header"
          className="CanvasPlanner__HeaderContainer"
          style={{ display: (props.planner_selected) ? 'block' : 'none' }}
        />
      )}
      <div id="DashboardOptionsMenu_Container">
        <DashboardOptionsMenu
          recent_activity_dashboard={props.recent_activity_dashboard}
          hide_dashcard_color_overlays={props.hide_dashcard_color_overlays}
          planner_enabled={props.planner_enabled}
          planner_selected={props.planner_selected}
        />
      </div>
    </div>
  </div>
);

DashboardHeader.propTypes = {
  recent_activity_dashboard: bool.isRequired,
  hide_dashcard_color_overlays: bool.isRequired,
  planner_enabled: bool.isRequired,
  planner_selected: bool.isRequired
}

export default DashboardHeader;
