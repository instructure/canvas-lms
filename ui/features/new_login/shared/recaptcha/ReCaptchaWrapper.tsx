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

import React, {forwardRef, useImperativeHandle, useRef} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('new_login')

interface Props {
  children: React.ReactNode
  hasError?: boolean
}

export interface ReCaptchaWrapperRef {
  focus: () => void
}

const ReCaptchaWrapper = forwardRef<ReCaptchaWrapperRef, Props>(({children, hasError}, ref) => {
  const containerRef = useRef<HTMLDivElement | null>(null)

  // expose focus to parent component
  useImperativeHandle(ref, () => ({
    focus: () => {
      containerRef.current?.focus()
    },
  }))

  return (
    <Flex direction="column" gap="xx-small">
      <View
        as="div"
        role="presentation"
        aria-describedby={hasError ? 'recaptcha-error' : undefined}
        position="relative"
        tabIndex={-1}
        elementRef={el => {
          containerRef.current = el as HTMLDivElement
        }}
      >
        {children}
      </View>

      {hasError && (
        <Text id="recaptcha-error" color="danger" role="alert" size="small" aria-live="assertive">
          {I18n.t('Please complete the reCAPTCHA verification.')}
        </Text>
      )}
    </Flex>
  )
})

export default ReCaptchaWrapper
