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

import {useEffect} from 'react'
import {useBreadcrumbStore} from './useBreadcrumbStore'

/**
 * Appends breadcrumbs to the end of the current breadcrumb list. This is useful for dynamically adding
 * breadcrumbs to a page while using React Router to handle navigation. Cleanup, removal, and syncing is
 * handled automatically by this hook.
 *
 * @example Imagine that you had a render tree like this, with routing controlled by React Router:
 * ```
 * <App>
 *   <Page1>
 *     <NestedPage />
 *   </Page1 >
 *   <Page2 />
 * </App>
 * ```
 * When a user is on the `NestedPage` component, you want the breadcrumbs to look like this:
 * ```
 * Default > Home > Page1 > NestedPage
 * ```
 * And when they're on Page2, you want the breadcrumbs to look like this:
 * ```
 * Default > Home > Page2
 * ```
 * Then your components would use this hook like so:
 * ```
 * const NestedPage = () => {
 *   useAppendBreadcrumb([{ label: 'NestedPage', href: '/page1/nested' }])
 *   // Everything else
 * }

 * const Page1 = () => {
 *   useAppendBreadcrumb([{ label: 'Page1', href: '/page1' }])
 *   // Everything else
 * }

 * const Page2 = () => {
 *   useAppendBreadcrumb([{ label: 'Page2', href: '/page2' }])
 *   // Everything else
 * }

 * const App = () => {
 *   useAppendBreadcrumb([{ label: 'Home', href: '/' }])
 *   // Everything else
 * }
 * ```
 *
 * @param name - The name of the breadcrumb. This is the text that will be displayed in the breadcrumb.
 * @param url - The URL of the breadcrumb. Because breadcrumbs can be arbitrarily nested, this URL *must* be provided, so
 * that the breadcrumb can correctly link to the intended page. This ensures proper navigation within the application.
 * @param enabled - Whether or not to append the breadcrumbs. This is useful for conditionally appending breadcrumbs,
 * such as for gating changes behind a feature flag or only appending if data has been loaded from the server.
 *
 */
export const useAppendBreadcrumb = (name: string, url: string, enabled = true) => {
  const {append, pop} = useBreadcrumbStore(s => ({
    append: s.appendBreadcrumb,
    pop: s.popBreadcrumb,
  }))

  useEffect(() => {
    if (enabled) {
      append({name, url})
      return pop
    }
  }, [name, url, append, enabled, pop])
}
