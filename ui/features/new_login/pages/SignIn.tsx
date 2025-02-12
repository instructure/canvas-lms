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

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'
import {replaceLocation} from '@canvas/util/globalUtils'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import React, {useEffect, useRef, useState} from 'react'
import {useNewLogin, useNewLoginData} from '../context'
import {performSignIn} from '../services'
import {ActionPrompt, RememberMeCheckbox, SSOButtons, SignInLinks} from '../shared'
import LoginAlert from '../shared/LoginAlert'
import {createErrorMessage} from '../shared/helpers'
import {SelfRegistrationType} from '../types'
import OtpForm from './OtpForm'

const I18n = createI18nScope('new_login')

const SignIn = () => {
  const {isUiActionPending, setIsUiActionPending, otpRequired, setOtpRequired, rememberMe} =
    useNewLogin()
  const {authProviders, invalidLoginFaqUrl, isPreviewMode, selfRegistrationType, loginHandleName} =
    useNewLoginData()

  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [usernameError, setUsernameError] = useState('')
  const [passwordError, setPasswordError] = useState('')
  const [loginFailed, setLoginFailed] = useState(false)

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

  const validateForm = (): boolean => {
    setUsernameError('')
    setPasswordError('')

    if (username.trim() === '') {
      setUsernameError(I18n.t('Please enter your %{loginHandleName}', {loginHandleName}))
      usernameInputRef.current?.focus()
      return false
    }

    if (password.trim() === '') {
      setPasswordError(I18n.t('Please enter your password'))
      passwordInputRef.current?.focus()
      return false
    }

    return true
  }

  const handleFailedLogin = () => {
    setPassword('')
    setLoginFailed(true)
  }

  const handleLogin = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (isDisabled) return

    if (!validateForm()) return

    setIsUiActionPending(true)

    try {
      const response = await performSignIn(username, password, rememberMe)

      if (response.status === 200) {
        if (response.data?.otp_required) {
          setOtpRequired(true)
        } else if (response.data?.pseudonym) {
          isRedirectingRef.current = true
          document.location.href = response.data.location || '/dashboard'
        } else {
          handleFailedLogin()
        }
      }
    } catch (error: any) {
      if (error.response?.status === 400) {
        handleFailedLogin()
      } else {
        showFlashAlert({
          message: I18n.t('There was an error logging in. Please try again.'),
          type: 'error',
        })
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

  const handleAlertDismiss = () => {
    setLoginFailed(false)
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
          <Flex.Item overflowX="visible" overflowY="visible">
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

      {authProviders && authProviders.length > 0 && (
        <Flex direction="column" gap="large">
          <SSOButtons />
          <View as="hr" borderWidth="small none none none" margin="small none" />
        </Flex>
      )}

      {loginFailed && (
        <LoginAlert
          invalidLoginFaqUrl={invalidLoginFaqUrl ?? null}
          onClose={handleAlertDismiss}
          loginHandleName={loginHandleName || ''}
        />
      )}

      <form onSubmit={handleLogin} noValidate={true}>
        <Flex direction="column" gap="large">
          <Flex direction="column" gap="mediumSmall">
            <TextInput
              autoComplete="username"
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

          <Flex direction="column" gap="mediumSmall">
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
              <SignInLinks />
            </Flex.Item>
          </Flex>
        </Flex>
      </form>
    </Flex>
  )
}

export default SignIn
