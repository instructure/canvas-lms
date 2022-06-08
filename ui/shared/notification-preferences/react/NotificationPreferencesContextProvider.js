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

import React, {createContext, useState} from 'react'

const DEFAULT_CONTEXT = {value: 'account', name: 'Account'}

export const NotificationPreferencesContext = createContext(null)

export const NotificationPreferencesContextProvider = props => {
  const [currentContext, setContext] = useState(DEFAULT_CONTEXT)

  return (
    <NotificationPreferencesContext.Provider value={{currentContext, setContext}}>
      {props.children}
    </NotificationPreferencesContext.Provider>
  )
}
