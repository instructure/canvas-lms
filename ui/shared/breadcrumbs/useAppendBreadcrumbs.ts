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
import type {Breadcrumb} from './useBreadcrumbStore'
import {useBreadcrumbStore} from './useBreadcrumbStore'

/**
 * Appends breadcrumbs to the end of the current breadcrumb list. This is useful for dynamically adding
 * breadcrumbs to a page while using React Router to handle navigation.
 *
 * When using this component, you should also use `useAppendBreadcrumbsToDefaults` in the parent component
 * to set the default breadcrumbs and prevent the breadcrumbs from growing indefinitely.
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
 * Then your components would use the two breadcrumbs hooks as so:
 * ```
 * const NestedPage = () => {
 *   useAppendBreadcrumbs([{ label: 'NestedPage', href: '/page1/nested' }])
 *   // Everything else
 * }

 * const Page1 = () => {
 *   useAppendBreadcrumbs([{ label: 'Page1', href: '/page1' }])
 *   // Everything else
 * }

 * const Page2 = () => {
 *   useAppendBreadcrumbs([{ label: 'Page2', href: '/page2' }])
 *   // Everything else
 * }

 * const App = () => {
 *   useAppendBreadcrumbsToDefaults([{ label: 'Home', href: '/' }])
 *   // Everything else
 * }
 * ```
 * The App component uses `useAppendBreadcrumbsToDefaults` to set the default breadcrumbs, and the other components
 * use `useAppendBreadcrumbs` to append their breadcrumbs as needed. Notice that we need to have one component that
 * sets the default breadcrumbs, otherwise, every navigation will append to the previous breadcrumbs, resulting in an
 * ever-growing list of breadcrumbs.
 *
 * @param breadcrumbs - The breadcrumbs to append to the default breadcrumbs.
 * @param enabled - Whether or not to append the breadcrumbs. This is useful for conditionally appending breadcrumbs,
 * such as for gating changes behind a feature flag or only appending if data has been loaded from the server.
 *
 */
export const useAppendBreadcrumbs = (breadcrumbs: Breadcrumb | Breadcrumb[], enabled = true) => {
  const appendCrumbs = useBreadcrumbStore(s => s.appendBreadcrumbs)

  useEffect(() => {
    if (enabled) {
      appendCrumbs(breadcrumbs)
    }
  }, [breadcrumbs, appendCrumbs, enabled])
}
