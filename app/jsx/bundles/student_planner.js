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

const element = document.getElementById('dashboard-planner');
const headerElement = document.getElementById('dashboard-planner-header');

const courses = window.ENV.DASHBOARD_COURSES.map(dc => ({
  ...dc,
  color: window.ENV.PREFERENCES.custom_colors[dc.assetString]
}));


const options = {
  locale: window.ENV.LOCALE,
  timeZone: window.ENV.TIMEZONE,
  theme: (ENV.use_high_contrast) ? 'canvas-a11y' : 'canvas',
  courses
};

if (element) {
  Planner.render(element, options);
}

if (headerElement) {
  Planner.renderHeader(headerElement, options);
}
