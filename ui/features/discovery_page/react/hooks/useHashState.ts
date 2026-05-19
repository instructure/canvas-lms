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

import {useCallback, useEffect, useState} from 'react'

// syncs a boolean state with a URL hash fragment
// when active, the hash is set; when inactive, the hash is removed
export function useHashState(hash: string): [boolean, (open: boolean) => void] {
  const [active, setActive] = useState(() => window.location.hash === hash)

  // hash → state
  useEffect(() => {
    const handleHashChange = () => setActive(window.location.hash === hash)
    window.addEventListener('hashchange', handleHashChange)
    return () => window.removeEventListener('hashchange', handleHashChange)
  }, [hash])

  // state → hash
  useEffect(() => {
    if (active) {
      if (window.location.hash !== hash) window.location.hash = hash
    } else if (window.location.hash === hash) {
      history.replaceState(null, '', window.location.pathname + window.location.search)
    }
  }, [active, hash])

  const setHashState = useCallback((open: boolean) => {
    setActive(open)
  }, [])

  return [active, setHashState]
}
