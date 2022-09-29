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

export const stubbable = {
  getValue() {
    return 'real'
  },

  getOtherValue() {
    return 'really real'
  },
}

export function waitForNextExample(callback) {
  const startTime = new Date().valueOf()
  const currentExample = QUnit.config.current

  const maybeCallback = () => {
    setTimeout(() => {
      const nowTime = new Date().valueOf()

      /*
       * When the next example has started, call the callback. In the event that
       * AsyncTracker unmanagedBehaviorStrategy is 'wait', the example will not
       * change until this callback is fired. Ensure it does after no longer
       * than 1000ms.
       */
      if (QUnit.config.current !== currentExample || nowTime - startTime > 1000) {
        callback()
      } else {
        maybeCallback()
      }
    }, 0)
  }

  maybeCallback()
}
