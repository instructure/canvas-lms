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

import { create } from 'zustand'
import { devtools } from 'zustand/middleware'

type Order = {
  _id: string
  subEntries: Order[]

}

type State = {
  replyRefs: Map<string, HTMLElement>
  highlightedRef: HTMLElement | null
  highlightedId: string | null
  rootEntries: Order[]
  isSplitScreen: boolean
}

type Actions = {
  setSplitScreen: (isSplitScreen: boolean) => void
  setRootEntries: (rootEntryIds: string[]) => void
  addRootEntry: (rootEntryId: string, position?: "first" | "last") => void
  pushSubEntries: (entries: { _id: string, deleted: boolean, parentId: string }[], rootEntryId: string) => void
  addReplyRef: (id: string, ref: HTMLElement) => void
  removeReplyRef: (id: string) => void
  highlightNext: (isSplitScreen?: boolean, isSplitScreenOpen?: boolean) => void
  highlightPrev: (isSplitScreen?: boolean, isSplitScreenOpen?: boolean) => void
  highlightEl: (elementRef: HTMLElement) => void
  clearHighlighted: () => void
}

const flattenEntries = (rootEntries: Order[], replyeRefs: Map<string, HTMLElement>) => {
  return rootEntries
    .flatMap(entry => [entry._id, ...entry.subEntries.map(subEntry => subEntry._id)])
    .filter(id => replyeRefs.has(id))
}

const flattenEntries2 = (entries: { _id: string, deleted: boolean, parentId: string }[], rootEntryId: string) => {
  const result: string[] = []
  const map = new Map()

  entries.forEach(entry => {
    map.set(entry._id, entry)
  })

  function dfs(entry: { _id: string, deleted: boolean, parentId: string }) {
    if (!entry.deleted) {
      result.push(entry._id)
    }

    entries.forEach(e => {
      if (e.parentId === entry._id) {
        dfs(e)
      }
    })
  }

  entries.forEach(entry => {
    if (entry.parentId === rootEntryId) {
      dfs(entry)
    }
  })

  return result
}

const useHighlightStore = create<State & Actions>()(
  devtools(set => ({
    isSplitScreen: false,
    replyRefs: new Map(),
    highlightedRef: null,
    highlightedId: null,
    rootEntries: [],
    setSplitScreen: (isSplitScreen) =>
      set(() => {
        return {
          isSplitScreen
        }
      }, undefined, 'splitScreen/set'),
    setRootEntries: ids =>
      set(state => {
        if (!state.rootEntries.length) {
          return { rootEntries: ids.map(id => ({ _id: id, subEntries: [] })) }
        } else if (state.rootEntries.length === ids.length) {
          const newEntries = ids.map((id) => {
            const entry = state.rootEntries.find(entry => entry._id === id)

            return entry
          }).filter((entry => entry !== undefined))

          return { rootEntries: newEntries }
        } else {
          return {
            rootEntries: ids.map(id => {
              const entry = state.rootEntries.find(entry => entry._id === id)
              if (entry) {
                return entry
              }

              return { _id: id, subEntries: [] }
            })
          }
        }
      }, undefined, 'rootEntry/set'),
    addRootEntry: (id, position = "last") =>
      set(state => {
        const rootEntry = state.rootEntries.find(entry => entry._id === id)

        if (!rootEntry) {
          if (position === "first") {
            return {
              rootEntries: [
                { _id: id, subEntries: [] },
                ...state.rootEntries
              ]
            }
          }

          return {
            rootEntries: [
              ...state.rootEntries,
              { _id: id, subEntries: [] }
            ]
          }
        }

        return state
      }, undefined, 'rootEntry/add'),
    pushSubEntries: (entries, rootEntryId) =>
      set(state => {
        return {
          rootEntries: state.rootEntries.map((entry) => {
            if (entry._id === rootEntryId) {
              return {
                ...entry,
                subEntries: flattenEntries2(entries, rootEntryId).map((_id) => ({ _id, subEntries: [] }))
              }
            }

            return entry
          })
        }
      }, undefined, 'subEntries/push'),
    addReplyRef: (id, ref) =>
      set(state => {
        if (!state.replyRefs.has(id)) {
          return { replyRefs: state.replyRefs.set(id, ref) }
        }

        return state
      }, undefined, 'ref/add'),
    removeReplyRef: id =>
      set(state => {
        state.replyRefs.delete(id)
        return { replyRefs: state.replyRefs }
      }, undefined, 'ref/remove'),
    highlightNext: (_isSplitScreen, isSplitScreenOpen) =>
      set(state => {
        if (isSplitScreenOpen) {
          // TODO: fix splitscreen view
          return state
        }
        const orderedIds = flattenEntries(state.rootEntries, state.replyRefs)
        const currentIndex = orderedIds.findIndex(id => state.highlightedId === id)

        if (currentIndex === orderedIds.length - 1) {
          return state
        }

        if (!state.highlightedId) {
          const ref = state.replyRefs.get(orderedIds[0])
          if (ref) {
            ref.focus()
          }
          return {
            highlightedId: orderedIds[0],
          }
        }

        if (currentIndex === -1) {
          return state
        }

        const ref = state.replyRefs.get(orderedIds[currentIndex + 1])

        if (ref) {
          ref.focus()
        }

        return {
          highlightedId: orderedIds[currentIndex + 1],
        }
      }, undefined, 'highlight/next'),
    highlightPrev: (_isSplitScreen, isSplitScreenOpen) =>
      set(state => {
        if (isSplitScreenOpen) {
          // TODO: fix splitscreen view
          return state
        }

        const orderedIds = flattenEntries(state.rootEntries, state.replyRefs)
        if (state.highlightedId === null) {
          return state
        }

        const currentIndex = orderedIds.findIndex(id => state.highlightedId === id)

        if (currentIndex === 0) {
          return state
        } else if (currentIndex === -1) {
          // TODO: something if the highlightedId is not in the list
          return state
        }

        const newId = orderedIds[currentIndex - 1]

        const ref = state.replyRefs.get(newId)

        if (ref) {
          ref.focus()
        }

        return {
          highlightedId: newId,
        }
      }, undefined, 'highlight/prev'),
    highlightEl: (elementRef) => set((state) => {
      if (!state.highlightedId) {
        const id = Array.from(state.replyRefs.entries()).find(([_key, value]) => value === elementRef)?.[0]

        if (id) {
          return {
            highlightedId: id
          }
        }
      }

      return state
    }, undefined, 'highlight/el'),
    clearHighlighted: () =>
      set(() => {
        return {
          highlightedId: null,
        }
      }, undefined, 'highlight/clear'),
  }),
    // redux devtool configuration
    {
      name: 'HighlightStore',
      enabled: false// TODO: only enable in dev mode
    }
  )
)

export default useHighlightStore
