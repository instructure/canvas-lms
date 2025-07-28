/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {useState, useEffect, useRef} from 'react'
import {isEqual} from 'lodash'

/*
 * React class components can use this.setState() which takes an optional second
 * argument, a callback function that is called after the state change has been
 * fully applied. There's no equivalent to that with the useState hook; this
 * custom hook addresses that by allowing a callback function to be provided as
 * a second argument to the setter function; that callback is then called after
 * the rerender triggered by the state change is completed.
 *
 *   const [val, setVal] = useStateWithCallback(initialVal [, makeMultipleCallbacks])
 *
 *   function callback(newVal) { ... }
 *
 *   setVal(newVal [, callback])
 *
 * By default the callback is called once, after the component is updated, with
 * the new value of the state variable. This most closely matches the semantics
 * of the old this.setState() callback feature. However, you can pass `true` as
 * the second argument to the useStateWithCallback hook, and then it will arrange
 * for the callback to be called multiple times if the state setter function is
 * called multiple times, if that is needed by the application (Although it's
 * probably kind of smelly to call the same state setter function more than once
 * per component render anyway.)
 *
 * The callback is called with the new state value as argument. If makeMultiple-
 * callbacks is true, the argument to each call is the intermediate value that
 * the setter is setting the state to.
 *
 * The callback is not called if the new state value is equal (as determined
 * by lodash isEqual) to the old value.
 */

type ValOrFunc<T> = T | ((arg: T) => T)
type Callback<T> = (arg: T) => void
type Setter<T> = (valOrFunc: ValOrFunc<T>, callback?: Callback<T>) => void

export default function useStateWithCallback<T>(
  initialValue: T,
  makeMultipleCallbacks: boolean = false,
): [T, Setter<T>] {
  type BoundCallback = () => void // argument is bound when the callback is created

  const [value, setValue] = useState<T>(initialValue)
  const curValue = useRef<T>(value)
  const callbackList = useRef<Array<BoundCallback>>([])

  function ourSetter(valOrFunc: ValOrFunc<T>, callback?: Callback<T>): void {
    setValue(valOrFunc)
    const oldValue = curValue.current
    curValue.current = valOrFunc instanceof Function ? valOrFunc(oldValue) : valOrFunc
    if (typeof callback === 'undefined' || isEqual(oldValue, curValue.current)) return
    // The following check would be unnecessary in a pure typescript environment
    // because anything other than a function would be a type error, but alas, we
    // still have to watch our backs
    if (typeof callback !== 'function') throw new TypeError('callback must be a function')
    if (makeMultipleCallbacks) {
      callbackList.current.push(callback.bind(null, curValue.current))
    } else {
      callbackList.current[0] = callback.bind(null, curValue.current)
    }
  }

  useEffect(function () {
    callbackList.current.forEach(fn => fn())
    callbackList.current = []
  })

  return [value, ourSetter]
}
