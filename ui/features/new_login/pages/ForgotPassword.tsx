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
import {useScope as useI18nScope} from '@canvas/i18n'
import LoginLinks from '../partials/LoginLinks'
import {forgotPassword} from '../utils/api'
import {Heading} from '@instructure/ui-heading'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('new_login')

const ForgotPassword = () => {
  const [email, setEmail] = useState('')
  const [isEmailValid, setIsEmailValid] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)

  const validateEmail = (value: string) => {
    const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    setIsEmailValid(emailPattern.test(value.trim()))
  }

  const handleForgotPassword = async (event: React.FormEvent) => {
    event.preventDefault()

    if (!isEmailValid) {
      showFlashAlert({
        message: I18n.t('Please enter a valid email address.'),
        type: 'error',
      })
      return
    }

    setIsSubmitting(true)

    try {
      const {requested} = await forgotPassword(email)
      if (requested) {
        showFlashAlert({
          message: I18n.t('A recovery email has been sent. Please check your inbox.'),
          type: 'success',
        })
        setEmail('')
      } else {
        showFlashAlert({
          message: I18n.t('No account found for this email.'),
          type: 'error',
        })
      }
    } catch (error: any) {
      showFlashAlert({
        message: I18n.t('An error occurred, please try again later.'),
        type: 'error',
      })
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleEmailChange = (_: any, value: string) => {
    setEmail(value)
    validateEmail(value)
  }

  return (
    <Flex direction="column" gap="large">
      <Flex.Item overflowY="visible">
        <Heading level="h2" as="h1">
          {I18n.t('Forgot Password')}
        </Heading>
      </Flex.Item>

      <Flex.Item overflowY="visible">
        <p>{I18n.t("Enter your Email and we'll send you a link to change your password.")}</p>
      </Flex.Item>

      <Flex.Item overflowY="visible">
        <form onSubmit={handleForgotPassword}>
          <Flex direction="column" gap="large">
            <Flex.Item overflowY="visible">
              <TextInput
                id="email"
                renderLabel={I18n.t('Email')}
                type="email"
                value={email}
                onChange={handleEmailChange}
                autoComplete="email"
              />
            </Flex.Item>

            <Flex.Item overflowY="visible">
              <Button
                type="submit"
                color="primary"
                display="block"
                disabled={!isEmailValid || isSubmitting}
              >
                {I18n.t('Submit')}
              </Button>
            </Flex.Item>
          </Flex>
        </form>
      </Flex.Item>

      <Flex.Item overflowY="visible">
        <LoginLinks />
      </Flex.Item>
    </Flex>
  )
}

export default ForgotPassword
