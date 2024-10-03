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
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import {Checkbox} from '@instructure/ui-checkbox'
import {Heading} from '@instructure/ui-heading'
import {useScope as useI18nScope} from '@canvas/i18n'
import {useNewLogin} from '../context/NewLoginContext'
import {cancelOtpRequest, initiateOtpRequest, verifyOtpRequest} from '../services'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('new_login')

const OtpForm = () => {
  const {
    rememberMe,
    setRememberMe,
    isLoading,
    setIsLoading,
    setOtpRequired,
    otpCommunicationChannelId,
    setOtpCommunicationChannelId,
  } = useNewLogin()
  const [verificationCode, setVerificationCode] = useState('')

  useEffect(() => {
    const initiateOtp = async () => {
      setIsLoading(true)

      try {
        const response = await initiateOtpRequest()

        if (response.status === 200 && (response.data.otp_sent || response.data.otp_configuring)) {
          setOtpCommunicationChannelId(response.data.otp_communication_channel_id || null)
        } else {
          showFlashAlert({
            message: I18n.t('Failed to send code. Please try again.'),
            type: 'error',
          })
          setIsLoading(false)
        }
      } catch (_error: unknown) {
        showFlashAlert({
          message: I18n.t('Failed to send code. Please try again.'),
          type: 'error',
        })
        setIsLoading(false)
      }
    }

    initiateOtp()
  }, [setIsLoading, setOtpCommunicationChannelId])

  const handleOtpSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    if (!verificationCode.trim()) {
      showFlashAlert({
        message: I18n.t('Please enter the code sent to your phone.'),
        type: 'error',
      })
      return
    }

    setIsLoading(true)

    try {
      const response = await verifyOtpRequest(verificationCode, rememberMe)

      if (response.status === 200 && response.data?.location) {
        window.location.href = response.data.location || '/dashboard'
      } else {
        showFlashAlert({
          message: I18n.t('The code you entered is incorrect. Please try again.'),
          type: 'error',
        })
        setIsLoading(false)
      }
    } catch (_error: unknown) {
      showFlashAlert({
        message: I18n.t('Something went wrong while verifying the code. Please try again.'),
        type: 'error',
      })
      setIsLoading(false)
    }
  }

  const handleCancelOtp = async () => {
    try {
      const response = await cancelOtpRequest()

      if (response.status === 200) {
        setOtpRequired(false)
      } else {
        showFlashAlert({
          message: I18n.t('Failed to cancel the verification process. Please try again.'),
          type: 'error',
        })
      }
    } catch (_error: unknown) {
      showFlashAlert({
        message: I18n.t('Failed to cancel the verification process. Please try again.'),
        type: 'error',
      })
    }
  }

  return (
    <Flex direction="column" gap="large">
      <Flex.Item overflowY="visible">
        <Heading level="h2" as="h1">
          {I18n.t('Multi-Factor Authentication')}
        </Heading>

        {otpCommunicationChannelId ? (
          <p>{I18n.t('Please enter the verification code sent to your mobile phone number.')}</p>
        ) : (
          <p>{I18n.t('Please enter the verification code shown by your authenticator app.')}</p>
        )}
      </Flex.Item>

      <Flex.Item overflowY="visible">
        <form onSubmit={handleOtpSubmit}>
          <Flex direction="column" gap="large">
            <Flex.Item overflowY="visible">
              <Flex direction="column" gap="small">
                <Flex.Item overflowY="visible">
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
                </Flex.Item>

                <Flex.Item overflowY="visible">
                  <Checkbox
                    label={I18n.t('Stay signed in')}
                    checked={rememberMe}
                    onChange={() => setRememberMe(!rememberMe)}
                    inline={true}
                  />
                </Flex.Item>
              </Flex>
            </Flex.Item>

            <Flex.Item overflowY="visible">
              <Flex direction="column" gap="small">
                <Flex.Item overflowY="visible">
                  <Button
                    type="submit"
                    color="primary"
                    display="block"
                    disabled={isLoading || !verificationCode.trim()}
                  >
                    {I18n.t('Verify')}
                  </Button>
                </Flex.Item>

                <Flex.Item overflowY="visible">
                  <Button
                    color="secondary"
                    onClick={handleCancelOtp}
                    display="block"
                    disabled={isLoading}
                  >
                    {I18n.t('Cancel')}
                  </Button>
                </Flex.Item>
              </Flex>
            </Flex.Item>
          </Flex>
        </form>
      </Flex.Item>
    </Flex>
  )
}

export default OtpForm
