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
import {ActionPrompt, EMAIL_REGEX, ROUTES, TermsAndPolicyCheckbox} from '../../shared'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {createErrorMessage, handleRegistrationRedirect} from '../../shared/helpers'
import {createTeacherAccount} from '../../services'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useNavigate} from 'react-router-dom'
import {useNewLogin} from '../../context/NewLoginContext'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('new_login')

const Teacher = () => {
  const {
    isUiActionPending,
    privacyPolicyUrl,
    recaptchaKey,
    setIsUiActionPending,
    termsOfUseUrl,
    termsRequired,
  } = useNewLogin()
  const navigate = useNavigate()

  const [email, setEmail] = useState('')
  const [emailError, setEmailError] = useState('')
  const [name, setName] = useState('')
  const [nameError, setNameError] = useState('')
  const [termsAccepted, setTermsAccepted] = useState(false)
  const [termsError, setTermsError] = useState('')

  const emailInputRef = useRef<HTMLInputElement | null>(null)
  const nameInputRef = useRef<HTMLInputElement | null>(null)

  const validateForm = (): boolean => {
    if (!EMAIL_REGEX.test(email)) {
      setEmailError(I18n.t('Please enter a valid email address.'))
      emailInputRef.current?.focus()
      return false
    } else {
      setEmailError('')
    }

    if (name.trim() === '') {
      setNameError(I18n.t('Name is required.'))
      nameInputRef.current?.focus()
      return false
    } else {
      setNameError('')
    }

    if (termsRequired && !termsAccepted) {
      setTermsError(I18n.t('You must accept the terms to create an account.'))
      const checkboxElement = document.querySelector('.terms-checkbox') as HTMLElement
      checkboxElement?.focus()
      return false
    } else {
      setTermsError('')
    }

    return true
  }

  const handleCreateTeacher = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    if (isUiActionPending || !validateForm()) return

    setIsUiActionPending(true)

    try {
      const response = await createTeacherAccount(name, email, termsAccepted)
      if (response.status === 200) {
        handleRegistrationRedirect(response.data)
      } else {
        showFlashAlert({
          message: 'Something went wrong. Please try again later.',
          type: 'error',
        })
      }
    } finally {
      setIsUiActionPending(false)
    }
  }

  const handleNameChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setName(value)
    if (value.trim() !== '' && nameError) {
      setNameError('')
    }
  }

  const handleEmailChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    const trimmedValue = value.trim()
    setEmail(trimmedValue)
    if (emailError) {
      setEmailError('')
    }
  }

  const handleEmailBlur = () => {
    if (!email) {
      setEmailError('')
    } else if (!EMAIL_REGEX.test(email)) {
      setEmailError(I18n.t('Please enter a valid email address.'))
    } else {
      setEmailError('')
    }
  }

  const handleTermsChange = (checked: boolean) => {
    setTermsAccepted(checked)
    if (termsError) setTermsError('')
  }

  const handleCancel = () => {
    navigate(ROUTES.SIGN_IN)
  }

  return (
    <Flex direction="column" gap="large">
      <Flex direction="column" gap="small">
        <Heading as="h1" level="h2">
          {I18n.t('Create a Teacher Account')}
        </Heading>

        <Text>{I18n.t('All fields are required.')}</Text>
      </Flex>

      <form onSubmit={handleCreateTeacher} noValidate={true}>
        <Flex direction="column" gap="large">
          <Flex direction="column" gap="small">
            <TextInput
              autoCapitalize="none"
              autoCorrect="none"
              disabled={isUiActionPending}
              inputRef={inputElement => (emailInputRef.current = inputElement)}
              messages={createErrorMessage(emailError)}
              onBlur={handleEmailBlur}
              onChange={handleEmailChange}
              renderLabel={I18n.t('Email Address')}
              value={email}
            />

            <TextInput
              autoCorrect="none"
              disabled={isUiActionPending}
              inputRef={inputElement => (nameInputRef.current = inputElement)}
              messages={createErrorMessage(nameError)}
              onChange={handleNameChange}
              renderLabel={I18n.t('Full Name')}
              value={name}
            />
          </Flex>

          {termsRequired && (
            <Flex.Item overflowX="visible" overflowY="visible">
              <TermsAndPolicyCheckbox
                checked={termsAccepted}
                className="terms-checkbox"
                isDisabled={isUiActionPending}
                messages={createErrorMessage(termsError)}
                onChange={handleTermsChange}
                privacyPolicyUrl={privacyPolicyUrl}
                termsOfUseUrl={termsOfUseUrl}
              />
            </Flex.Item>
          )}

          {recaptchaKey && <Text>(TODO reCAPTCHA if enabled {recaptchaKey})</Text>}

          <Flex direction="row" gap="small">
            <Button
              color="secondary"
              disabled={isUiActionPending}
              display="block"
              onClick={handleCancel}
            >
              {I18n.t('Back to Login')}
            </Button>

            <Button type="submit" color="primary" display="block" disabled={isUiActionPending}>
              {I18n.t('Next')}
            </Button>
          </Flex>
        </Flex>
      </form>

      <Flex.Item align="center">
        <ActionPrompt variant="signIn" />
      </Flex.Item>
    </Flex>
  )
}

export default Teacher
