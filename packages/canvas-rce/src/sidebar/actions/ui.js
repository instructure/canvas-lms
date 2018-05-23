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

export const CHANGE_TAB = "CHANGE_TAB";
export const CHANGE_ACCORDION = "CHANGE_ACCORDION";
export const RESET_UI = "RESET_UI";
export const HIDE_SIDEBAR = "HIDE_SIDEBAR";
export const SHOW_SIDEBAR = "SHOW_SIDEBAR";

export function changeTab(index) {
  return { type: CHANGE_TAB, index };
}

export function changeAccordion(index) {
  return { type: CHANGE_ACCORDION, index };
}

export function resetUI() {
  return { type: RESET_UI };
}

export function hideSidebar() {
  return { type: HIDE_SIDEBAR };
}

export function showSidebar() {
  return { type: SHOW_SIDEBAR };
}
