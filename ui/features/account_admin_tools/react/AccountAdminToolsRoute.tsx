/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useEffect, useState} from 'react'
import {useParams} from 'react-router-dom'
import {Portal} from '@instructure/ui-portal'
import BouncedEmailsView from './BouncedEmailsView'
import CommMessagesView from './CommMessages'

// maybe could go into shared code if it proves more generally useful
function awaitElementById(
  id: string,
  rejectOnTimeout: boolean = false,
): Promise<HTMLElement | null> {
  return new Promise(function (resolve, reject) {
    const timer = setTimeout(neverAppeared, 1000) // wait at most 1 second (parameterize?)

    const observer = new MutationObserver(function () {
      const element = document.getElementById(id)
      if (element) {
        clearTimeout(timer)
        observer.disconnect()
        resolve(element)
      }
    })

    function neverAppeared(): void {
      observer.disconnect()
      if (rejectOnTimeout) reject(new ReferenceError(`Element with id "${id}" never showed up`))
      else resolve(null)
    }

    // If the element is already there, no need to get fancy
    const initialElement = document.getElementById(id)
    if (initialElement) {
      clearTimeout(timer)
      resolve(initialElement)
    } else observer.observe(document.body, {childList: true, subtree: true})
  })
}

type PortalMount = {
  mountPoint: HTMLElement
  component: JSX.Element
}

let portals: Array<PortalMount>

// This is set up so it can be used to render multiple portals across the
// entire settings page settings page React code! Just repeat the pattern
// for each tab or bundle you want to render.

// This route-rendered component is more complex than most because it needs
// to wait for the underlying container divs to appear before sticking the
// portals into them, since they are not rendered by Rails in an ERB by
// some Backbone code. A bit of a hack but I'd rather go in the React Router
// direction than manually rendering React components in the Backbone code.

// Bounced Emails tab
async function bouncedEmailsTab(accountId?: string): Promise<void> {
  const mountPoint = await awaitElementById('bouncedEmailsPane')
  if (!accountId || !mountPoint) return
  portals.push({
    mountPoint,
    component: <BouncedEmailsView accountId={accountId} />,
  })
}

// Communication Messages (View Notifications) tab
async function commMessagesTab(accountId?: string): Promise<void> {
  const mountPoint = await awaitElementById('commMessagesPane')
  if (!accountId || !mountPoint) return
  portals.push({
    mountPoint,
    component: <CommMessagesView accountId={accountId} />,
  })
}

export function Component(): JSX.Element | null {
  const [ready, setReady] = useState(false)
  const {accountId} = useParams()

  useEffect(() => {
    const portalsReady: Array<Promise<void>> = []
    portals = []

    portalsReady.push(bouncedEmailsTab(accountId))
    portalsReady.push(commMessagesTab(accountId))

    Promise.all(portalsReady).then(() => setReady(true))
  }, [accountId])

  return ready ? (
    <>
      {portals.map(({mountPoint, component}) => (
        <Portal key={mountPoint.id} open={true} mountNode={mountPoint}>
          {component}
        </Portal>
      ))}
    </>
  ) : null
}
