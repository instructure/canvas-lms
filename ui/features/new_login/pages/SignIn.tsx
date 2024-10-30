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

import OtpForm from '../shared/OtpForm'
import React, {useCallback, useEffect, useState} from 'react'
import SSOButtons from '../shared/SSOButtons'
import SignInLinks from '../shared/SignInLinks'
import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
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
    setRememberMe,
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
  const [formValid, setFormValid] = useState(false)

  const validateForm = useCallback(() => {
    return username.trim() !== '' && password.trim() !== ''
  }, [username, password])

  useEffect(() => {
    setFormValid(validateForm())
  }, [validateForm])

  const handleLogin = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    if (isPreviewMode) return

    if (!validateForm()) {
      showFlashAlert({
        message: I18n.t('Please enter a username and password.'),
        type: 'error',
      })
      return
    }

    setIsUiActionPending(true)

    try {
      const response = await performSignIn(username, password, rememberMe)

      if (response.status === 200 && response.data?.otp_required) {
        setOtpRequired(true)
      } else if (response.status === 200 && response.data?.pseudonym) {
        window.location.href = response.data.location || '/dashboard'
      } else {
        showFlashAlert({
          message: I18n.t('There was an error logging in. Please try again.'),
          type: 'error',
        })
      }
    } catch (_error: unknown) {
      showFlashAlert({
        message: I18n.t('There was an error logging in. Please try again.'),
        type: 'error',
      })
    } finally {
      setIsUiActionPending(false)
    }
  }

  const handleUsernameChange = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    if (isPreviewMode) return
    setUsername(value)
  }

  const handlePasswordChange = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    if (isPreviewMode) return
    setPassword(value)
  }

  if (otpRequired && !isPreviewMode) {
    return <OtpForm />
  }

  return (
    <Flex direction="column" gap="large">
      <Flex.Item overflowY="visible">
        <Heading level="h2" as="h1">
          {I18n.t('Welcome to Canvas LMS')}
        </Heading>
      </Flex.Item>

      {authProviders && authProviders.length > 0 && (
        <Flex.Item overflowY="visible">
          <Flex direction="column" gap="large">
            <Flex.Item overflowY="visible">
              <SSOButtons />
            </Flex.Item>

            <Flex.Item overflowY="visible">
              <View as="hr" borderWidth="small none none none" margin="small none" />
            </Flex.Item>
          </Flex>
        </Flex.Item>
      )}

      <Flex.Item overflowY="visible">
        <form onSubmit={handleLogin}>
          <Flex direction="column" gap="large">
            <Flex.Item overflowY="visible">
              <Flex direction="column" gap="small">
                <Flex.Item overflowY="visible">
                  <TextInput
                    id="username"
                    renderLabel={loginHandleName}
                    type="text"
                    value={username}
                    onChange={handleUsernameChange}
                    autoComplete="username"
                    disabled={isUiActionPending}
                  />
                </Flex.Item>

                <Flex.Item overflowY="visible">
                  <TextInput
                    id="password"
                    renderLabel={I18n.t('Password')}
                    type="password"
                    value={password}
                    onChange={handlePasswordChange}
                    autoComplete="current-password"
                    disabled={isUiActionPending}
                  />
                </Flex.Item>

                <Flex.Item overflowY="visible">
                  <Checkbox
                    label={I18n.t('Stay signed in')}
                    checked={rememberMe}
                    onChange={() => setRememberMe(!rememberMe)}
                    inline={true}
                    disabled={isUiActionPending}
                  />
                </Flex.Item>
              </Flex>
            </Flex.Item>

            <Flex.Item overflowY="visible">
              <Flex direction="column" gap="small">
                <Flex.Item overflowY="visible">
                  <Button
                    type="submit"
                    color="primary"
                    display="block"
                    disabled={!formValid || isUiActionPending}
                  >
                    {I18n.t('Sign In')}
                  </Button>
                </Flex.Item>

                <Flex.Item overflowY="visible" align="center">
                  <SignInLinks />
                </Flex.Item>
              </Flex>
            </Flex.Item>
          </Flex>
        </form>
      </Flex.Item>
    </Flex>
  )
}

export default SignIn
