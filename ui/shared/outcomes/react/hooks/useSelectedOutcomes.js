/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useReducer, useCallback} from 'react'

const useSelectedOutcomes = (initialValue = new Set()) => {
  const reducer = (prevState, action) => {
    switch (action.type) {
      case 'clear': {
        return new Set()
      }
      case 'remove': {
        const {linkId} = action.payload
        const newState = new Set(prevState)
        if (newState.has(linkId)) {
          newState.delete(linkId)
        }
        return newState
      }
      case 'toggle': {
        const {linkId} = action.payload
        const newState = new Set(prevState)
        if (newState.has(linkId)) {
          newState.delete(linkId)
        } else {
          newState.add(linkId)
        }
        return newState
      }
      default:
        return prevState
    }
  }
  // reducer supports limited number of actions so they are hard coded as functions
  const [selectedOutcomeIds, dispatchSelectedOutcomeIds] = useReducer(reducer, initialValue)
  const selectedOutcomesCount = selectedOutcomeIds.size
  const toggleSelectedOutcomes = useCallback(
    outcome => dispatchSelectedOutcomeIds({type: 'toggle', payload: {linkId: outcome.linkId}}),
    []
  )
  const clearSelectedOutcomes = useCallback(() => dispatchSelectedOutcomeIds({type: 'clear'}), [])
  const removeSelectedOutcome = useCallback(
    outcome => dispatchSelectedOutcomeIds({type: 'remove', payload: {linkId: outcome.linkId}}),
    []
  )
  return {
    selectedOutcomeIds,
    selectedOutcomesCount,
    toggleSelectedOutcomes,
    clearSelectedOutcomes,
    removeSelectedOutcome,
    dispatchSelectedOutcomeIds,
  }
}

export default useSelectedOutcomes
