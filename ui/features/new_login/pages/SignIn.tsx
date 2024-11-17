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

import React, {useEffect, useRef, useState} from 'react'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {OtpForm, RememberMeCheckbox, SignInLinks, SSOButtons} from '../shared'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {performSignIn} from '../services'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useNewLogin} from '../context/NewLoginContext'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('new_login')

const SignIn = () => {
  const {
    rememberMe,
    isUiActionPending,
    setIsUiActionPending,
    otpRequired,
    setOtpRequired,
    loginHandleName,
    authProviders,
    isPreviewMode,
  } = useNewLogin()

  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [usernameError, setUsernameError] = useState('')
  const [passwordError, setPasswordError] = useState('')
  const isRedirectingRef = useRef(false)

  const usernameInputRef = useRef<HTMLInputElement | undefined>(undefined)
  const passwordInputRef = useRef<HTMLInputElement | undefined>(undefined)

  useEffect(() => {
    setUsername('')
    setPassword('')
    setUsernameError('')
    setPasswordError('')
  }, [otpRequired])

  useEffect(() => {
    if (usernameError) {
      usernameInputRef.current?.focus()
    } else if (passwordError) {
      passwordInputRef.current?.focus()
    }
  }, [usernameError, passwordError])

  const validateForm = (): boolean => {
    setUsernameError('')
    setPasswordError('')

    let formIsValid = true
    if (username.trim() === '') {
      setUsernameError(I18n.t('Please enter your %{loginHandleName}', {loginHandleName}))
      formIsValid = false
    }
    if (password.trim() === '' && formIsValid) {
      setPasswordError(I18n.t('Please enter your password'))
      formIsValid = false
    }
    return formIsValid
  }

  const handleFailedLogin = () => {
    setUsernameError(
      I18n.t('Please verify your %{loginHandleName} and password and try again', {loginHandleName})
    )
    setPassword('')
  }

  const handleLogin = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (isPreviewMode || isUiActionPending) return

    if (!validateForm()) return

    setIsUiActionPending(true)

    try {
      const response = await performSignIn(username, password, rememberMe)

      if (response.status === 200) {
        if (response.data?.otp_required) {
          setOtpRequired(true)
        } else if (response.data?.pseudonym) {
          isRedirectingRef.current = true
          window.location.replace(response.data.location || '/dashboard')
          return
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
    if (usernameError) setUsernameError('')
  }

  const handlePasswordChange = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setPassword(value.trim())
    if (passwordError) setPasswordError('')
  }

  if (otpRequired && !isPreviewMode) {
    return <OtpForm />
  }

  return (
    <Flex direction="column" gap="large">
      <Heading as="h1" level="h2">
        {I18n.t('Welcome to Canvas')}
      </Heading>

      {authProviders && authProviders.length > 0 && (
        <Flex direction="column" gap="large">
          <SSOButtons />
          <View as="hr" borderWidth="small none none none" margin="small none" />
        </Flex>
      )}

      <form onSubmit={handleLogin} noValidate={true}>
        <Flex direction="column" gap="large">
          <Flex direction="column" gap="mediumSmall">
            <TextInput
              id="username"
              inputRef={inputElement => {
                usernameInputRef.current = inputElement as HTMLInputElement | undefined
              }}
              renderLabel={loginHandleName}
              value={username}
              onChange={handleUsernameChange}
              autoComplete="username"
              disabled={isUiActionPending}
              messages={usernameError ? [{type: 'error', text: usernameError}] : []}
            />

            <TextInput
              id="password"
              inputRef={inputElement => {
                passwordInputRef.current = inputElement as HTMLInputElement | undefined
              }}
              renderLabel={I18n.t('Password')}
              type="password"
              value={password}
              onChange={handlePasswordChange}
              autoComplete="current-password"
              disabled={isUiActionPending}
              messages={passwordError ? [{type: 'error', text: passwordError}] : []}
            />

            <Flex.Item overflowY="visible" overflowX="visible">
              <RememberMeCheckbox />
            </Flex.Item>
          </Flex>

          <Flex direction="column" gap="mediumSmall">
            <Button type="submit" color="primary" display="block" disabled={isUiActionPending}>
              {I18n.t('Log In')}
            </Button>

            <Flex.Item align="center">
              <SignInLinks />
            </Flex.Item>
          </Flex>
        </Flex>
      </form>
    </Flex>
  )
}

export default SignIn
