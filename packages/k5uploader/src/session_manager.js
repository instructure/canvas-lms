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

import messageBus from './message_bus'
import k5Options from './k5_options'
import KalturaSession from './kaltura_session'

function SessionManager() {
  this.sessionData = new KalturaSession()
}

SessionManager.prototype.loadSession = function () {
  const xhr = new XMLHttpRequest()
  xhr.open('POST', k5Options.sessionUrl, true)
  xhr.responseType = 'json'
  xhr.onload = this.onSessionLoaded.bind(this)
  xhr.send()
}

SessionManager.prototype.onSessionLoaded = function (e) {
  const xhr = e.target
  if (xhr.status == 200) {
    this.sessionData.setSession(xhr.response)
    messageBus.dispatchEvent('SessionManager.complete', this.sessionData, this)
  } else {
    messageBus.dispatchEvent('SessionManager.error')
  }
}

SessionManager.prototype.getSession = function () {
  return this.sessionData
}

export default SessionManager
