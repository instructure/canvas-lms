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
import classNames from 'classnames'
import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Loading} from './index'
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
    rememberMe,
    setRememberMe,
    isUiActionPending,
    setIsUiActionPending,
    setOtpRequired,
    otpCommunicationChannelId,
    setOtpCommunicationChannelId,
  } = useNewLogin()
  const [verificationCode, setVerificationCode] = useState('')
  const [isRedirecting, setIsRedirecting] = useState(false)
  // hide OTP form while handling redirection
  const [isInitiatingOtp, setIsInitiatingOtp] = useState(true)

  useEffect(() => {
    const initiateOtp = async () => {
      setIsUiActionPending(true)

      try {
        const response = await initiateOtpRequest()
        if (response.status === 200 && (response.data.otp_sent || response.data.otp_configuring)) {
          if (response.data.otp_sent) {
            setOtpCommunicationChannelId(response.data.otp_communication_channel_id || null)
            setIsInitiatingOtp(false)
            setIsUiActionPending(false)
          } else {
            setIsRedirecting(true)
            setIsUiActionPending(false)
            // redirect to the old otp configuration page
            // TODO handle otp configuration with React
            window.location.href = '/login/otp'
          }
        } else {
          // generic otp send failure or unexpected response
          showFlashAlert({
            message: I18n.t(
              'Unable to send the verification code at the moment. Please check your connection or try again later.'
            ),
            type: 'error',
          })
          setOtpRequired(false)
          setIsUiActionPending(false)
          setIsInitiatingOtp(false)
        }
      } catch (_error: unknown) {
        // network error(s) or unknown exception(s)
        showFlashAlert({
          message: I18n.t(
            'Failed to send the code due to a network error. Please check your internet connection and try again.'
          ),
          type: 'error',
        })
        setOtpRequired(false)
        setIsUiActionPending(false)
        setIsInitiatingOtp(false)
      }
    }

    initiateOtp()
  }, [setIsUiActionPending, setOtpCommunicationChannelId, setOtpRequired])

  const handleOtpSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    if (!verificationCode.trim()) {
      showFlashAlert({
        message: I18n.t('Please enter the code sent to your phone.'),
        type: 'error',
      })
      return
    }

    setIsUiActionPending(true)

    try {
      const response = await verifyOtpRequest(verificationCode, rememberMe)

      if (response.status === 200 && response.data?.location) {
        window.location.href = response.data.location || '/dashboard'
      } else {
        showFlashAlert({
          message: I18n.t('The code you entered is incorrect. Please try again.'),
          type: 'error',
        })
        setIsUiActionPending(false)
      }
    } catch (_error: unknown) {
      showFlashAlert({
        message: I18n.t('Something went wrong while verifying the code. Please try again.'),
        type: 'error',
      })
      setIsUiActionPending(false)
    }
  }

  const handleCancelOtp = async () => {
    setIsUiActionPending(true)

    try {
      const response = await cancelOtpRequest()

      if (response.status === 200) {
        setOtpRequired(false)
        setIsUiActionPending(false)
      } else {
        showFlashAlert({
          message: I18n.t('Failed to cancel the verification process. Please try again.'),
          type: 'error',
        })
        setIsUiActionPending(false)
      }
    } catch (_error: unknown) {
      showFlashAlert({
        message: I18n.t('Failed to cancel the verification process. Please try again.'),
        type: 'error',
      })
      setIsUiActionPending(false)
    }
  }

  const loadingContent = (
    <Loading
      title={
        isRedirecting
          ? I18n.t('Redirecting, please wait...')
          : I18n.t('Loading page, please wait...')
      }
    />
  )

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

      <form onSubmit={handleOtpSubmit}>
        <Flex direction="column" gap="large">
          <Flex direction="column" gap="small">
            <TextInput
              id="otpCode"
              renderLabel={I18n.t('Verification Code')}
              type="text"
              value={verificationCode}
              onChange={(_event, value) => {
                setVerificationCode(value)
              }}
              autoComplete="one-time-code"
            />

            <Flex.Item overflowY="visible" overflowX="visible">
              <Checkbox
                label={I18n.t('Stay signed in')}
                checked={rememberMe}
                onChange={() => setRememberMe(!rememberMe)}
                inline={true}
              />
            </Flex.Item>
          </Flex>

          <Flex direction="column" gap="small">
            <Button
              type="submit"
              color="primary"
              display="block"
              disabled={isUiActionPending || !verificationCode.trim()}
            >
              {I18n.t('Verify')}
            </Button>

            <Button
              color="secondary"
              onClick={handleCancelOtp}
              display="block"
              disabled={isUiActionPending}
            >
              {I18n.t('Cancel')}
            </Button>
          </Flex>
        </Flex>
      </form>
    </Flex>
  )

  return isInitiatingOtp || isRedirecting ? loadingContent : otpFormContent
}

export default OtpForm
