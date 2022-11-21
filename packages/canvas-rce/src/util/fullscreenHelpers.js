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

// safari implements only the webkit prefixed version of the fullscreen api
const FS_ELEMENT =
  document.fullscreenElement === undefined ? 'webkitFullscreenElement' : 'fullscreenElement'
const FS_REQUEST = document.body.requestFullscreen ? 'requestFullscreen' : 'webkitRequestFullscreen'
const FS_EXIT = document.exitFullscreen ? 'exitFullscreen' : 'webkitExitFullscreen'
const FS_CHANGEEVENT =
  FS_ELEMENT === 'webkitFullscreenElement' ? 'webkitfullscreenchange' : 'fullscreenchange'
const FS_ENABLED = document.fullscreenEnabled ? 'fullscreenEnabled' : 'webkitFullscreenEnabled'

const instuiPopupMountNode = () => document[FS_ELEMENT]

export {FS_ELEMENT, FS_REQUEST, FS_EXIT, FS_CHANGEEVENT, FS_ENABLED, instuiPopupMountNode}
