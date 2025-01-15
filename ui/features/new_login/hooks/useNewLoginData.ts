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

import {useEffect, useState} from 'react'
import {type AuthProvider, type PasswordPolicy, SelfRegistrationType} from '../types'

interface NewLoginData {
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
}

interface NewLoginDataResult {
  data: NewLoginData
  isDataLoading: boolean
}

// transform raw password policy data into a typed object
const transformPasswordPolicy = (rawPolicy: any): PasswordPolicy => {
  if (typeof rawPolicy !== 'object' || rawPolicy === null) {
    console.error('Invalid password policy data:', rawPolicy)
    return {}
  }

  return {
    disallowCommonPasswords: rawPolicy.disallow_common_passwords === 'true',
    maxRepeats: rawPolicy.max_repeats ? parseInt(rawPolicy.max_repeats, 10) : undefined,
    maxSequence: rawPolicy.max_sequence ? parseInt(rawPolicy.max_sequence, 10) : undefined,
    maximumCharacterLength: rawPolicy.maximum_character_length
      ? parseInt(rawPolicy.maximum_character_length, 10)
      : undefined,
    maximumLoginAttempts: rawPolicy.maximum_login_attempts
      ? parseInt(rawPolicy.maximum_login_attempts, 10)
      : undefined,
    minimumCharacterLength: rawPolicy.minimum_character_length
      ? parseInt(rawPolicy.minimum_character_length, 10)
      : undefined,
    requireNumberCharacters: rawPolicy.require_number_characters === 'true',
    requireSymbolCharacters: rawPolicy.require_symbol_characters === 'true',
  }
}

// transform a string into a typed SelfRegistrationType, if valid
const transformSelfRegistrationType = (
  value: string | undefined
): SelfRegistrationType | undefined =>
  value && Object.values(SelfRegistrationType).includes(value as SelfRegistrationType)
    ? (value as SelfRegistrationType)
    : undefined

// retrieve the login data container element from the DOM
const getLoginDataContainer = (): HTMLElement | null => document.getElementById('new_login_data')

// fetch a string attribute, optionally transforming it into a typed value
const getStringAttribute = <T>(
  container: HTMLElement,
  attribute: string,
  transform?: (value: string | undefined) => T | undefined
): T | undefined => {
  const rawValue = container.getAttribute(attribute)?.trim()
  if (rawValue === '') return undefined
  return transform ? transform(rawValue) : (rawValue as unknown as T | undefined)
}

// fetch a boolean attribute from the container
const getBooleanAttribute = (container: HTMLElement, attribute: string): boolean | undefined => {
  const value = container.getAttribute(attribute)?.trim().toLowerCase()
  return value === 'true' ? true : value === 'false' ? false : undefined
}

// fetch an object attribute, optionally transforming it into a typed object
const getObjectAttribute = <T>(
  container: HTMLElement,
  attribute: string,
  transform?: (raw: unknown) => T
): T | undefined => {
  const value = getStringAttribute(container, attribute)
  if (!value) return undefined
  if (typeof value === 'string') {
    try {
      const parsedValue = JSON.parse(value)
      return transform ? transform(parsedValue) : (parsedValue as T)
    } catch (e) {
      console.error(`Failed to parse ${attribute} as JSON:`, e)
    }
  }
  return undefined
}

// fetch login data from HTML attributes
const fetchLoginDataFromAttributes = (): NewLoginData => {
  const container = getLoginDataContainer()

  return container
    ? {
        enableCourseCatalog: getBooleanAttribute(container, 'data-enable-course-catalog'),
        authProviders: getObjectAttribute<AuthProvider[]>(container, 'data-auth-providers'),
        loginHandleName: getStringAttribute(container, 'data-login-handle-name'),
        loginLogoUrl: getStringAttribute(container, 'data-login-logo-url'),
        loginLogoText: getStringAttribute(container, 'data-login-logo-text'),
        bodyBgColor: getStringAttribute(container, 'data-body-bg-color'),
        bodyBgImage: getStringAttribute(container, 'data-body-bg-image'),
        isPreviewMode: getBooleanAttribute(container, 'data-is-preview-mode'),
        selfRegistrationType: getStringAttribute<SelfRegistrationType>(
          container,
          'data-self-registration-type',
          transformSelfRegistrationType
        ),
        recaptchaKey: getStringAttribute(container, 'data-recaptcha-key'),
        termsRequired: getBooleanAttribute(container, 'data-terms-required'),
        termsOfUseUrl: getStringAttribute(container, 'data-terms-of-use-url'),
        privacyPolicyUrl: getStringAttribute(container, 'data-privacy-policy-url'),
        requireEmail: getBooleanAttribute(container, 'data-require-email'),
        passwordPolicy: getObjectAttribute<PasswordPolicy>(
          container,
          'data-password-policy',
          transformPasswordPolicy
        ),
        forgotPasswordUrl: getStringAttribute(container, 'data-forgot-password-url'),
      }
    : {}
}

// hook …
export const useNewLoginData = (): NewLoginDataResult => {
  const [newLoginData, setNewLoginData] = useState<NewLoginData>({
    enableCourseCatalog: undefined,
    authProviders: undefined,
    loginHandleName: undefined,
    loginLogoUrl: undefined,
    loginLogoText: undefined,
    bodyBgColor: undefined,
    bodyBgImage: undefined,
    isPreviewMode: undefined,
    selfRegistrationType: undefined,
    recaptchaKey: undefined,
    termsRequired: undefined,
    termsOfUseUrl: undefined,
    privacyPolicyUrl: undefined,
    requireEmail: undefined,
    passwordPolicy: undefined,
    forgotPasswordUrl: undefined,
  })
  const [isDataLoading, setIsDataLoading] = useState(true)

  useEffect(() => {
    const fetchData = async () => {
      try {
        // TODO: replace with new endpoint and a doFetchApi() call
        const data = fetchLoginDataFromAttributes()
        setNewLoginData(data)
      } catch (error) {
        console.error('Failed to fetch login data:', error)
      } finally {
        setIsDataLoading(false)
      }
    }

    fetchData()
  }, [])

  return {data: newLoginData, isDataLoading}
}
