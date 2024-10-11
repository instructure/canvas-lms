/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {createContext, type ReactNode, useContext, useState} from 'react'
import type {AuthProvider} from '../types'
import {useNewLoginData} from '../hooks/useNewLoginData'

interface NewLoginContextType {
  rememberMe: boolean
  setRememberMe: (value: boolean) => void
  isUiActionPending: boolean
  setIsUiActionPending: (value: boolean) => void
  otpRequired: boolean
  setOtpRequired: (value: boolean) => void
  showForgotPassword: boolean
  setShowForgotPassword: (value: boolean) => void
  otpCommunicationChannelId: string | null
  setOtpCommunicationChannelId: (id: string | null) => void
  // define data attributes from hook
  loginHandleName: string
  authProviders: AuthProvider[]
}

const NewLoginContext = createContext<NewLoginContextType | undefined>(undefined)

interface NewLoginProviderProps {
  children: ReactNode
}

export const NewLoginProvider = ({children}: NewLoginProviderProps) => {
  const [rememberMe, setRememberMe] = useState(false)
  const [isUiActionPending, setIsUiActionPending] = useState(false)
  const [otpRequired, setOtpRequired] = useState(false)
  const [showForgotPassword, setShowForgotPassword] = useState(false)
  const [otpCommunicationChannelId, setOtpCommunicationChannelId] = useState<string | null>(null)

  // get data attribute values from hook
  const {loginHandleName, authProviders} = useNewLoginData()

  return (
    <NewLoginContext.Provider
      value={{
        rememberMe,
        setRememberMe,
        isUiActionPending,
        setIsUiActionPending,
        otpRequired,
        setOtpRequired,
        showForgotPassword,
        setShowForgotPassword,
        otpCommunicationChannelId,
        setOtpCommunicationChannelId,
        // pass data attribute hook values
        loginHandleName,
        authProviders,
      }}
    >
      {children}
    </NewLoginContext.Provider>
  )
}

export const useNewLogin = (): NewLoginContextType => {
  const context = useContext(NewLoginContext)

  if (context === undefined) {
    throw new Error('useNewLogin must be used within a NewLoginProvider')
  }

  return context
}
