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

import React, {useRef} from 'react'
import {Controller, useForm, type SubmitHandler} from 'react-hook-form'
import * as z from 'zod'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {raw} from '@instructure/html-escape'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {zodResolver} from '@hookform/resolvers/zod'
import {
  getFormErrorMessage,
  isDateTimeInputInvalid,
} from '@canvas/forms/react/react-hook-form/utils'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import type {Token} from './types'

const I18n = createI18nScope('profile')

export const PURPOSE_MAX_LENGTH = 255
const MAX_EXPIRATION_DAYS = 120

const getMaxExpirationDate = () => {
  const maxDate = new Date()
  maxDate.setDate(maxDate.getDate() + MAX_EXPIRATION_DAYS)
  maxDate.setHours(0, 0, 0, 0) // Remove time, set to midnight
  return maxDate
}

const isFeatureFlagEnabled = () => ENV.FEATURES?.student_access_token_management

const isCurrentUserStudent = () => ENV.user_is_only_student

const shouldEnforceMaxExpiration = () => isFeatureFlagEnabled() && isCurrentUserStudent()

const defaultValues = {
  purpose: '',
  expires_at: undefined,
}

const createValidationSchema = () =>
  z.object({
    purpose: z
      .string()
      .min(1, I18n.t('Purpose is required.'))
      .max(
        PURPOSE_MAX_LENGTH,
        I18n.t('Exceeded the maximum length (%{purposeMaxLength} characters).', {
          purposeMaxLength: PURPOSE_MAX_LENGTH,
        }),
      ),
    expires_at: z
      .string()
      .optional()
      .refine(
        value => {
          // return false if there's no value and we should enforce max expiration
          return !(!value && shouldEnforceMaxExpiration())
        },
        {
          message: I18n.t('Expiration date is required.'),
        },
      ),
  })

type FormValues = z.infer<ReturnType<typeof createValidationSchema>>

interface NewAccessTokenProps {
  onSubmit: (token: Token) => void
  onClose: () => void
}

const NewAccessToken = ({onSubmit, onClose}: NewAccessTokenProps) => {
  const {
    formState: {errors, isSubmitting},
    control,
    handleSubmit,
    setFocus,
  } = useForm({
    defaultValues,
    resolver: zodResolver(createValidationSchema()),
  })
  const expiresAtInputRef = useRef<DateTimeInput>(null)
  const title = I18n.t('New Access Token')
  const submitButtonText = isSubmitting ? I18n.t('Generating Token...') : I18n.t('Generate Token')
  const cancelButtonText = I18n.t('Cancel')

  const handleFormSubmit: SubmitHandler<FormValues> = async token => {
    try {
      if (isDateTimeInputInvalid(expiresAtInputRef)) {
        setFocus('expires_at')
        return
      }

      const {json} = await doFetchApi<Token>({
        path: '/api/v1/users/self/tokens',
        method: 'POST',
        body: {token},
      })

      onSubmit(json!)
    } catch {
      showFlashError(I18n.t('Generating token failed.'))()
    }
  }

  return (
    <Modal
      as="form"
      open={true}
      onDismiss={onClose}
      onSubmit={handleSubmit(handleFormSubmit)}
      size="medium"
      label={title}
      noValidate={true}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{title}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Flex direction="column" gap="small">
          <Text
            dangerouslySetInnerHTML={{
              __html: raw(
                I18n.t(
                  "Access tokens are what allow third-party applications to access Canvas resources on your behalf. These tokens are normally created automatically for applications as needed, but if *you're developing a new or limited project* you can just generate the token from here.",
                  {
                    wrapper:
                      '<a href="https://developerdocs.instructure.com/services/canvas" class="external" target="_blank" rel="noreferrer noopener">$1</a>',
                  },
                ),
              ),
            }}
          />
          <Controller
            name="purpose"
            control={control}
            render={({field}) => (
              <TextInput
                {...field}
                isRequired={true}
                renderLabel={I18n.t('Purpose')}
                messages={getFormErrorMessage(errors, 'purpose')}
              />
            )}
          />
          <Controller
            name="expires_at"
            control={control}
            render={({field: {onChange, ref, ...rest}}) => (
              <DateTimeInput
                {...rest}
                isRequired={shouldEnforceMaxExpiration()}
                ref={expiresAtInputRef}
                dateInputRef={dateInputRef => {
                  dateInputRef?.setAttribute('data-testid', 'expiration-date')

                  ref(dateInputRef)
                }}
                timeInputRef={timeInputRef =>
                  timeInputRef?.setAttribute('data-testid', 'expiration-time')
                }
                timezone={ENV.TIMEZONE}
                locale={ENV.LOCALE}
                description={
                  <ScreenReaderContent>{I18n.t('Pick a date and time.')}</ScreenReaderContent>
                }
                invalidDateTimeMessage={() => ''}
                disabledDates={date => {
                  if (shouldEnforceMaxExpiration()) {
                    return new Date(date) > getMaxExpirationDate()
                  } else {
                    return false
                  }
                }}
                disabledDateTimeMessage={I18n.t(
                  'Expiration date cannot be more than %{days} days in the future.',
                  {
                    days: MAX_EXPIRATION_DAYS,
                  },
                )}
                dateRenderLabel={I18n.t('Expiration date')}
                timeRenderLabel={I18n.t('Expiration time')}
                prevMonthLabel={I18n.t('Previous month')}
                nextMonthLabel={I18n.t('Next month')}
                layout="columns"
                onChange={(_, isoValue) => onChange(isoValue)}
                messages={[
                  ...getFormErrorMessage(errors, 'expires_at'),
                  ...(shouldEnforceMaxExpiration()
                    ? [
                        {
                          type: 'hint' as const,
                          text: I18n.t('Maximum expiration is %{days} days.', {
                            days: MAX_EXPIRATION_DAYS,
                          }),
                        },
                      ]
                    : [
                        {
                          type: 'hint' as const,
                          text: I18n.t('Leave the expiration fields blank for no expiration.'),
                        },
                      ]),
                ]}
              />
            )}
          />
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Flex gap="x-small">
          <Button type="button" color="secondary" onClick={onClose} aria-label={cancelButtonText}>
            {cancelButtonText}
          </Button>
          <Button
            type="submit"
            color="primary"
            disabled={isSubmitting}
            aria-label={submitButtonText}
          >
            {submitButtonText}
          </Button>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default NewAccessToken
