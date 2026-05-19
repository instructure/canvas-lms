/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {useEffect, useState, type ComponentType} from 'react'

export type PageContentWrapperProps = {
  pageContent: HTMLElement
}

export type PageContentWrapper = ComponentType<PageContentWrapperProps>

let registered: PageContentWrapper | undefined
const listeners = new Set<() => void>()

// Register a component that should wrap the page content (#application) inside
// ContentTypeExternalToolDrawer's DrawerLayout.Content. The wrapper is rendered
// in place of the default `<div ref={pageContentRef} />` slot and takes over
// responsibility for placing pageContent in the DOM.
export function registerPageContentWrapper(wrapper: PageContentWrapper): void {
  registered = wrapper
  listeners.forEach(fn => fn())
}

// Test-only hook for resetting registry state between tests.
export function _resetPageContentWrapper(): void {
  registered = undefined
  listeners.forEach(fn => fn())
}

export function usePageContentWrapper(): PageContentWrapper | undefined {
  // Lazy initializer + functional setter — `registered` is a component (function),
  // and `useState`/`setState` treat bare functions as initializers/updaters.
  const [w, setW] = useState<PageContentWrapper | undefined>(() => registered)
  useEffect(() => {
    if (w !== registered) setW(() => registered)
    const listener = () => setW(() => registered)
    listeners.add(listener)
    return () => {
      listeners.delete(listener)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])
  return w
}
