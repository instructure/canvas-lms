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

import produce, {Draft} from 'immer'
import {isEqual} from 'es-toolkit/compat'
import {useRef, createContext, useContext, useSyncExternalStore, PropsWithChildren} from 'react'

interface Store<T> {
  get: () => T
  set: (setter: (draft: Draft<T>) => void) => void
  subscribe: (callback: () => void) => () => void
}

const FastContext = createContext<Store<any> | null>(null)
FastContext.displayName = 'FastContext'

export function configureStore<T>(initialState: T): Store<T> {
  let store = initialState

  const subscribers = new Set<() => void>()

  const get = () => store

  const set = (setter: (draft: Draft<T>) => void) => {
    const next = produce(store, setter)
    if (next !== store) {
      store = next
      subscribers.forEach(callback => callback())
    }
  }

  const subscribe = (callback: () => void) => {
    subscribers.add(callback)
    return () => subscribers.delete(callback)
  }

  return {
    get,
    set,
    subscribe,
  }
}

export function Provider(props: PropsWithChildren<{store: Store<any>}>) {
  return <FastContext.Provider value={props.store}>{props.children}</FastContext.Provider>
}

export function useSelector<R>(selector: (state: any) => R): R {
  const store = useContext(FastContext)
  if (!store) {
    throw new Error('Store not found')
  }

  const lastRef = useRef<R>(selector(store.get()))
  return useSyncExternalStore(store.subscribe, () => {
    const next = selector(store.get())
    if (isEqual(next, lastRef.current)) {
      return lastRef.current
    } else {
      lastRef.current = next
      return next
    }
  })
}
useSelector.withType = <T,>() => {
  return <R,>(selector: (state: T) => R): R => {
    return useSelector(selector)
  }
}

export function useSetStore(): Store<any>['set'] {
  const store = useContext(FastContext)
  if (!store) {
    throw new Error('Store not found')
  }
  return store.set
}
useSetStore.withType = <T,>() => {
  return (): ((setter: (draft: Draft<T>) => void) => void) => {
    return useSetStore()
  }
}

export function useGetStore(): () => any {
  const store = useContext(FastContext)
  if (!store) {
    throw new Error('Store not found')
  }
  return store.get
}
useGetStore.withType = <T,>() => {
  return (): (() => T) => {
    return useGetStore()
  }
}
