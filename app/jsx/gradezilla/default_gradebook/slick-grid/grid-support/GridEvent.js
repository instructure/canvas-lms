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

export default class GridEvent {
  handlers = [];

  subscribe (handler) {
    if (!this.handlers.includes(handler)) {
      this.handlers.push(handler);
    }
  }

  unsubscribe (handler) {
    const index = this.handlers.indexOf(handler);
    if (index !== -1) {
      this.handlers.splice(index, 1);
    }
  }

  trigger (event, data) {
    for (let i = 0; i < this.handlers.length; i++) {
      if (this.handlers[i](event, data) === false) {
        return false; // prevent additional handlers from continuing
      }
    }

    return true; // continue handling
  }
}
