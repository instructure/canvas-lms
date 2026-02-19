/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('lti_registrations')

export type MigrationEmailNotificationProps = {
  emailNotification: boolean
  setEmailNotification: (checked: boolean) => void
  email: string
  setEmail: (value: string) => void
  emailError?: string
  setEmailError: (error: string | undefined) => void
  handleEmailChange: (_e: React.ChangeEvent<HTMLInputElement>, value: string) => void
  setEmailInputElement: (ref: HTMLInputElement | null) => void
}

export const MigrationEmailNotification = ({
  emailNotification,
  setEmailNotification,
  email,
  setEmail,
  emailError,
  setEmailError,
  handleEmailChange,
  setEmailInputElement,
}: MigrationEmailNotificationProps) => {
  return (
    <Flex.Item padding="small none none none">
      <View as="div" borderWidth="small 0 0 0" padding="small 0 0 0">
        <Flex direction="column" gap="small">
          <Flex.Item>
            <Checkbox
              label={I18n.t('Email report upon completion of a migration')}
              checked={emailNotification}
              onChange={e => {
                setEmailNotification(e.target.checked)
                if (!e.target.checked) {
                  setEmailError(undefined)
                  setEmail('')
                }
              }}
            />
          </Flex.Item>
          {emailNotification && (
            <Flex.Item>
              <TextInput
                value={email}
                onChange={handleEmailChange}
                placeholder={I18n.t('Enter email address')}
                isRequired={true}
                messages={emailError ? [{text: emailError, type: 'error'}] : undefined}
                inputRef={ref => {
                  if (ref instanceof HTMLInputElement) {
                    setEmailInputElement(ref)
                  }
                }}
              />
            </Flex.Item>
          )}
        </Flex>
      </View>
    </Flex.Item>
  )
}
