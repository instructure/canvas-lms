/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import $ from 'jquery'
import serviceRCELoader from './serviceRCELoader'

function loadServiceSidebar(callback) {
  serviceRCELoader.loadSidebarOnTarget($('#editor_tabs').get(0), callback)
}

const Sidebar = {
  /**
   * variables to track singleton state and initialization status
   *
   * @private
   */
  instance: undefined,
  pendingShow: false,
  initializing: false,
  subscriptions: {},

  /**
   * initialize the sidebar. safe to call multiple times; if the sidebar is
   * already initialized or currently initializing, it won't be started
   * again. can also pass callbacks to execute any time the sidebar is shown
   * (`show`) or hidden (`hide`).
   *
   * @public
   */
  init(subscriptions = {}) {
    if (!this.instance && !this.initializing) {
      this.initializing = true
      const callback = sidebar => {
        this.initializing = false
        this.instance = sidebar
        if (this.pendingShow) {
          this.show()
        }
      }
      loadServiceSidebar(callback)
    }
    this.subscriptions = subscriptions
  },

  /**
   * show the sidebar, if initialized. no-op if the sidebar is not
   * initialized or even if it's currently initializing. if shown, triggers
   * any callbacks registered for `show` on init.
   *
   * @public
   */
  show() {
    if (this.instance) {
      this.instance.show()
      if (this.subscriptions.show) {
        this.subscriptions.show()
      }
    } else {
      this.pendingShow = true
    }
  },

  /**
   * hide the sidebar, if initialized. no-op if the sidebar is not
   * initialized or even if it's currently initializing. if hidden, triggers
   * any callbacks registered for `hide` on init.
   *
   * @public
   */
  hide() {
    if (this.instance) {
      this.instance.hide()
      if (this.subscriptions.hide) {
        this.subscriptions.hide()
      }
    } else {
      this.pendingShow = false
    }
  },

  /**
   * reset, for specs
   *
   * @private
   */
  reset() {
    this.instance = undefined
    this.initializing = false
    this.subscriptions = {}
  },
}

export default Sidebar
