/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

// This hook is much like useEffect, except it doesn't wait for the DOM to
// render and runs the function immediately. It also takes an additional options
// parameter where you can specify {deep: true} to make it run a deep comparison
// on the dependencies instead of the default shallow comparison.
//
// This is useful for starting asynchronous operations that don't depend on the
// new DOM, such as api fetches. Because it runs immediately, it may also reduce
// flicker in the browser by avoiding multiple DOM updates.

import {useEffect, useRef} from 'react'
import {isEqual} from 'lodash'
import {shallowEqualArrays} from 'shallow-equal'

function depsHaveChanged(priorDeps, newDeps, opts) {
  return (
    (!opts.deep && !shallowEqualArrays(priorDeps, newDeps)) ||
    (opts.deep && !isEqual(priorDeps, newDeps))
  )
}

export default function useImmediate(fn, newDeps, opts = {}) {
  const priorDeps = useRef(null)
  const cleanupFn = useRef(null)

  // schedule the final cleanup for when the component unmounts
  useEffect(
    () => () => {
      if (cleanupFn.current) cleanupFn.current()
    },
    []
  )

  // Like useEffect, we want to run the fn and its cleanup every time if deps are not specified
  const depsChanged = !newDeps || depsHaveChanged(priorDeps.current, newDeps, opts)
  if (depsChanged) {
    if (cleanupFn.current) cleanupFn.current()
    cleanupFn.current = fn()
    priorDeps.current = newDeps
  }
}
