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
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import React, {useRef, useState} from 'react'
import {useNewLogin, useNewLoginData} from '../../context'
import {usePasswordValidator, useSafeBackNavigation, useServerErrorsMap} from '../../hooks'
import {ROUTES} from '../../routes/routes'
import {createParentAccount} from '../../services'
import {ActionPrompt, TermsAndPolicyCheckbox} from '../../shared'
import {createErrorMessage, EMAIL_REGEX, handleRegistrationRedirect} from '../../shared/helpers'
import {ReCaptchaSection, ReCaptchaSectionRef} from '../../shared/recaptcha'

const I18n = createI18nScope('new_login')

const ERROR_MESSAGES = {
  invalidEmail: I18n.t('Please enter a valid email address.'),
  passwordRequired: I18n.t('Password is required.'),
  passwordsNotMatch: I18n.t('Passwords do not match.'),
  nameRequired: I18n.t('Name is required.'),
  pairingCodeRequired: I18n.t('Pairing code is required.'),
  termsRequired: I18n.t('You must accept the terms to create an account.'),
}

const Parent = () => {
  const {isUiActionPending, setIsUiActionPending} = useNewLogin()
  const {passwordPolicy, privacyPolicyUrl, recaptchaKey, termsOfUseUrl, termsRequired} =
    useNewLoginData()
  const validatePassword = usePasswordValidator(passwordPolicy)
  const serverErrorsMap = useServerErrorsMap()

  const [confirmPassword, setConfirmPassword] = useState('')
  const [confirmPasswordError, setConfirmPasswordError] = useState('')
  const [email, setEmail] = useState('')
  const [emailError, setEmailError] = useState('')
  const [name, setName] = useState('')
  const [nameError, setNameError] = useState('')
  const [pairingCode, setPairingCode] = useState('')
  const [pairingCodeError, setPairingCodeError] = useState('')
  const [password, setPassword] = useState('')
  const [passwordError, setPasswordError] = useState('')
  const [termsAccepted, setTermsAccepted] = useState(false)
  const [termsError, setTermsError] = useState('')

  const isRedirectingRef = useRef(false)
  const confirmPasswordInputRef = useRef<HTMLInputElement | null>(null)
  const emailInputRef = useRef<HTMLInputElement | null>(null)
  const nameInputRef = useRef<HTMLInputElement | null>(null)
  const pairingCodeInputRef = useRef<HTMLInputElement | null>(null)
  const passwordInputRef = useRef<HTMLInputElement | null>(null)

  const [captchaToken, setCaptchaToken] = useState<string | null>(null)
  const recaptchaSectionRef = useRef<ReCaptchaSectionRef>(null)

  const validateForm = (): boolean => {
    let hasValidationError = false
    let focusTarget: HTMLInputElement | null = null

    setEmailError('')
    setPasswordError('')
    setConfirmPasswordError('')
    setNameError('')
    setPairingCodeError('')
    setTermsError('')

    if (!EMAIL_REGEX.test(email)) {
      setEmailError(ERROR_MESSAGES.invalidEmail)
      focusTarget = emailInputRef.current
      hasValidationError = true
    }

    if (!password) {
      setPasswordError(ERROR_MESSAGES.passwordRequired)
      if (!focusTarget) focusTarget = passwordInputRef.current
      hasValidationError = true
    } else if (passwordPolicy) {
      const errorKey = validatePassword(password)
      if (errorKey) {
        setPasswordError(
          // prefer server error messages for consistency; fallback to a generic message if unmapped
          serverErrorsMap[`pseudonym.password.${errorKey}`]?.() ||
            I18n.t('An unknown error occurred.'),
        )
        if (!focusTarget) focusTarget = passwordInputRef.current
        hasValidationError = true
      }
    }

    if (!confirmPassword || password !== confirmPassword) {
      setConfirmPasswordError(ERROR_MESSAGES.passwordsNotMatch)
      if (!focusTarget) focusTarget = confirmPasswordInputRef.current
      hasValidationError = true
    }

    if (name.trim() === '') {
      setNameError(ERROR_MESSAGES.nameRequired)
      if (!focusTarget) focusTarget = nameInputRef.current
      hasValidationError = true
    }

    if (pairingCode.trim() === '') {
      setPairingCodeError(ERROR_MESSAGES.pairingCodeRequired)
      if (!focusTarget) focusTarget = pairingCodeInputRef.current
      hasValidationError = true
    }

    if (termsRequired && !termsAccepted) {
      setTermsError(ERROR_MESSAGES.termsRequired)
      if (!focusTarget) {
        focusTarget = document.getElementById('terms-checkbox') as HTMLInputElement
      }
      hasValidationError = true
    }

    if (recaptchaKey) {
      const recaptchaValid = recaptchaSectionRef.current?.validate() ?? true
      if (!recaptchaValid) {
        recaptchaSectionRef.current?.focus()
        hasValidationError = true
      }
    }

    if (focusTarget) focusTarget.focus()

    return !hasValidationError
  }

  const handleServerErrors = (errors: any) => {
    let hasFocusedError = false

    setEmailError('')
    setPasswordError('')
    setConfirmPasswordError('')
    setNameError('')
    setPairingCodeError('')
    setTermsError('')

    // email address
    if (errors.pseudonym?.unique_id?.length) {
      const errorKey = `pseudonym.unique_id.${errors.pseudonym.unique_id[0]?.type}`
      setEmailError(serverErrorsMap[errorKey]?.() || I18n.t('An unknown error occurred.'))
      if (!hasFocusedError) {
        emailInputRef.current?.focus()
        hasFocusedError = true
      }
    }

    // password
    if (errors.pseudonym?.password?.length) {
      const errorKey = `pseudonym.password.${errors.pseudonym.password[0]?.type}`
      setPasswordError(serverErrorsMap[errorKey]?.() || I18n.t('An unknown error occurred.'))
      if (!hasFocusedError) {
        passwordInputRef.current?.focus()
        hasFocusedError = true
      }
    }

    // confirm password
    if (errors.pseudonym?.password_confirmation?.length) {
      const errorKey = `pseudonym.password_confirmation.${errors.pseudonym.password_confirmation[0]?.type}`
      setConfirmPasswordError(serverErrorsMap[errorKey]?.() || I18n.t('An unknown error occurred.'))
      if (!hasFocusedError) {
        confirmPasswordInputRef.current?.focus()
        hasFocusedError = true
      }
    }

    // full name
    if (errors.user?.name?.length) {
      const errorKey = `user.name.${errors.user.name[0]?.type}`
      setNameError(serverErrorsMap[errorKey]?.() || I18n.t('An unknown error occurred.'))
      if (!hasFocusedError) {
        nameInputRef.current?.focus()
        hasFocusedError = true
      }
    }

    // student pairing code
    if (errors.pairing_code?.code?.length) {
      const errorKey = `pairing_code.code.${errors.pairing_code.code[0]?.type}`
      setPairingCodeError(serverErrorsMap[errorKey]?.() || I18n.t('An unknown error occurred.'))
      if (!hasFocusedError) {
        pairingCodeInputRef.current?.focus()
        hasFocusedError = true
      }
    }

    // terms of use
    if (errors.user?.terms_of_use?.length) {
      const errorKey = `user.terms_of_use.${errors.user.terms_of_use[0]?.type}`
      setTermsError(serverErrorsMap[errorKey]?.() || I18n.t('An unknown error occurred.'))
      if (!hasFocusedError) {
        const checkbox = document.getElementById('terms-checkbox') as HTMLInputElement
        checkbox?.focus()
        hasFocusedError = true
      }
    }

    // reCAPTCHA
    if (recaptchaKey) {
      recaptchaSectionRef.current?.reset()
      recaptchaSectionRef.current?.validate()
      if (!hasFocusedError) {
        recaptchaSectionRef.current?.focus()
      }
    }
  }

  const handleCreateParent = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    // comment out if you want to test server errors
    if (isUiActionPending || !validateForm()) return

    setIsUiActionPending(true)

    try {
      const response = await createParentAccount({
        name,
        email,
        password,
        confirmPassword,
        pairingCode,
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

  const handleNameChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setName(value)
  }

  const handleEmailChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setEmail(value.trim())
  }

  const handlePasswordChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setPassword(value)
  }

  const handleConfirmPasswordChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setConfirmPassword(value)
  }

  const handlePairingCodeChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setPairingCode(value.trim())
  }

  const handleTermsChange = (checked: boolean) => {
    setTermsAccepted(checked)
  }

  const handleCancel = useSafeBackNavigation(ROUTES.SIGN_IN)

  const handleReCaptchaVerify = (token: string | null) => {
    if (!token) console.error('Failed to get a valid reCAPTCHA token')
    setCaptchaToken(token)
  }

  return (
    <Flex direction="column" gap="large">
      <Flex direction="column" gap="small">
        <Heading as="h1" level="h2">
          {I18n.t('Create a Parent Account')}
        </Heading>

        <Flex.Item overflowX="visible" overflowY="visible">
          <ActionPrompt variant="signIn" />
        </Flex.Item>
      </Flex>

      <form onSubmit={handleCreateParent} noValidate={true}>
        <Flex direction="column" gap="large">
          <Flex direction="column" gap="small">
            <TextInput
              autoCapitalize="none"
              autoComplete="email"
              autoCorrect="none"
              disabled={isUiActionPending}
              isRequired={true}
              inputRef={inputElement => (emailInputRef.current = inputElement)}
              messages={createErrorMessage(emailError)}
              onChange={handleEmailChange}
              renderLabel={I18n.t('Email Address')}
              value={email}
              data-testid="email-input"
            />

            <TextInput
              autoComplete="new-password"
              disabled={isUiActionPending}
              isRequired={true}
              inputRef={inputElement => (passwordInputRef.current = inputElement)}
              messages={createErrorMessage(passwordError)}
              onChange={handlePasswordChange}
              renderLabel={I18n.t('Password')}
              type="password"
              value={password}
              data-testid="password-input"
            />

            <TextInput
              autoComplete="new-password"
              disabled={isUiActionPending}
              isRequired={true}
              inputRef={inputElement => (confirmPasswordInputRef.current = inputElement)}
              messages={createErrorMessage(confirmPasswordError)}
              onChange={handleConfirmPasswordChange}
              renderLabel={I18n.t('Confirm Password')}
              type="password"
              value={confirmPassword}
              data-testid="confirm-password-input"
            />

            <TextInput
              autoCorrect="none"
              disabled={isUiActionPending}
              isRequired={true}
              inputRef={inputElement => (nameInputRef.current = inputElement)}
              messages={createErrorMessage(nameError)}
              onChange={handleNameChange}
              renderLabel={I18n.t('Full Name')}
              value={name}
              data-testid="name-input"
            />

            <TextInput
              autoCapitalize="none"
              autoCorrect="none"
              disabled={isUiActionPending}
              isRequired={true}
              inputRef={inputElement => (pairingCodeInputRef.current = inputElement)}
              messages={createErrorMessage(pairingCodeError)}
              onChange={handlePairingCodeChange}
              renderLabel={I18n.t('Student Pairing Code')}
              value={pairingCode}
              data-testid="pairing-code-input"
            />

            <Text>
              <Link
                href="https://community.canvaslms.com/t5/Canvas-Resource-Documents/Pairing-Codes-FAQ/ta-p/388738"
                target="_blank"
                data-testid="pairing-code-link"
              >
                {I18n.t('What is a pairing code?')}
              </Link>
            </Text>
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
                isRequired={true}
              />
            </Flex.Item>
          )}

          {recaptchaKey && (
            <ReCaptchaSection
              ref={recaptchaSectionRef}
              recaptchaKey={recaptchaKey}
              onVerify={handleReCaptchaVerify}
            />
          )}

          <Flex direction="row" gap="small">
            <Button
              color="secondary"
              disabled={isUiActionPending}
              display="block"
              onClick={handleCancel}
              data-testid="back-button"
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
    </Flex>
  )
}

export default Parent
