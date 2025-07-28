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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import React, {forwardRef, useImperativeHandle, useRef, useState} from 'react'
import {ErrorBoundary} from '..'
import ReCaptcha from './ReCaptcha'
import ReCaptchaWrapper, {type ReCaptchaWrapperRef} from './ReCaptchaWrapper'

const I18n = createI18nScope('new_login')

interface Props {
  recaptchaKey: string
  onVerify?: (token: string | null) => void
}

export interface ReCaptchaSectionRef {
  validate: () => boolean
  reset: () => void
  focus: () => void
}

const ReCaptchaSection = forwardRef<ReCaptchaSectionRef, Props>(({recaptchaKey, onVerify}, ref) => {
  const [captchaError, setCaptchaError] = useState(false)
  const [captchaToken, setCaptchaToken] = useState<string | null>(null)
  const [validationTriggered, setValidationTriggered] = useState(false)

  const wrapperRef = useRef<ReCaptchaWrapperRef | null>(null)

  useImperativeHandle(ref, () => ({
    validate: () => {
      setValidationTriggered(true)
      if (captchaError || !captchaToken) {
        setCaptchaError(true)
        return false
      }
      return true
    },
    reset: () => {
      setCaptchaToken(null)
      setCaptchaError(false)
      setValidationTriggered(false)
      if (window.grecaptcha) {
        window.grecaptcha.reset()
      } else {
        console.warn('window.grecaptcha is not available!')
      }
    },
    focus: () => {
      wrapperRef.current?.focus()
    },
  }))

  const handleVerify = (token: string | null) => {
    if (token) {
      setCaptchaToken(token)
      setCaptchaError(false)
    } else {
      setCaptchaToken(null)
      setCaptchaError(true)
    }

    if (onVerify) {
      onVerify(token)
    } else {
      console.warn('No onVerify callback provided for ReCaptchaSection.')
    }
  }

  return (
    <ErrorBoundary
      fallback={
        <Text color="danger" role="alert" size="small" aria-live="assertive">
          {I18n.t('Something went wrong with reCAPTCHA. Please refresh and try again.')}
        </Text>
      }
    >
      <ReCaptchaWrapper ref={wrapperRef} hasError={validationTriggered && !captchaToken}>
        <ReCaptcha siteKey={recaptchaKey} onVerify={handleVerify} />
      </ReCaptchaWrapper>
    </ErrorBoundary>
  )
})

export default ReCaptchaSection
