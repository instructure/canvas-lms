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
import type {ReCaptchaSectionRef} from '../../shared/recaptcha/ReCaptchaSection'
import {ActionPrompt, TermsAndPolicyCheckbox} from '../../shared'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {ROUTES} from '../../routes/routes'
import {ReCaptchaSection} from '../../shared/recaptcha'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {createErrorMessage, EMAIL_REGEX, handleRegistrationRedirect} from '../../shared/helpers'
import {createTeacherAccount} from '../../services'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useNavigate} from 'react-router-dom'
import {useNewLogin} from '../../context/NewLoginContext'
import {useScope as useI18nScope} from '@canvas/i18n'
import {useServerErrorsMap} from '../../hooks/useServerErrorsMap'

const I18n = useI18nScope('new_login')

const ERROR_MESSAGES = {
  invalidEmail: I18n.t('Please enter a valid email address.'),
  nameRequired: I18n.t('Name is required.'),
  termsRequired: I18n.t('You must accept the terms to create an account.'),
}

const Teacher = () => {
  const {
    isUiActionPending,
    setIsUiActionPending,
    passwordPolicy,
    privacyPolicyUrl,
    recaptchaKey,
    termsOfUseUrl,
    termsRequired,
  } = useNewLogin()
  const serverErrorsMap = useServerErrorsMap(passwordPolicy)
  const navigate = useNavigate()

  const [email, setEmail] = useState('')
  const [emailError, setEmailError] = useState('')
  const [name, setName] = useState('')
  const [nameError, setNameError] = useState('')
  const [termsAccepted, setTermsAccepted] = useState(false)
  const [termsError, setTermsError] = useState('')

  const isRedirectingRef = useRef(false)
  const emailInputRef = useRef<HTMLInputElement | null>(null)
  const nameInputRef = useRef<HTMLInputElement | null>(null)

  const [captchaToken, setCaptchaToken] = useState<string | null>(null)
  const recaptchaSectionRef = useRef<ReCaptchaSectionRef>(null)

  const validateForm = (): boolean => {
    setEmailError('')
    setNameError('')
    setTermsError('')

    if (!EMAIL_REGEX.test(email)) {
      setEmailError(ERROR_MESSAGES.invalidEmail)
      emailInputRef.current?.focus()
      return false
    }

    if (name.trim() === '') {
      setNameError(ERROR_MESSAGES.nameRequired)
      nameInputRef.current?.focus()
      return false
    }

    if (termsRequired && !termsAccepted) {
      setTermsError(ERROR_MESSAGES.termsRequired)
      const checkbox = document.getElementById('terms-checkbox') as HTMLInputElement
      checkbox?.focus()
      return false
    }

    if (recaptchaKey) {
      const recaptchaValid = recaptchaSectionRef.current?.validate() ?? true
      if (!recaptchaValid) return false
    }

    return true
  }

  const handleServerErrors = (errors: any) => {
    let hasFocusedError = false

    setEmailError('')
    setNameError('')
    setTermsError('')

    // email address
    if (errors.pseudonym?.unique_id?.length) {
      const errorKey = `pseudonym.unique_id.${errors.pseudonym.unique_id[0]?.type}`
      setEmailError(serverErrorsMap[errorKey] || I18n.t('An unknown error occurred.'))

      if (!hasFocusedError) {
        emailInputRef.current?.focus()
        hasFocusedError = true
      }
    }

    // full name
    if (errors.user?.name?.length) {
      const errorKey = `user.name.${errors.user.name[0]?.type}`
      setNameError(serverErrorsMap[errorKey] || I18n.t('An unknown error occurred.'))

      if (!hasFocusedError) {
        nameInputRef.current?.focus()
        hasFocusedError = true
      }
    }

    // terms of use
    if (errors.user?.terms_of_use?.length) {
      const errorKey = `user.terms_of_use.${errors.user.terms_of_use[0]?.type}`
      setTermsError(serverErrorsMap[errorKey] || I18n.t('An unknown error occurred.'))

      if (!hasFocusedError) {
        const checkbox = document.getElementById('terms-checkbox') as HTMLInputElement
        checkbox?.focus()
        hasFocusedError = true
      }
    }

    // reCAPTCHA
    if (recaptchaKey && errors.recaptcha) {
      recaptchaSectionRef.current?.validate()
      if (!hasFocusedError) {
        // TODO: handle reCAPTCHA errors …
      }
    }
  }

  const handleCreateTeacher = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    // comment out if you want to test server errors
    if (isUiActionPending || !validateForm()) return

    setIsUiActionPending(true)

    try {
      const response = await createTeacherAccount({
        name,
        email,
        termsAccepted,
        captchaToken: captchaToken ?? undefined,
      })

      if (response.status === 200) {
        isRedirectingRef.current = true
        handleRegistrationRedirect(response.data)
      } else {
        showFlashAlert({
          message: I18n.t('Something went wrong. Please try again later.'),
          type: 'error',
        })
      }
    } catch (error: any) {
      if (error.response) {
        const errorJson = await error.response.json()
        if (errorJson.errors) {
          setIsUiActionPending(false)
          // allow fields to re-enable before processing server errors
          setTimeout(() => handleServerErrors(errorJson.errors), 0)
        } else {
          showFlashAlert({
            message: I18n.t('Something went wrong. Please try again later.'),
            type: 'error',
          })
        }
      } else {
        showFlashAlert({
          message: I18n.t('Something went wrong. Please try again later.'),
          type: 'error',
        })
      }
    } finally {
      if (!isRedirectingRef.current) setIsUiActionPending(false)
    }
  }

  const handleEmailChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setEmail(value.trim())
  }

  const handleNameChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setName(value)
  }

  const handleTermsChange = (checked: boolean) => {
    setTermsAccepted(checked)
  }

  const handleCancel = () => {
    navigate(ROUTES.SIGN_IN)
  }

  const handleReCaptchaVerify = (token: string | null) => {
    // eslint-disable-next-line no-console
    if (!token) console.error('Failed to get a valid reCAPTCHA token')
    setCaptchaToken(token)
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
                id="terms-checkbox"
                isDisabled={isUiActionPending}
                messages={createErrorMessage(termsError)}
                onChange={handleTermsChange}
                privacyPolicyUrl={privacyPolicyUrl}
                termsOfUseUrl={termsOfUseUrl}
              />
            </Flex.Item>
          )}

          {recaptchaKey && (
            <Flex justifyItems="center">
              <ReCaptchaSection
                ref={recaptchaSectionRef}
                recaptchaKey={recaptchaKey}
                onVerify={handleReCaptchaVerify}
              />
            </Flex>
          )}

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

      <Flex.Item align="center" overflowX="visible" overflowY="visible">
        <ActionPrompt variant="signIn" />
      </Flex.Item>
    </Flex>
  )
}

export default Teacher
