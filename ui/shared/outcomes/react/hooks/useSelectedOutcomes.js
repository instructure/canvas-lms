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

const useSelectedOutcomes = (initialValue = {}) => {
  const reducer = (prevState, action) => {
    switch (action.type) {
      case 'clear': {
        return {}
      }
      case 'toggle': {
        const {_id, title, canUnlink} = action.payload
        const newState = {...prevState}
        prevState[_id] ? delete newState[_id] : (newState[_id] = {_id, title, canUnlink})
        return newState
      }
      default:
        return prevState
    }
  }
  // reducer supports limited number of actions so they are hard coded as functions
  const [selectedOutcomes, dispatchSelectedOutcomes] = useReducer(reducer, initialValue)
  const selectedOutcomesCount = Object.keys(selectedOutcomes).length
  const toggleSelectedOutcomes = useCallback(
    outcome => dispatchSelectedOutcomes({type: 'toggle', payload: outcome}),
    []
  )
  const clearSelectedOutcomes = useCallback(() => dispatchSelectedOutcomes({type: 'clear'}), [])

  return {
    selectedOutcomes,
    selectedOutcomesCount,
    toggleSelectedOutcomes,
    clearSelectedOutcomes,
    dispatchSelectedOutcomes
  }
}

export default useSelectedOutcomes
