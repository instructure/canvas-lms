/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

let beforeUnloadHandler
function setUnloadMessage(msg) {
  removeUnloadMessage()

  beforeUnloadHandler = function (e) {
    return (e.returnValue = msg || '')
  }
  window.addEventListener('beforeunload', beforeUnloadHandler)
}

function removeUnloadMessage() {
  if (beforeUnloadHandler) {
    window.removeEventListener('beforeunload', beforeUnloadHandler)
    beforeUnloadHandler = null
  }
}

function findDomForWindow(sourceWindow) {
  const iframes = document.getElementsByTagName('IFRAME')
  for (let i = 0; i < iframes.length; i += 1) {
    if (iframes[i].contentWindow === sourceWindow) {
      return iframes[i]
    }
  }
  return null
}

export {setUnloadMessage, removeUnloadMessage, findDomForWindow}
