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
import {Flex} from '@instructure/ui-flex'
import {IconWarningSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import React, {forwardRef, useImperativeHandle, useRef} from 'react'

const I18n = createI18nScope('new_login')

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
        aria-describedby={hasError ? 'recaptcha-error' : undefined}
        as="div"
        data-testid="recaptcha-container"
        elementRef={el => {
          containerRef.current = el as HTMLDivElement
        }}
        height="78px"
        position="relative"
        role="presentation"
        tabIndex={-1}
        width="304px"
      >
        {children}
      </View>

      {hasError && (
        <Flex alignItems="start" as="div" direction="row" gap="xx-small">
          <Flex.Item align="start" padding="xxx-small 0 0 0" shouldShrink={false}>
            <IconWarningSolid
              color="error"
              data-testid="recaptcha-error-icon"
              height="0.875rem"
              style={{verticalAlign: 'top'}}
              width="0.875rem"
            />
          </Flex.Item>
          <Text
            aria-live="assertive"
            as="span"
            color="danger"
            data-testid="recaptcha-error-text"
            id="recaptcha-error"
            lineHeight="default"
            role="alert"
            size="small"
          >
            {I18n.t('Please complete the verification.')}
          </Text>
        </Flex>
      )}
    </Flex>
  )
})

export default ReCaptchaWrapper
