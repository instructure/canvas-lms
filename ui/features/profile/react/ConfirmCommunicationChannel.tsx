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

import React, {type ReactNode} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {raw} from '@instructure/html-escape'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {zodResolver} from '@hookform/resolvers/zod'
import * as z from 'zod'
import {Controller, useForm, type SubmitHandler} from 'react-hook-form'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'

const I18n = createI18nScope('profile')

const defaultValues = {code: ''}

const createValidationSchema = () =>
  z.object({
    code: z
      .string()
      .min(1, I18n.t('Code is required.'))
      .length(4, I18n.t('Code must be four characters.')),
  })

type FormValues = z.infer<ReturnType<typeof createValidationSchema>>

interface ConfirmChannelResponse {
  communication_channel: {id: string; pseudonym_id: string}
}

export interface ConfirmCommunicationChannelProps {
  communicationChannel: {user_id: string; pseudonym_id: string; channel_id: string}
  phoneNumberOrEmail: string
  children: ReactNode
  onClose: () => void
  onSubmit?: (response: ConfirmChannelResponse) => void
  onError?: () => void
}

const ConfirmCommunicationChannel = ({
  communicationChannel,
  phoneNumberOrEmail,
  children,
  onClose,
  onSubmit,
  onError,
}: ConfirmCommunicationChannelProps) => {
  const {
    formState: {errors, isSubmitting},
    control,
    handleSubmit,
  } = useForm({
    defaultValues,
    resolver: zodResolver(createValidationSchema()),
  })
  const title = I18n.t('Confirm Communication Channel')
  const buttonText = isSubmitting ? I18n.t('Confirming...') : I18n.t('Confirm')

  const handleFormSubmit: SubmitHandler<FormValues> = async ({code}) => {
    try {
      const {json} = await doFetchApi<ConfirmChannelResponse>({
        path: `/register/${code}`,
        method: 'POST',
        body: JSON.stringify({
          code,
          ...communicationChannel,
        }),
      })

      onSubmit?.(json!)
    } catch {
      onError?.()
    }
  }

  return (
    <Modal
      as="form"
      size="medium"
      label={title}
      open={true}
      shouldCloseOnDocumentClick={false}
      onDismiss={onClose}
      onSubmit={handleSubmit(handleFormSubmit)}
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
        <Flex direction="column" gap="medium" padding="small 0 0 0">
          <Text
            dangerouslySetInnerHTML={{
              __html: raw(
                I18n.t(
                  'To activate this communication channel, enter the four-character confirmation code sent to *%{phoneNumberOrEmail}*. The code is case sensitive.',
                  {wrapper: '<b>$1</b>', phoneNumberOrEmail},
                ),
              ),
            }}
          />
          <Controller
            name="code"
            control={control}
            render={({field}) => (
              <TextInput
                {...field}
                width="200px"
                renderLabel={I18n.t('Code')}
                messages={getFormErrorMessage(errors, 'code')}
              />
            )}
          />
          {children}
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Button type="submit" color="primary" disabled={isSubmitting} aria-label={buttonText}>
          {buttonText}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default ConfirmCommunicationChannel
