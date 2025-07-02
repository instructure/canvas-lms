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

import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {assignLocation, windowPathname} from '@canvas/util/globalUtils'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {TextInput} from '@instructure/ui-text-input'
import React, {useEffect, useRef, useState} from 'react'
import {useNewLogin, useNewLoginData} from '../context'
import {ROUTES} from '../routes/routes'
import {performSignIn} from '../services'
import {
  ActionPrompt,
  ForgotPasswordLink,
  LoginTroubleLink,
  RememberMeCheckbox,
  SSOButtons,
} from '../shared'
import {createErrorMessage} from '../shared/helpers'
import {SelfRegistrationType} from '../types'
import OtpForm from './OtpForm'

const I18n = createI18nScope('new_login')

const SignIn = () => {
  const {isUiActionPending, otpRequired, rememberMe, setIsUiActionPending, setOtpRequired} =
    useNewLogin()
  const {authProviders, invalidLoginFaqUrl, isPreviewMode, loginHandleName, selfRegistrationType} =
    useNewLoginData()

  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [usernameError, setUsernameError] = useState('')
  const [passwordError, setPasswordError] = useState('')

  const isRedirectingRef = useRef(false)
  const usernameInputRef = useRef<HTMLInputElement | null>(null)
  const passwordInputRef = useRef<HTMLInputElement | null>(null)

  const isDisabled = isPreviewMode || isUiActionPending

  useEffect(() => {
    setUsername('')
    setPassword('')
    setUsernameError('')
    setPasswordError('')
  }, [otpRequired])

  // focus input after isUiActionPending clears and error state is present
  // this is cleaner than setTimeout()/requestAnimationFrame() workarounds
  useEffect(() => {
    if (!isUiActionPending && usernameError) {
      usernameInputRef.current?.focus()
    }
  }, [isUiActionPending, usernameError])

  const validateForm = (): boolean => {
    let hasValidationError = false
    let focusTarget: HTMLInputElement | null = null

    setUsernameError('')
    setPasswordError('')

    if (username.trim() === '') {
      setUsernameError(
        I18n.t('Please enter your %{loginHandleName}.', {
          loginHandleName: loginHandleName?.toLowerCase(),
        }),
      )
      focusTarget = usernameInputRef.current
      hasValidationError = true
    }

    if (password.trim() === '') {
      setPasswordError(I18n.t('Please enter your password.'))
      if (!focusTarget) focusTarget = passwordInputRef.current
      hasValidationError = true
    }

    if (focusTarget) focusTarget.focus()

    return !hasValidationError
  }

  const handleFailedLogin = () => {
    setPasswordError('')
    setPassword('')
    setUsernameError(I18n.t('Please verify your email and password and try again.'))
    // focus set in useEffect above …
  }

  const handleLogin = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (isDisabled) return

    if (!validateForm()) return

    setIsUiActionPending(true)

    try {
      const loginApiEndpoint = windowPathname().startsWith(ROUTES.LDAP)
        ? ROUTES.LDAP
        : ROUTES.SIGN_IN
      const response = await performSignIn(username, password, rememberMe, loginApiEndpoint)

      if (response.status === 200) {
        if (response.data?.otp_required) {
          setOtpRequired(true)
        } else if (response.data?.location) {
          isRedirectingRef.current = true
          // location is always present for successful logins, including:
          // standard logins, cross-account redirects, OAuth flows,
          // course-based logins, and registration confirmations
          assignLocation(response.data.location)
        } else {
          handleFailedLogin()
        }
      }
    } catch (error: any) {
      if (error.response?.status === 400) {
        handleFailedLogin()
      } else {
        showFlashError(I18n.t('Something went wrong. Please try again later.'))(error)
      }
    } finally {
      if (!isRedirectingRef.current) setIsUiActionPending(false)
    }
  }

  const handleUsernameChange = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setUsername(value.trim())
  }

  const handlePasswordChange = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setPassword(value.trim())
  }

  if (otpRequired && !isPreviewMode) {
    return <OtpForm />
  }

  return (
    <Flex direction="column" gap="large">
      <Flex direction="column" gap="small">
        <Heading as="h1" level="h2">
          {I18n.t('Welcome to Canvas')}
        </Heading>

        {selfRegistrationType && (
          <Flex.Item data-testid="self-registration-prompt" overflowX="visible" overflowY="visible">
            <ActionPrompt
              variant={
                selfRegistrationType === SelfRegistrationType.ALL
                  ? 'createAccount'
                  : 'createParentAccount'
              }
            />
          </Flex.Item>
        )}
      </Flex>

      <form onSubmit={handleLogin} noValidate={true}>
        <Flex direction="column" gap="large">
          <Flex direction="column" gap="mediumSmall">
            <TextInput
              autoComplete="username"
              autoCapitalize="none"
              disabled={isUiActionPending}
              id="username"
              inputRef={inputElement => (usernameInputRef.current = inputElement)}
              messages={createErrorMessage(usernameError)}
              onChange={handleUsernameChange}
              renderLabel={loginHandleName}
              value={username}
              isRequired={true}
              data-testid="username-input"
            />

            <TextInput
              autoComplete="current-password"
              disabled={isUiActionPending}
              id="password"
              inputRef={inputElement => (passwordInputRef.current = inputElement)}
              messages={createErrorMessage(passwordError)}
              onChange={handlePasswordChange}
              renderLabel={I18n.t('Password')}
              type="password"
              value={password}
              isRequired={true}
              data-testid="password-input"
            />

            <Flex.Item overflowY="visible" overflowX="visible">
              <RememberMeCheckbox />
            </Flex.Item>
          </Flex>

          <Flex direction="column" gap="small">
            <Button
              type="submit"
              color="primary"
              display="block"
              disabled={isUiActionPending}
              data-testid="login-button"
            >
              {I18n.t('Log In')}
            </Button>

            <Flex.Item align="center" overflowX="visible" overflowY="visible">
              <ForgotPasswordLink />
            </Flex.Item>

            {invalidLoginFaqUrl && (
              <Flex.Item align="center" overflowX="visible" overflowY="visible">
                <LoginTroubleLink url={invalidLoginFaqUrl} />
              </Flex.Item>
            )}
          </Flex>
        </Flex>
      </form>

      {authProviders && authProviders.length > 0 && (
        <Flex direction="column" gap="large">
          <SSOButtons />
        </Flex>
      )}
    </Flex>
  )
}

export default SignIn
