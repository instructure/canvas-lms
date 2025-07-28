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

import {View} from '@instructure/ui-view'
import React, {useEffect, useRef} from 'react'

declare global {
  interface Window {
    grecaptcha?: any
  }
}

interface Props {
  siteKey: string
  onVerify: (token: string | null) => void
}

const ReCaptcha = ({siteKey, onVerify}: Props) => {
  const containerRef = useRef<HTMLDivElement | null>(null)
  const captchaRenderedRef = useRef(false)

  useEffect(() => {
    const grecaptcha = window.grecaptcha as NonNullable<typeof window.grecaptcha>
    if (!grecaptcha || !containerRef.current) {
      console.error('reCAPTCHA script not found on window')
      return
    }

    grecaptcha.ready(() => {
      if (!captchaRenderedRef.current) {
        containerRef.current!.innerHTML = ''
        grecaptcha.render(containerRef.current!, {
          sitekey: siteKey,
          size: 'normal',
          theme: 'light',
          callback: onVerify,
          'expired-callback': () => {
            onVerify(null)
          },
        })
        captchaRenderedRef.current = true
      }
    })
  }, [siteKey, onVerify])

  return (
    <View
      as="div"
      elementRef={element => {
        containerRef.current = element as HTMLDivElement
      }}
    />
  )
}

export default ReCaptcha
