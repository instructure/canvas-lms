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

import AsyncTracker from './AsyncTracker'
import ContextTracker from './ContextTracker'
import EventTracker from './EventTracker'
import SandboxFactory from './SandboxFactory'

const DEFAULT_SPEC_TIMEOUT = 5000

const UNPROTECTED_SPECS = Object.keys(process.env).includes('UNPROTECTED_SPECS')

export const contextTracker = new ContextTracker(QUnit)

export const sandboxFactory = new SandboxFactory({
  contextTracker,
  global: window,
  qunit: QUnit
})

export const asyncTracker = new AsyncTracker({
  contextTracker,

  /*
   * Add stack traces to logging to help identify sources of behavior.
   */
  debugging: false,

  /*
   * Log when async behavior has not resolved by the end of a spec.
   */
  logUnmanagedBehavior: false,

  /*
   * What to do when async behavior has not resolved by the end of a spec:
   * - 'none': nothing
   * - 'wait': allow the behavior to fully resolve before continuing specs
   * - 'hurry': resolve all behavior immediately and continue specs
   * - 'clear': cancel all unresolved behavior and continue specs
   * - 'fail': cancel all unresolved behavior and fail the current spec
   */
  unmanagedBehaviorStrategy: 'none'
})

export const eventTracker = new EventTracker({
  contextTracker,

  /*
   * Add stack traces to logging to help identify sources of behavior.
   */
  debugging: false,

  /*
   * Log when event listeners have been added but not removed within a spec.
   */
  logUnmanagedListeners: false,

  /*
   * What to do when event listeners have been added but not removed within a
   * spec.
   * - 'none': nothing
   * - 'remove': remove all remaining listeners and continue specs
   * - 'fail': remove all remaining listeners and fail the current spec
   */
  unmanagedListenerStrategy: 'none'
})

contextTracker.onContextStart(() => {
  // Set a standard timeout for all specs.
  // This can be overridden within specs.
  QUnit.config.testTimeout = DEFAULT_SPEC_TIMEOUT
})

if (!UNPROTECTED_SPECS) {
  contextTracker.setup()
}
