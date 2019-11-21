/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {whitelist} from './messageTypes'

// page-global storage for data relevant to LTI postMessage events
const ltiState = {}
export {ltiState}

const handleLtiPostMessage = async e => {
  const {messageType, data} = e.data
  let handler

  // Enforce messageType whitelist
  if (!whitelist.includes(messageType)) {
    console.error(`invalid messageType: ${messageType}`)
    return false
  }

  try {
    const handlerModule = await import(`./${messageType}.js`)
    handler = handlerModule.default
    handler(data)
    return true
  } catch (error) {
    console.error(`Error loading or executing message handler for "${messageType}"`, error)
  }
}

export default handleLtiPostMessage
