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

import {type MutableRefObject, createContext, useContext} from 'react'

interface ObserverContextProps {
  observerRef: MutableRefObject<IntersectionObserver | undefined> | null
  nodesRef: MutableRefObject<Map<string, Element>> | null
  startObserving: (language: string) => void
  stopObserving: () => void
}

const observerContextDefaultValue = {
  observerRef: null,
  nodesRef: null,
  startObserving: (_language: string) => {},
  stopObserving: () => {},
}

export const ObserverContext = createContext<ObserverContextProps>(observerContextDefaultValue)

export const useObserverContext = () => {
  const contextData = useContext(ObserverContext)

  if (!contextData || !contextData.observerRef || !contextData.nodesRef) {
    throw new Error('useObserverContext must be used within an ObserverProvider')
  }

  return contextData
}

ObserverContext.displayName = 'ObserverContext'
