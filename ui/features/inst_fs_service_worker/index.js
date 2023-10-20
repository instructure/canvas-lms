/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import ready from '@instructure/ready'

function isSafariVersion13OrGreater() {
  const match = /Version\/(\d+).+Safari/.exec(navigator.userAgent)
  return match ? parseInt(match[1], 10) >= 13 : false
}

ready(() => {
  // See service worker definition for comments on purpose and why we only
  // install it for recent (13+) Safari.
  if (isSafariVersion13OrGreater() && 'serviceWorker' in navigator) {
    navigator.serviceWorker
      .register('/inst-fs-sw.js')
      .then(() => {
        // eslint-disable-next-line no-console
        console.log(
          'Registration succeeded. Refresh page to proxy Inst-FS requests through ServiceWorker.'
        )
      })
      .catch(function (err) {
        // eslint-disable-next-line no-console
        console.log('Inst-FS ServiceWorker registration failed. :(', err)
      })
  }
})
