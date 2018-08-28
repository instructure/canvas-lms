/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import { combineReducers } from 'redux';
import { handleAction } from 'redux-actions';
import days from './days-reducer';
import loading from './loading-reducer';
import courses from './courses-reducer';
import groups from './groups-reducer';
import opportunities from './opportunities-reducer';
import todo from './todo-reducer';
import ui from './ui-reducer';
import savePlannerItem from './save-item-reducer';
import sidebar from './sidebar-reducer';

const locale = handleAction('INITIAL_OPTIONS', (state, action) => {
  return action.payload.env.MOMENT_LOCALE;
}, 'en');

const timeZone = handleAction('INITIAL_OPTIONS', (state, action) => {
  return action.payload.env.TIMEZONE;
}, 'UTC');

const currentUser = handleAction('INITIAL_OPTIONS', (state, action) => {
  const env = action.payload.env;
  const user = env.current_user;
  const userColor = env.PREFERENCES &&
    env.PREFERENCES.custom_colors &&
    env.PREFERENCES.custom_colors[`user_${user.id}`];
  return {
    id: user.id,
    displayName: user.display_name,
    avatarUrl: env.current_user.avatar_is_fallback ? null : env.current_user.avatar_image_url,
    color: userColor,
  };
}, {});

const firstNewActivityDate = handleAction('FOUND_FIRST_NEW_ACTIVITY_DATE', (state, action) => {
  return action.payload.clone();
}, null);

const combinedReducers = combineReducers({
  courses,
  groups,
  locale,
  timeZone,
  currentUser,
  days,
  loading,
  firstNewActivityDate,
  opportunities,
  todo,
  ui,
  sidebar,
});

export default function finalReducer (state, action) {
  const nextState = savePlannerItem(state, action);
  return combinedReducers(nextState, action);
}
