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

import React, {createContext, type ReactNode, useContext} from 'react'
import {useFetchNewLoginData} from '../hooks'
import type {AuthProvider, HelpLink, PasswordPolicy, SelfRegistrationType} from '../types'

interface NewLoginDataContextType {
  isDataLoading: boolean
  enableCourseCatalog?: boolean
  authProviders?: AuthProvider[]
  loginHandleName?: string
  loginLogoUrl?: string
  loginLogoText?: string
  bodyBgColor?: string
  bodyBgImage?: string
  isPreviewMode?: boolean
  selfRegistrationType?: SelfRegistrationType
  recaptchaKey?: string
  termsRequired?: boolean
  termsOfUseUrl?: string
  privacyPolicyUrl?: string
  requireEmail?: boolean
  passwordPolicy?: PasswordPolicy
  forgotPasswordUrl?: string
  invalidLoginFaqUrl?: string
  helpLink?: HelpLink
  requireAup?: boolean
}

const NewLoginDataContext = createContext<NewLoginDataContextType | undefined>(undefined)

interface NewLoginDataProviderProps {
  children: ReactNode
}

export const NewLoginDataProvider = ({children}: NewLoginDataProviderProps) => {
  const {data, isDataLoading} = useFetchNewLoginData()

  const {
    enableCourseCatalog,
    authProviders,
    loginHandleName,
    loginLogoUrl,
    loginLogoText,
    bodyBgColor,
    bodyBgImage,
    isPreviewMode,
    selfRegistrationType,
    recaptchaKey,
    termsRequired,
    termsOfUseUrl,
    privacyPolicyUrl,
    requireEmail,
    passwordPolicy,
    forgotPasswordUrl,
    invalidLoginFaqUrl,
    helpLink,
    requireAup,
  } = data

  const value: NewLoginDataContextType = {
    isDataLoading,
    enableCourseCatalog,
    authProviders,
    loginHandleName,
    loginLogoUrl,
    loginLogoText,
    bodyBgColor,
    bodyBgImage,
    isPreviewMode,
    selfRegistrationType,
    recaptchaKey,
    termsRequired,
    termsOfUseUrl,
    privacyPolicyUrl,
    requireEmail,
    passwordPolicy,
    forgotPasswordUrl,
    invalidLoginFaqUrl,
    helpLink,
    requireAup,
  }

  return <NewLoginDataContext.Provider value={value}>{children}</NewLoginDataContext.Provider>
}

export const useNewLoginData = (): NewLoginDataContextType => {
  const context = useContext(NewLoginDataContext)

  if (context === undefined) {
    throw new Error('useNewLoginData must be used within a NewLoginDataProvider')
  }

  return context
}
