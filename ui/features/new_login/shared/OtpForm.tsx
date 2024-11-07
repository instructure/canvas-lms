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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import classNames from 'classnames'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Loading, RememberMeCheckbox} from '.'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {cancelOtpRequest, initiateOtpRequest, verifyOtpRequest} from '../services'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useNewLogin} from '../context/NewLoginContext'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('new_login')

interface Props {
  className?: string
}

const OtpForm = ({className}: Props) => {
  const {
    isUiActionPending,
    setIsUiActionPending,
    otpCommunicationChannelId,
    setOtpCommunicationChannelId,
    otpRequired,
    setOtpRequired,
    rememberMe,
  } = useNewLogin()

  const [verificationCode, setVerificationCode] = useState('')
  const [verificationCodeError, setVerificationCodeError] = useState('')
  const [isInitiating, setIsInitiating] = useState(true)
  const isRedirectingRef = useRef(false)

  const otpInputRef = useRef<HTMLInputElement | undefined>(undefined)

  const showErrorAlert = useCallback(
    (message: string) => {
      showFlashAlert({message, type: 'error'})
      setIsUiActionPending(false)
      setIsInitiating(false)
    },
    [setIsUiActionPending, setIsInitiating]
  )

  useEffect(() => {
    setVerificationCode('')
    setVerificationCodeError('')
  }, [otpRequired])

  useEffect(() => {
    if (verificationCodeError) {
      otpInputRef.current?.focus()
    }
  }, [verificationCodeError])

  const redirectTo = (url: string) => {
    isRedirectingRef.current = true
    window.location.replace(url)
  }

  const initiateOtp = useCallback(async () => {
    setIsUiActionPending(true)

    try {
      const response = await initiateOtpRequest()

      if (response.status === 200 && (response.data.otp_sent || response.data.otp_configuring)) {
        if (response.data.otp_sent) {
          setOtpCommunicationChannelId(response.data.otp_communication_channel_id || null)
          setIsUiActionPending(false)
        } else {
          redirectTo('/login/otp')
          return
        }
      } else {
        showErrorAlert(
          I18n.t(
            'Unable to send the verification code at the moment. Please check your connection or try again later.'
          )
        )
        setOtpRequired(false)
      }
    } catch (_error: unknown) {
      showErrorAlert(
        I18n.t(
          'Failed to send the code due to a network error. Please check your internet connection and try again.'
        )
      )
      setOtpRequired(false)
    } finally {
      if (!isRedirectingRef.current) {
        setIsUiActionPending(false)
        setIsInitiating(false)
      }
    }
  }, [showErrorAlert, setOtpCommunicationChannelId, setOtpRequired, setIsUiActionPending])

  useEffect(() => {
    initiateOtp()
  }, [initiateOtp])

  const handleOtpSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    if (!verificationCode) {
      setVerificationCodeError(I18n.t('Please enter the code sent to your phone.'))
      return
    }

    setIsUiActionPending(true)

    try {
      const response = await verifyOtpRequest(verificationCode, rememberMe)

      if (response.status === 200 && response.data?.location) {
        redirectTo(response.data.location || '/dashboard')
        return
      }
    } catch (error: any) {
      if (error.response?.status === 422) {
        setVerificationCodeError(I18n.t('Invalid verification code, please try again.'))
      } else {
        showErrorAlert(I18n.t('Something went wrong while verifying the code. Please try again.'))
      }
    } finally {
      if (!isRedirectingRef.current) setIsUiActionPending(false)
    }
  }

  const handleCancelOtp = () => {
    setIsUiActionPending(false)
    setOtpRequired(false)

    cancelOtpRequest().catch(_error => {
      // eslint-disable-next-line no-console
      console.error('Failed to cancel OTP process due to a network or server issue')
    })
  }

  const handleVerificationCodeChange = (
    _event: React.ChangeEvent<HTMLInputElement>,
    value: string
  ) => {
    setVerificationCode(value.trim())
    if (verificationCodeError) setVerificationCodeError('')
  }

  const handleVerificationCodeBlur = () => {
    if (!verificationCode && verificationCodeError) {
      setVerificationCodeError(I18n.t('Please enter the code sent to your phone.'))
    }
  }

  const otpFormContent = (
    <Flex className={classNames(className)} direction="column" gap="large">
      <Heading level="h2" as="h1">
        {I18n.t('Multi-Factor Authentication')}
      </Heading>

      {otpCommunicationChannelId ? (
        <Text>
          {I18n.t('Please enter the verification code sent to your mobile phone number.')}
        </Text>
      ) : (
        <Text>{I18n.t('Please enter the verification code shown by your authenticator app.')}</Text>
      )}

      <form onSubmit={handleOtpSubmit} noValidate={true}>
        <Flex direction="column" gap="large">
          <Flex direction="column" gap="small">
            <TextInput
              id="otpCode"
              renderLabel={I18n.t('Verification Code')}
              type="text"
              value={verificationCode}
              onChange={handleVerificationCodeChange}
              onBlur={handleVerificationCodeBlur}
              messages={verificationCodeError ? [{type: 'error', text: verificationCodeError}] : []}
              autoComplete="one-time-code"
              inputRef={inputElement => {
                otpInputRef.current = inputElement as HTMLInputElement | undefined
              }}
              disabled={isUiActionPending}
            />

            <Flex.Item overflowY="visible" overflowX="visible">
              <RememberMeCheckbox />
            </Flex.Item>
          </Flex>

          <Flex direction="row" gap="small">
            <Button
              color="secondary"
              onClick={handleCancelOtp}
              display="block"
              disabled={isUiActionPending}
            >
              {I18n.t('Cancel')}
            </Button>

            <Button type="submit" color="primary" display="block" disabled={isUiActionPending}>
              {I18n.t('Verify')}
            </Button>
          </Flex>
        </Flex>
      </form>
    </Flex>
  )

  const loadingContent = <Loading title={I18n.t('Loading page, please wait...')} />

  return isInitiating ? loadingContent : otpFormContent
}

export default OtpForm
