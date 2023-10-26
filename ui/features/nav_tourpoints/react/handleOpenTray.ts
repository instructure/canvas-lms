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

import tourPubSub from '@canvas/tour-pubsub'

export default async function handleOpenTray(trayType: string) {
  await new Promise<void>(resolve => {
    let resolved = false
    let timeout: number
    const unsubscribe = tourPubSub.subscribe('navigation-tray-opened', type => {
      if (resolved) return
      if (type === trayType) {
        // For A11y, we need to do some DOM shenanigans so the Tour portal
        // has screen reader focus and not the greedy nav trays.
        // The Nav Tray will automatically remove this attribute when it opens
        // when the tour is done.
        const navElement = document.getElementById('nav-tray-portal')
        if (navElement) {
          navElement.setAttribute('aria-hidden', 'true')
        }
        const tourElement = document.getElementById('___reactour')
        if (tourElement) {
          tourElement.setAttribute('aria-hidden', 'false')
        }
        clearTimeout(timeout)
        unsubscribe()
        resolve()
      }
    })

    tourPubSub.publish('navigation-tray-open', {type: trayType, noFocus: true})
    // 5 second timeout just in case it never resolves
    timeout = setTimeout(() => {
      resolved = true
      unsubscribe()
      resolve()
    }, 5000) as unknown as number
  })
}
