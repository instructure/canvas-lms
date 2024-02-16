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

import defaults from './defaults'

function KalturaSession() {
  this.ks = ''
  this.subp_id = ''
  this.partner_id = ''
  this.uid = ''
  this.serverTime = 0
}

KalturaSession.prototype.setSession = function (obj) {
  if (obj) {
    defaults('ks', this, obj)
    defaults('subp_id', this, obj)
    defaults('partner_id', this, obj)
    defaults('uid', this, obj)
    defaults('serverTime', this, obj)
    defaults('ui_conf_id', this, obj)
  }
}

KalturaSession.prototype.getSession = function () {
  return {
    ks: this.ks,
    subp_id: this.subp_id,
    partner_id: this.partner_id,
    uid: this.uid,
    serverTime: this.serverTime,
    ui_conf_id: this.ui_conf_id,
  }
}

KalturaSession.prototype.asEntryParams = function () {
  return this.getSession()
}

export default KalturaSession
