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

import React, {useRef, useState} from 'react'
import {Button} from '@instructure/ui-buttons'
import {EMAIL_REGEX, ROUTES} from '../shared'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {createErrorMessage} from '../shared/helpers'
import {forgotPassword} from '../services'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useNavigate} from 'react-router-dom'
import {useNewLogin} from '../context/NewLoginContext'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('new_login')

const ForgotPassword = () => {
  const {isUiActionPending, setIsUiActionPending, loginHandleName} = useNewLogin()
  const navigate = useNavigate()

  const [email, setEmail] = useState('')
  const [emailError, setEmailError] = useState('')
  const [emailSent, setEmailSent] = useState(false)
  const [submittedEmail, setSubmittedEmail] = useState('')

  const emailInputRef = useRef<HTMLInputElement | null>(null)

  const validateForm = (): boolean => {
    if (!EMAIL_REGEX.test(email)) {
      setEmailError(I18n.t('Please enter a valid %{loginHandleName} address.', {loginHandleName}))
      emailInputRef.current?.focus()
      return false
    } else {
      setEmailError('')
    }

    return true
  }

  const handleForgotPassword = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    if (isUiActionPending || !validateForm()) return

    setIsUiActionPending(true)

    try {
      const response = await forgotPassword(email)

      if (response.status === 200 && response.data?.requested) {
        setSubmittedEmail(email)
        setEmail('')
        setEmailSent(true)
      } else {
        setEmailError(I18n.t('No account found for this email address'))
        emailInputRef.current?.focus()
      }
    } catch (_error: unknown) {
      showFlashAlert({
        message: I18n.t('Something went wrong. Please try again later.'),
        type: 'error',
      })
    } finally {
      setIsUiActionPending(false)
    }
  }

  const handleEmailChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setEmail(value.trim())
    if (emailError) {
      setEmailError('')
    }
  }

  const handleEmailBlur = () => {
    if (!email) {
      setEmailError('')
    } else if (!EMAIL_REGEX.test(email)) {
      setEmailError(I18n.t('Please enter a valid %{loginHandleName}', {loginHandleName}))
    } else {
      setEmailError('')
    }
  }

  const handleCancel = () => {
    navigate(ROUTES.SIGN_IN)
  }

  const passwordRecoveryForm = (
    <>
      <Flex direction="column" gap="small">
        <Heading as="h1" level="h2">
          {I18n.t('Forgot your password?')}
        </Heading>

        <Text>
          {I18n.t(
            'Enter your %{loginHandleName} and we’ll send you a link to change your password.',
            {loginHandleName}
          )}
        </Text>
      </Flex>

      <form onSubmit={handleForgotPassword} noValidate={true}>
        <Flex direction="column" gap="large">
          <TextInput
            aria-describedby="emailHelp"
            autoComplete="email"
            disabled={isUiActionPending}
            id="email"
            inputRef={inputElement => (emailInputRef.current = inputElement)}
            messages={createErrorMessage(emailError)}
            onBlur={handleEmailBlur}
            onChange={handleEmailChange}
            renderLabel={loginHandleName}
            type="email"
            value={email}
          />

          <Flex direction="row" gap="small">
            <Button
              color="secondary"
              display="block"
              onClick={handleCancel}
              disabled={isUiActionPending}
            >
              {I18n.t('Back to Login')}
            </Button>

            <Button type="submit" color="primary" display="block" disabled={isUiActionPending}>
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
        <Heading as="h1" level="h2">
          {I18n.t('Check your email')}
        </Heading>

        <Text>
          {I18n.t(
            'A recovery email has been sent to %{email}. Please check your inbox and follow the instructions to reset your password. This may take up to 10 minutes. If you don’t receive an email, be sure to check your spam folder.',
            {email: submittedEmail}
          )}
        </Text>
      </Flex>

      <Button color="secondary" display="block" onClick={handleCancel}>
        {I18n.t('Back to login')}
      </Button>
    </>
  )

  return (
    <Flex direction="column" gap="large">
      {emailSent ? confirmationMessage : passwordRecoveryForm}
    </Flex>
  )
}

export default ForgotPassword
