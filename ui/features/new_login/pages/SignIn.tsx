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

import React, {useEffect, useState} from 'react'
import {Button} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import SSOButtons from '../partials/SSOButtons'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Checkbox} from '@instructure/ui-checkbox'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoginLinks from '../partials/LoginLinks'
import {useNewLoginData} from '../hooks/useNewLoginData'
import {login} from '../utils/api'
import type {LoginResponse} from '../utils/types'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('new_login')

const SignIn = () => {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [rememberMe, setRememberMe] = useState(false)
  const [formValid, setFormValid] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const {authProviders, loginHandleName} = useNewLoginData()

  useEffect(() => {
    const isUsernameValid = username.trim() !== ''
    const isPasswordValid = password.trim() !== ''
    setFormValid(isUsernameValid && isPasswordValid)
  }, [username, password])

  const handleLogin = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    if (!formValid) {
      showFlashAlert({
        message: I18n.t('Please enter a username and password.'),
        type: 'error',
      })
      return
    }

    setIsSubmitting(true)

    try {
      const data: LoginResponse = await login(username, password, rememberMe)
      window.location.href = data.location
    } catch (error: any) {
      showFlashAlert({
        message: error.message || I18n.t('There was an error logging in. Please try again.'),
        type: 'error',
      })
      setIsSubmitting(false)
    }
  }

  const handleUsernameChange = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setUsername(value)
  }

  const handlePasswordChange = (_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setPassword(value)
  }

  return (
    <Flex direction="column" gap="large">
      <Flex.Item overflowY="visible">
        <Heading level="h2" as="h1">
          {I18n.t('Welcome to Canvas')}
        </Heading>
      </Flex.Item>

      {authProviders.length > 0 && (
        <Flex.Item overflowY="visible">
          <Flex direction="column" gap="large">
            <Flex.Item overflowY="visible">
              <SSOButtons providers={authProviders} />
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
                  />
                </Flex.Item>

                <Flex.Item overflowY="visible">
                  <Checkbox
                    label={I18n.t('Stay signed in')}
                    checked={rememberMe}
                    onChange={() => setRememberMe(!rememberMe)}
                  />
                </Flex.Item>
              </Flex>
            </Flex.Item>

            <Flex.Item overflowY="visible">
              <Button
                type="submit"
                color="primary"
                display="block"
                disabled={!formValid || isSubmitting}
              >
                {I18n.t('Sign In')}
              </Button>
            </Flex.Item>

            <Flex.Item overflowY="visible">
              <LoginLinks />
            </Flex.Item>
          </Flex>
        </form>
      </Flex.Item>
    </Flex>
  )
}

export default SignIn
