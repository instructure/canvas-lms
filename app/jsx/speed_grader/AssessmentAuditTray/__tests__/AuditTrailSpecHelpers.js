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

/* eslint-disable import/prefer-default-export */
export function buildEvent(attr = {}) {
  return {
    assignmentId: '2301',
    canvadocId: null,
    eventType: 'unknown',
    id: '4901',
    payload: {},
    submissionId: null,
    userId: '1101',
    ...attr,
    createdAt: attr.createdAt ? new Date(attr.createdAt) : new Date()
  }
}
