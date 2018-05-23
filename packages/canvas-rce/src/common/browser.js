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

let isIE = false;
let isEdge = false;

// expected to be called as setFromTinymce(window.tinymce) at some point where
// window.tinymce is available
export function setFromTinymce(tinymce) {
  set(tinymce.Env);
}

export function reset() {
  set({ ie: false, edge: false });
}

export function set(env) {
  isIE = !!env.ie;
  isEdge = isIE && !!(env.edge || env.ie == 12);
}

export function ie() {
  return isIE;
}

export function edge() {
  return isEdge;
}
