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

import React, {useState} from 'react'
import {Button} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {useScope as useI18nScope} from '@canvas/i18n'
import {useNewLogin} from '../context/NewLoginContext'
import {SignInLinks} from '../shared'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {forgotPassword} from '../services'

const I18n = useI18nScope('new_login')

const ForgotPassword = () => {
  const {isUiActionPending, setIsUiActionPending, loginHandleName} = useNewLogin()
  const [email, setEmail] = useState('')
  const [isEmailValid, setIsEmailValid] = useState(false)
  const [emailSent, setEmailSent] = useState(false)
  const [submittedEmail, setSubmittedEmail] = useState('')

  const validateEmail = (value: string) => {
    setIsEmailValid(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim()))
  }

  const handleForgotPassword = async (event: React.FormEvent) => {
    event.preventDefault()

    if (!isEmailValid) {
      showFlashAlert({
        message: I18n.t('Please enter your email address.'),
        type: 'error',
      })
      return
    }

    setIsUiActionPending(true)

    try {
      const response = await forgotPassword(email)

      if (response.status === 200 && response.data?.requested) {
        setSubmittedEmail(email)
        setEmail('')
        setIsEmailValid(false)
        setEmailSent(true)

        showFlashAlert({
          message: I18n.t('Password recovery email successfully sent.', {email}),
          type: 'success',
        })
      } else {
        showFlashAlert({
          message: I18n.t('No account found for this email address.'),
          type: 'warning',
        })
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

  const handleEmailChange = (_: any, value: string) => {
    setEmail(value)
    validateEmail(value)
  }

  const passwordRecoveryForm = (
    <>
      <Flex.Item overflowY="visible">
        <p>
          {I18n.t(
            'Enter your %{loginHandleName} and we’ll send you a link to change your password.',
            {loginHandleName}
          )}
        </p>
      </Flex.Item>

      <Flex.Item overflowY="visible">
        <form onSubmit={handleForgotPassword}>
          <Flex direction="column" gap="large">
            <Flex.Item overflowY="visible">
              <TextInput
                id="email"
                renderLabel={loginHandleName}
                type="email"
                value={email}
                onChange={handleEmailChange}
                autoComplete="email"
                aria-describedby="emailHelp"
              />
            </Flex.Item>

            <Flex.Item overflowY="visible">
              <Flex direction="column" gap="small">
                <Flex.Item overflowY="visible">
                  <Button
                    type="submit"
                    color="primary"
                    display="block"
                    disabled={!isEmailValid || isUiActionPending}
                  >
                    {I18n.t('Submit')}
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
    </>
  )

  const confirmationMessage = (
    <>
      <Flex.Item overflowY="visible">
        <p>
          {I18n.t(
            'A recovery email has been sent to %{email}. Please check your inbox and follow the instructions to reset your password. This may take up to 30 minutes. If you don’t receive an email, be sure to check your spam folder.',
            {email: submittedEmail}
          )}
        </p>
      </Flex.Item>

      <Flex.Item overflowY="visible">
        <SignInLinks />
      </Flex.Item>
    </>
  )

  return (
    <Flex direction="column" gap="large">
      <Flex.Item overflowY="visible">
        <Heading level="h2" as="h1">
          {I18n.t('Forgot Password')}
        </Heading>
      </Flex.Item>

      {emailSent ? confirmationMessage : passwordRecoveryForm}
    </Flex>
  )
}

export default ForgotPassword
