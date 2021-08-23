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

import formatMessage from '../format-message'

let externalConversion

export function initializeContent(options) {
  externalConversion = options.convertApiUserContent
}

export function convertApiUserContent(content) {
  // allow tests to work without initialization
  if (process.env.NODE_ENV === 'test') {
    return content
  }
  return externalConversion(content)
}

export function assignmentType(itemType) {
  switch (itemType) {
    case 'Quiz':
      return formatMessage('Quiz')
    case 'Discussion':
      return formatMessage('Discussion')
    case 'Assignment':
      return formatMessage('Assignment')
    case 'Page':
      return formatMessage('Page')
    case 'Announcement':
      return formatMessage('Announcement')
    case 'To Do':
      return formatMessage('To Do')
    case 'Calendar Event':
      return formatMessage('Calendar Event')
    case 'Peer Review':
      return formatMessage('Peer Review')
    default:
      return formatMessage('Task')
  }
}
