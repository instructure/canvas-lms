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
import {ActionPrompt, EMAIL_REGEX, ReCaptcha, ROUTES, TermsAndPolicyCheckbox} from '../../shared'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {
  createErrorMessage,
  handleRegistrationRedirect,
  validatePassword,
} from '../../shared/helpers'
import {createParentAccount} from '../../services'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useNavigate} from 'react-router-dom'
import {useNewLogin} from '../../context/NewLoginContext'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('new_login')

const Parent = () => {
  const {
    isUiActionPending,
    privacyPolicyUrl,
    recaptchaKey,
    setIsUiActionPending,
    termsOfUseUrl,
    termsRequired,
    passwordPolicy,
  } = useNewLogin()
  const navigate = useNavigate()

  const [confirmPassword, setConfirmPassword] = useState('')
  const [email, setEmail] = useState('')
  const [name, setName] = useState('')
  const [pairingCode, setPairingCode] = useState('')
  const [password, setPassword] = useState('')
  const [termsAccepted, setTermsAccepted] = useState(false)
  const [captchaToken, setCaptchaToken] = useState<string | null>(null)

  const [confirmPasswordError, setConfirmPasswordError] = useState('')
  const [emailError, setEmailError] = useState('')
  const [nameError, setNameError] = useState('')
  const [pairingCodeError, setPairingCodeError] = useState('')
  const [passwordError, setPasswordError] = useState('')
  const [termsError, setTermsError] = useState('')

  const emailInputRef = useRef<HTMLInputElement | null>(null)
  const passwordInputRef = useRef<HTMLInputElement | null>(null)
  const confirmPasswordInputRef = useRef<HTMLInputElement | null>(null)
  const nameInputRef = useRef<HTMLInputElement | null>(null)
  const pairingCodeInputRef = useRef<HTMLInputElement | null>(null)

  const validateForm = (): boolean => {
    if (!EMAIL_REGEX.test(email)) {
      setEmailError(I18n.t('Please enter a valid email address.'))
      emailInputRef.current?.focus()
      return false
    } else {
      setEmailError('')
    }

    if (!password) {
      setPasswordError(I18n.t('Password is required.'))
      passwordInputRef.current?.focus()
      return false
    } else if (passwordPolicy) {
      const passwordValidationError = validatePassword(password, passwordPolicy)
      if (passwordValidationError) {
        setPasswordError(passwordValidationError)
        passwordInputRef.current?.focus()
        return false
      } else {
        setPasswordError('')
      }
    }

    if (password !== confirmPassword) {
      setConfirmPasswordError(I18n.t('Passwords do not match.'))
      confirmPasswordInputRef.current?.focus()
      return false
    } else {
      setConfirmPasswordError('')
    }

    if (name.trim() === '') {
      setNameError(I18n.t('Name is required.'))
      nameInputRef.current?.focus()
      return false
    } else {
      setNameError('')
    }

    const pairingCodeRegex = /^[a-zA-Z0-9]{6}$/
    if (!pairingCodeRegex.test(pairingCode)) {
      setPairingCodeError(I18n.t('Pairing code must be 6 alphanumeric characters.'))
      pairingCodeInputRef.current?.focus()
      return false
    } else {
      setPairingCodeError('')
    }

    if (termsRequired && !termsAccepted) {
      setTermsError(I18n.t('You must accept the terms to create an account.'))
      const checkboxElement = document.querySelector('.terms-checkbox') as HTMLElement
      checkboxElement?.focus()
      return false
    } else {
      setTermsError('')
    }

    if (recaptchaKey && !captchaToken) {
      showFlashAlert({
        message: I18n.t('Please complete the reCAPTCHA verification.'),
        type: 'error',
      })
      return false
    }

    return true
  }

  const handleCreateParent = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()

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
        handleRegistrationRedirect(response.data)
      } else {
        showFlashAlert({
          message: I18n.t('Something went wrong. Please try again later.'),
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
    setEmail(value.trim())
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

  const handlePasswordChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setPassword(value)
    if (passwordError) {
      setPasswordError('')
    }
  }

  const handlePasswordBlur = () => {
    if (!password) {
      setPasswordError('')
    } else if (passwordPolicy) {
      const passwordValidationError = validatePassword(password, passwordPolicy)
      if (passwordValidationError) {
        setPasswordError(passwordValidationError)
      } else {
        setPasswordError('')
      }
    }
  }

  const handleConfirmPasswordChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setConfirmPassword(value)
    if (confirmPasswordError) {
      setConfirmPasswordError('')
    }
  }

  const handleConfirmPasswordBlur = () => {
    if (confirmPassword && confirmPassword !== password) {
      setConfirmPasswordError(I18n.t('Passwords do not match.'))
    }
  }

  const handlePairingCodeChange = (_: React.ChangeEvent<HTMLInputElement>, value: string) => {
    setPairingCode(value.trim())
    if (pairingCodeError) {
      setPairingCodeError('')
    }
  }

  const handlePairingCodeBlur = () => {
    if (pairingCode) {
      const pairingCodeRegex = /^[a-zA-Z0-9]{6}$/
      if (!pairingCodeRegex.test(pairingCode)) {
        setPairingCodeError(I18n.t('Pairing code must be 6 alphanumeric characters.'))
      } else {
        setPairingCodeError('')
      }
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
          {I18n.t('Create a Parent Account')}
        </Heading>

        <Text>{I18n.t('All fields are required.')}</Text>
      </Flex>

      <form onSubmit={handleCreateParent} noValidate={true}>
        <Flex direction="column" gap="large">
          <Flex direction="column" gap="small">
            <TextInput
              autoCapitalize="none"
              autoComplete="email"
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
              autoComplete="new-password"
              disabled={isUiActionPending}
              inputRef={inputElement => (passwordInputRef.current = inputElement)}
              messages={createErrorMessage(passwordError)}
              onBlur={handlePasswordBlur}
              onChange={handlePasswordChange}
              renderLabel={I18n.t('Password')}
              type="password"
              value={password}
            />

            <TextInput
              autoComplete="new-password"
              disabled={isUiActionPending}
              inputRef={inputElement => (confirmPasswordInputRef.current = inputElement)}
              messages={createErrorMessage(confirmPasswordError)}
              onBlur={handleConfirmPasswordBlur}
              onChange={handleConfirmPasswordChange}
              renderLabel={I18n.t('Confirm Password')}
              type="password"
              value={confirmPassword}
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

            <TextInput
              autoCapitalize="none"
              autoCorrect="none"
              disabled={isUiActionPending}
              inputRef={inputElement => (pairingCodeInputRef.current = inputElement)}
              messages={createErrorMessage(pairingCodeError)}
              onBlur={handlePairingCodeBlur}
              onChange={handlePairingCodeChange}
              renderLabel={I18n.t('Student Pairing Code')}
              value={pairingCode}
            />

            <Text>
              <Link
                href="https://community.canvaslms.com/t5/Canvas-Resource-Documents/Pairing-Codes-FAQ/ta-p/388738"
                target="_blank"
              >
                {I18n.t('What is a pairing code?')}
              </Link>
            </Text>
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

          {recaptchaKey && (
            <Flex justifyItems="center" alignItems="center">
              <ReCaptcha siteKey={recaptchaKey} onVerify={token => setCaptchaToken(token)} />
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

export default Parent
