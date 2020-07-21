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

import {getBrowser} from 'jsx/shared/browserUtils'
import ready from '@instructure/ready'

ready(() => {
  // See service worker definition for comments on purpose and why we only
  // install it for recent (13+) Safari.
  const {name, version} = getBrowser()
  if (name !== 'Safari' || parseFloat(version) < 13) {
    console.log('Inst-FS ServiceWorker not necessary for this browser.')
  } else if (!('serviceWorker' in navigator)) {
    console.log('ServiceWorkers not available. :( Inst-FS files may fail to inline.')
  } else if (navigator.serviceWorker.controller) {
    console.log('Inst-FS ServiceWorker already registered.')
  } else {
    navigator.serviceWorker
      .register('/inst-fs-sw.js')
      .then(() => {
        console.log(
          'Registration succeeded. Refresh page to proxy Inst-FS requests through ServiceWorker.'
        )
      })
      .catch(function(err) {
        console.log('Inst-FS ServiceWorker registration failed. :(', err)
      })
  }
})
