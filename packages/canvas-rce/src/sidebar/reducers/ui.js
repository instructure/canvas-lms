/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {
  CHANGE_TAB,
  CHANGE_ACCORDION,
  RESET_UI,
  HIDE_SIDEBAR,
  SHOW_SIDEBAR
} from "../actions/ui";
import { combineReducers } from "redux";

function hidden(state = false, action) {
  switch (action.type) {
    case HIDE_SIDEBAR:
      return true;

    case RESET_UI:
    case SHOW_SIDEBAR:
      return false;

    default:
      return state;
  }
}

function selectedTabIndex(state = 0, action) {
  switch (action.type) {
    case RESET_UI:
      return 0;

    case CHANGE_TAB:
      return action.index;

    default:
      return state;
  }
}

function selectedAccordionIndex(state = 0, action) {
  switch (action.type) {
    case RESET_UI:
      return 0;

    case CHANGE_TAB:
      // switch links panel accordion tab back to first tab any time we
      // switch _back to_ links panel
      return 0;

    case CHANGE_ACCORDION:
      return action.index;

    default:
      return state;
  }
}

export default combineReducers({
  hidden,
  selectedTabIndex,
  selectedAccordionIndex
});
