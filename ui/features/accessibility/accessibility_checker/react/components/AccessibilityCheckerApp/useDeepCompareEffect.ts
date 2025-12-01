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

import {useRef, useEffect} from 'react'
import {isEqual} from 'es-toolkit/compat'

function useDeepCompareMemoize<T>(value: T): T {
  const ref = useRef<T>(value)

  if (!isEqual(ref.current, value)) {
    ref.current = value
  }

  return ref.current
}

export function useDeepCompareEffect(callback: () => void, dependencies: any[]) {
  const memoDeps = dependencies.map(useDeepCompareMemoize)
  useEffect(callback, memoDeps)
}
