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
import ReactDOM from 'react-dom';
import { Provider } from 'react-redux';
import ToDoSidebar from '../dashboard/ToDoSidebar';
import configureStore from '../dashboard/ToDoSidebar/store';

const store = configureStore({});

/**
* This handles rendering this properly.  Because the sidebar itself is loaded
* via a Rails render without layout, it can't render out the script tag for this
* bundle.  So we load this bundle at the main application, but we need to wait for
* the sidebar to render.  This makes it so we check every 500ms for the proper
* container to be there, once it is there, we stop.
*/
const interval = window.setInterval(() => {
  const container = document.querySelector('.Sidebar__TodoListContainer')
  if (container) {
    ReactDOM.render(
      <Provider store={store}>
        <ToDoSidebar courses={window.ENV.STUDENT_PLANNER_COURSES} timeZone={window.ENV.TIMEZONE} />
      </Provider>
      , document.querySelector('.Sidebar__TodoListContainer'));
    window.clearInterval(interval);
  }
}, 500);
