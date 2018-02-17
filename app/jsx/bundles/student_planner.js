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
import Planner from 'canvas-planner';
import $ from 'jquery';
import 'compiled/jquery.rails_flash_notifications';
import {sharedDashboardInstance} from '../dashboardPlannerHelper';

const stickyElement = document.getElementById('dashboard_header_container');
const element = document.getElementById('dashboard-planner');
const headerElement = document.getElementById('dashboard-planner-header');

const courses = window.ENV.STUDENT_PLANNER_COURSES.map(dc => ({
  ...dc,
  color: window.ENV.PREFERENCES.custom_colors[dc.assetString]
}));

const groups = window.ENV.STUDENT_PLANNER_GROUPS ?
  window.ENV.STUDENT_PLANNER_GROUPS.map(dg => ({
    ...dg,
    color: window.ENV.PREFERENCES.custom_colors[dg.assetString] || '#666666'
  })) : [];

const stickyElementRect = stickyElement.getBoundingClientRect()
const stickyOffset = stickyElementRect.bottom - stickyElementRect.top

const changeToDashboardCardView = () => {
  sharedDashboardInstance.changeToCardView();
}

const options = {
  flashAlertFunctions: {
    visualErrorCallback: $.flashError,
    visualSuccessCallback: $.flashMessage,
    srAlertCallback: $.screenReaderFlashMessage
  },
  locale: window.ENV.LOCALE,
  timeZone: window.ENV.TIMEZONE,
  userId: window.ENV.current_user_id,
  ariaHideElement: document.getElementById('application'),
  theme: '',
  // the new activity button isn't sticky in IE yet, so make sure it slides
  // under the header that is sticky in IE
  stickyZIndex: 3,
  stickyOffset,
  courses,
  groups,
  changeToDashboardCardView
};

if (element) {
  Planner.render(element, options);
}

if (headerElement) {
  Planner.renderHeader(headerElement, options);
}
