/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

// https://github.com/instructure/instructure-ui/blob/v7.18.0/packages/ui-dom-utils/src/addPositionChangeListener.js
// This file creates a recursive listener that is never ending, causing jest.runAllTimers() to run infinitely long.
jest.mock('@instructure/ui-dom-utils/lib/addPositionChangeListener', () => ({
  addPositionChangeListener: () => ({remove: () => {}}),
}))

// https://github.com/instructure/instructure-ui/blob/v7.18.0/packages/ui-dom-utils/src/addResizeListener.js
// This file creates a recursive listener that is never ending, causing jest.runAllTimers() to run infinitely long.
jest.mock('@instructure/ui-dom-utils/lib/addResizeListener', () => ({
  addResizeListener: () => ({remove: () => {}}),
}))

// https://github.com/jsdom/jsdom/issues/3234
// JSDOM getComputedStyle() is painfully slow and our tests don't really need it.
// If you ever need it in the future, use jest.unmock() in the file that needs it
// or be prepared to fix the build speed regression in another way.
jest.mock('@instructure/ui-dom-utils/lib/getComputedStyle', () => ({
  getComputedStyle: () => ({getPropertyValue: () => void 0}),
}))
