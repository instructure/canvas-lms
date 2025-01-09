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
 * Appends breadcrumbs to the default breadcrumbs that are set in window.ENV.breadcrumbs.
 * This is useful for dynamically adding breadcrumbs to a page that are not part of the default breadcrumbs.
 *
 * @note This should only be used by a single component within the render tree, otherwise the last
 *       component to render will overwrite the breadcrumbs set by the previous component. If you need
 *       to append breadcrumbs from multiple components, you should use the `useAppendBreadcrumbs` hook in
 *       combination with this hook.
 * @link { import('./useAppendBreadcrumbs').useAppendBreadcrumbs }
 * @param breadcrumbs - The breadcrumbs to append to the default breadcrumbs.
 * @param enabled - Whether or not to append the breadcrumbs. This is useful for conditionally appending breadcrumbs,
 * such as for gating changes behind a feature flag or only appending if data has been loaded from the server.
 */
export const useAppendBreadcrumbsToDefaults = (
  breadcrumbs: Breadcrumb | Breadcrumb[],
  enabled = true,
) => {
  const appendCrumbs = useBreadcrumbStore(s => s.appendBreadcrumbsToDefaults)

  useEffect(() => {
    if (enabled) {
      appendCrumbs(breadcrumbs)
    }
  }, [breadcrumbs, appendCrumbs, enabled])
}
