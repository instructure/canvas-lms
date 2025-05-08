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

import {useEffect} from 'react'

/**
 * A utility React hook for Pendo that conditionally transforms the current URL pathname
 * before it is registered by Pendo for analytics.
 *
 * @param whenPendoReady - A promise that resolves with the Pendo object when it's initialized.
 * @param searchValue - The substring in the current pathname to look for.
 * @param replaceValue - The value to replace `searchValue` with if the predicate is true.
 * @param shouldTransform - If true, the pathname is transformed, otherwise it remains unchanged.
 */

export function usePathTransform(
  whenPendoReady: any,
  searchValue: string,
  replaceValue: string,
  shouldTransform: boolean,
) {
  useEffect(() => {
    if (!shouldTransform) return

    whenPendoReady?.then((pendo: any) => {
      if (!pendo) return

      const newPath = window.location.pathname.replace(searchValue, replaceValue)
      pendo.location.addTransforms([
        {
          attr: 'pathname',
          action: 'Replace',
          data: newPath,
        },
      ])
    })
  }, [whenPendoReady, searchValue, replaceValue, shouldTransform])
}
