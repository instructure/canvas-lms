/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

export const SEARCH_DEBOUNCE_DELAY = 300
// We allow 5000ms for the screen reader to finish reading the label of the focused element before
// announcing the screen reader alert. Otherwise, the focus announcement steals the alert announcement.
export const SCREENREADER_ALERT_TIMEOUT = 5000
export const SEARCH_RESULT_ANNOUNCEMENT_DELAY = 1000
export const CARD_HEIGHT = 120
