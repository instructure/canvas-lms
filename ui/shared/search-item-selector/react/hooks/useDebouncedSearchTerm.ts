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

// We don't want to search immediately after each keystroke, so debounce changes to a search term.
//
// This hook creates two pieces of state: {
//   searchTerm: the debounced search term
//   searchTermIsPending:
//     a non-debounced boolean indicating whether a change to searchTerm is pending. this can change
//     with every call to setSearchTerm. If you want your component to appear to be loading before
//     the search actually begins, you'll want to || this with your actual loading state.
// }
//
// call this like:
// useDebouncedSearchTerm(defaultValue, options)
// options = {
//   timeout: debounce ms. Has a sensible default
//   isSearchableTerm: searchTerm only gets set if this returns true
// }
// returns {
//   searchTerm: the search term state value,
//   searchTermIsPending: the searchTermIsPending state value
//   setSearchTerm: A Debounced setter for searchTerm. It checks the isSearchableTerm before setting.
//   cancelCallback: the use-debounce cancel function
//   callPending: the use-debounce callPending function
// }
//
// NOTE: Unlike most hooks, the setSearchTerm function will be a new function every time
// the search term changes.

import {useState, useCallback} from 'react'
import {useDebouncedCallback} from 'use-debounce'

const TYPING_DEBOUNCE_TIMEOUT = 750

// This jsdoc comment lets typescript know the types of the parameters to useDebouncedSearchTerm
/**
 * @param deaultValue {string}
 * @param  {timeout: number, isSearchableTerm {() => boolean}}
 */
export default function useDebouncedSearchTerm(
  defaultValue: string,
  {
    timeout = TYPING_DEBOUNCE_TIMEOUT,
    isSearchableTerm = () => true,
  }: {
    timeout?: number
    isSearchableTerm?: (term: string) => boolean
  } = {}
) {
  const [searchTerm, rawSetSearchTerm] = useState(defaultValue)
  const [searchTermIsPending, setSearchIsPending] = useState(false)

  // We only want to set the searchTerm state if the final value is actually
  // different than the old value, and only if the new value is valid.
  const searchTermWillChange = useCallback(
    (oldTerm, newTerm) => oldTerm !== newTerm && isSearchableTerm(newTerm),
    [isSearchableTerm]
  )

  const [debouncedSetSearchTerm, cancelCallback, callPending] = useDebouncedCallback(
    (newSearchTerm: string) => {
      // Set the new search term first to avoid a render where isPending is
      // false but the new search term hasn't been set yet.
      if (searchTermWillChange(searchTerm, newSearchTerm)) {
        rawSetSearchTerm(newSearchTerm)
      }
      // Whether we actually set the new search term or not, a change can no
      // longer be pending because this callback has now been called.
      setSearchIsPending(false)
    },
    timeout
  )

  const wrappedCancelCallback = (...args: any[]) => {
    setSearchIsPending(false)
    // @ts-expect-error
    cancelCallback(...args)
  }

  // Note that this depends on searchTerm, so this will return a new function
  // every time the searchTerm actually changes.
  const setSearchTerm = useCallback(
    (newSearchTerm: string) => {
      // if the search term becomes the same as it was before, then a search
      // will no longer be pending and we can set that state to false.
      setSearchIsPending(searchTermWillChange(searchTerm, newSearchTerm))
      debouncedSetSearchTerm(newSearchTerm)
    },
    [debouncedSetSearchTerm, searchTermWillChange, searchTerm]
  )

  return {
    searchTerm,
    setSearchTerm,
    searchTermIsPending,
    cancelCallback: wrappedCancelCallback,
    callPending,
  }
}
