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
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Focusable} from '@instructure/ui-focusable'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import React, {useEffect, useRef, useState} from 'react'
import {useNewLogin, useNewLoginData} from '../context'
import {forgotPassword} from '../services'
import {createErrorMessage} from '../shared/helpers'
import {assignLocation} from '@canvas/util/globalUtils'
import {LOGIN_ENTRY_URL} from '../routes/routes'

const I18n = createI18nScope('new_login')

const ForgotPassword = () => {
  const {isUiActionPending, setIsUiActionPending} = useNewLogin()
  const {loginHandleName} = useNewLoginData()

  const [username, setUsername] = useState('')
  const [usernameError, setUsernameError] = useState('')
  const [confirmationSent, setConfirmationSent] = useState(false)
  const [submittedUsername, setSubmittedUsername] = useState('')

  const usernameInputRef = useRef<HTMLInputElement | null>(null)

  const confirmationHeadingRef = useRef<HTMLHeadingElement | null>(null)
  useEffect(() => {
    if (confirmationSent) {
      confirmationHeadingRef.current?.focus()
    }
  }, [confirmationSent])

  const validateForm = (): boolean => {
    setUsernameError('')

    if (username.trim() === '') {
      setUsernameError(
        I18n.t('Please enter your %{loginHandleName}.', {
          loginHandleName: loginHandleName?.toLowerCase(),
        }),
      )
      usernameInputRef.current?.focus()
      return false
    }

    return true
  }

  const handleForgotPassword = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    if (isUiActionPending || !validateForm()) return

    setIsUiActionPending(true)

    try {
      const response = await forgotPassword(username)

      if (response.status === 200 && response.data?.requested) {
        setSubmittedUsername(username)
        setUsername('')
        setConfirmationSent(true)
      } else {
        setUsernameError(
          I18n.t('No account found for this %{loginHandleName}.', {
            loginHandleName: loginHandleName?.toLowerCase(),
          }),
        )
        usernameInputRef.current?.focus()
      }
    } catch (error: any) {
      showFlashError(I18n.t('Something went wrong. Please try again later.'))(error)
    } finally {
      setIsUiActionPending(false)
    }
  }

  const handleUsernameChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setUsername(value)
  }

  const handleCancel = () => assignLocation(LOGIN_ENTRY_URL)

  const passwordRecoveryForm = (
    <>
      <Flex direction="column" gap="small">
        <Heading as="h1" level="h2">
          {I18n.t('Forgot password?')}
        </Heading>

        <Text>
          {I18n.t(
            'Enter your %{loginHandleName} and we’ll send you a link to change your password.',
            {loginHandleName: loginHandleName?.toLowerCase()},
          )}
        </Text>
      </Flex>

      <form onSubmit={handleForgotPassword} noValidate={true}>
        <Flex direction="column" gap="large">
          <TextInput
            autoComplete="username"
            data-testid="username-input"
            disabled={isUiActionPending}
            id="username"
            inputRef={inputElement => (usernameInputRef.current = inputElement)}
            isRequired={true}
            messages={createErrorMessage(usernameError)}
            onChange={handleUsernameChange}
            renderLabel={loginHandleName}
            type="text"
            value={username}
          />

          <Flex direction="row" gap="small">
            <Button
              color="secondary"
              display="block"
              onClick={handleCancel}
              disabled={isUiActionPending}
              data-testid="cancel-button"
            >
              {I18n.t('Back')}
            </Button>

            <Button
              type="submit"
              color="primary"
              display="block"
              disabled={isUiActionPending}
              data-testid="submit-button"
            >
              {I18n.t('Next')}
            </Button>
          </Flex>
        </Flex>
      </form>
    </>
  )

  const confirmationMessage = (
    <>
      <Flex direction="column" gap="small">
        <Focusable>
          {({attachRef}) => (
            <Heading
              as="h1"
              data-testid="confirmation-heading"
              elementRef={el => {
                attachRef(el)
                confirmationHeadingRef.current = el as HTMLHeadingElement | null
              }}
              level="h2"
              tabIndex={-1}
            >
              {I18n.t('Check Your Email')}
            </Heading>
          )}
        </Focusable>

        <Text data-testid="confirmation-message">
          {I18n.t(
            'A recovery email has been sent to %{username}. Please check your inbox and follow the instructions to reset your password. This may take up to 10 minutes. If you don’t receive an email, be sure to check your spam folder.',
            {username: submittedUsername},
          )}
        </Text>
      </Flex>

      <Button
        color="secondary"
        display="block"
        onClick={handleCancel}
        data-testid="confirmation-back-button"
      >
        {I18n.t('Back')}
      </Button>
    </>
  )

  return (
    <Flex direction="column" gap="large">
      {confirmationSent ? confirmationMessage : passwordRecoveryForm}
    </Flex>
  )
}

export default ForgotPassword
