/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {create} from 'zustand'

export type Breadcrumb = {
  name: string
  /**
   * The URL of the breadcrumb. Because breadcrumbs can be arbitrarily nested, this URL *must* be provided, so
   * that the breadcrumb can correctly link to the intended page. This ensures proper navigation within the application.
   */
  url: string
}

export interface BreadcrumbStoreActions {
  setBreadcrumbs: (breadcrumbs: Breadcrumb[]) => void
  appendBreadcrumb: (breadcrumb: Breadcrumb) => void
  popBreadcrumb: () => void
  resetBreadcrumbs: () => void
}
/**
 * Get the default breadcrumbs from the ENV or the DOM. Note that the DOM is only used if the ENV is not present.
 * If the DOM is used, the breadcrumbs are cached in the ENV for future use.
 * @returns The default breadcrumbs from the ENV or the DOM
 */
const defaultBreadcrumbs = (): Breadcrumb[] => {
  if (window.ENV.breadcrumbs) {
    return window.ENV.breadcrumbs
  }

  const breadcrumbElement = document.querySelector('#breadcrumbs > ul')

  if (!breadcrumbElement) {
    return []
  }

  const crumbs = Array.from(breadcrumbElement.querySelectorAll('li'))
    // the first breadcrumb is a home icon, we don't want that. We're just going to leave it in place.
    .slice(1)
    .map(li => {
      // if there's an anchor tag, use that as the breadcrumb, otherwise use the span
      const a = li.querySelector('a')
      if (a) {
        return {
          name: a.textContent?.trim() ?? '',
          // All anchor tags *should* have an href, but just in case they don't, we'll default to the current page
          url: a.getAttribute('href') ?? window.location.pathname,
        }
      } else {
        const span = li.querySelector('span')!
        return {
          name: span.textContent?.trim() ?? '',
          // Span's are typically used to represent the current page
          url: window.location.pathname,
        }
      }
    })
    // Filter out any errant breadcrumbs that don't have a name. If it doesn't have a name, it's not a breadcrumb!
    .filter(crumb => crumb.name.length > 0)

  window.ENV.breadcrumbs = crumbs

  return crumbs
}

export const useBreadcrumbStore = create<{state: Breadcrumb[]} & BreadcrumbStoreActions>(set => ({
  state: defaultBreadcrumbs() ?? [],
  appendBreadcrumb: breadcrumb =>
    set(state => {
      return {
        state: [...state.state, breadcrumb],
      }
    }),
  popBreadcrumb: () =>
    set(state => {
      const newState = [...state.state]
      newState.pop()
      return {state: newState}
    }),
  setBreadcrumbs: breadcrumbs => set({state: breadcrumbs}),
  resetBreadcrumbs: () => set({state: defaultBreadcrumbs() ?? []}),
}))

/**
 * Sync the breadcrumbs in the store with the UI. This is only necessary if the instui_nav feature flag is off. Otherwise,
 * React takes care of this for us.
 * @param crumbs The breadcrumbs to sync with the UI
 */
const syncBreadcrumbs = (crumbs: Breadcrumb[]) => {
  const breadcrumbElement = document.querySelector('#breadcrumbs > ul')

  if (!breadcrumbElement) {
    return
  }

  // Clear the existing breadcrumbs, except for the very first, which is the home icon.
  // The store is now the source of truth (mostly)
  for (let i = breadcrumbElement.children.length - 1; i > 0; i--) {
    breadcrumbElement.removeChild(breadcrumbElement.children[i])
  }

  crumbs.forEach((crumb, index) => {
    const li = document.createElement('li')

    const span = document.createElement('span')
    span.className = 'ellipsible'
    span.textContent = crumb.name

    if (index < crumbs.length - 1) {
      const a = document.createElement('a')
      a.href = crumb.url
      a.appendChild(span)
      li.appendChild(a)
    } else {
      // The final breadcrumb is never a link, as it's the current page
      li.appendChild(span)
    }
    breadcrumbElement.appendChild(li)
  })
}

// Some pages don't use the InstUI Top Nav, so we should still manually sync the breadcrumbs in those cases.
if (!document.getElementById('react-instui-topnav')) {
  useBreadcrumbStore.subscribe(state => {
    syncBreadcrumbs(state.state)
  })
}
