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
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {Controller, useForm, type Control, type SubmitHandler} from 'react-hook-form'
import * as z from 'zod'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'
import {zodResolver} from '@hookform/resolvers/zod'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('profile')

type ServiceName = 'skype' | 'google_drive' | 'diigo'

export const USERNAME_MAX_LENGTH = 255

const defaultValues = {username: '', password: ''}

const createValidationSchema = () =>
  z.object({
    username: z
      .string()
      .min(1, I18n.t('This field is required.'))
      .max(
        USERNAME_MAX_LENGTH,
        I18n.t('Exceeded the maximum length (%{usernameMaxLength} characters).', {
          usernameMaxLength: USERNAME_MAX_LENGTH,
        }),
      ),
    password: z.string().optional(),
  })

type FormValues = z.infer<ReturnType<typeof createValidationSchema>>

export const serviceConfigByName: Record<
  ServiceName,
  {
    title: string
    description: string
    image: {path: string; alt: string}
    fields?: (control: Control<typeof defaultValues, any>) => ReactNode
    button: ({isSubmitting}: {isSubmitting: boolean}) => ReactNode
  }
> = {
  skype: {
    title: I18n.t('Register Skype'),
    description: I18n.t(
      'Skype offers free online voice and video calls. Lots of students use Skype as a free, easy way to communicate. If you register your Skype Name and enable visibility, then other students can easily find your contact and call or add you using Skype.',
    ),
    image: {path: '/images/skype.png', alt: I18n.t('Skype logo')},
    fields: control => (
      <Controller
        name="username"
        control={control}
        render={({field, formState: {errors}}) => (
          <TextInput
            {...field}
            renderLabel={I18n.t('Skype Name')}
            messages={getFormErrorMessage(errors, 'username')}
          />
        )}
      />
    ),
    button: ({isSubmitting}) => {
      const buttonText = isSubmitting ? I18n.t('Saving Skype Name...') : I18n.t('Save Skype Name')

      return (
        <Button type="submit" color="primary" disabled={isSubmitting} aria-label={buttonText}>
          {buttonText}
        </Button>
      )
    },
  },
  google_drive: {
    title: I18n.t('Authorize Google Drive'),
    description: I18n.t(
      "Once you authorize us to see your Google Drive you'll be able to submit your assignments directly from Google Drive, and create and share documents with members of your classes.",
    ),
    image: {path: '/images/google_docs.png', alt: I18n.t('Google drive logo')},
    button: () => {
      const buttonText = I18n.t('Authorize Google Drive Access')

      return (
        <Button
          as="a"
          color="primary"
          href={ENV.google_drive_oauth_url ?? '#'}
          aria-label={buttonText}
        >
          {buttonText}
        </Button>
      )
    },
  },
  diigo: {
    title: I18n.t('Diigo login'),
    description: I18n.t(
      "Diigo is a social bookmarking tool tailored specifically to research and education. Canvas's rich content editor will let you search your Diigo tags to easily link from within Canvas to other resources you find useful.",
    ),
    image: {path: '/images/diigo.png', alt: I18n.t('Diigo logo')},
    fields: control => (
      <>
        <Controller
          name="username"
          control={control}
          render={({field, formState: {errors}}) => (
            <TextInput
              {...field}
              renderLabel={I18n.t('Username')}
              messages={getFormErrorMessage(errors, 'username')}
            />
          )}
        />
        <Controller
          name="password"
          control={control}
          render={({field, formState: {errors}}) => (
            <TextInput
              {...field}
              type="password"
              renderLabel={I18n.t('Password')}
              messages={getFormErrorMessage(errors, 'password')}
            />
          )}
        />
      </>
    ),
    button: ({isSubmitting}) => {
      const buttonText = isSubmitting ? I18n.t('Saving Login...') : I18n.t('Save Login')

      return (
        <Button type="submit" color="primary" aria-label={buttonText}>
          {buttonText}
        </Button>
      )
    },
  },
}

interface RegisterServiceProps {
  serviceName: ServiceName
  onSubmit: () => void
  onClose: () => void
}

const RegisterService = ({serviceName, onSubmit, onClose}: RegisterServiceProps) => {
  const {
    control,
    formState: {isSubmitting},
    handleSubmit,
  } = useForm({defaultValues, resolver: zodResolver(createValidationSchema())})
  const {title, image, description, fields, button} = serviceConfigByName[serviceName]

  const handleFormSubmit: SubmitHandler<FormValues> = async ({username, password}) => {
    try {
      await doFetchApi({
        path: '/profile/user_services',
        method: 'POST',
        body: {
          user_service: {
            service: serviceName,
            user_name: username,
            password: password || undefined,
          },
        },
      })

      onSubmit()
    } catch {
      showFlashError(
        I18n.t('Registration failed. Check the username and/or password, and try again.'),
      )()
    }
  }

  return (
    <Modal
      as="form"
      open={true}
      onDismiss={onClose}
      onSubmit={handleSubmit(handleFormSubmit)}
      size="small"
      label={title}
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
        <img src={image.path} alt={image.alt} style={{float: 'left', margin: 10, marginLeft: 0}} />
        <Text>{description}</Text>
        {fields && (
          <Flex direction="column" gap="medium" padding="small 0 0 0">
            {fields(control)}
          </Flex>
        )}
      </Modal.Body>
      <Modal.Footer>{button({isSubmitting})}</Modal.Footer>
    </Modal>
  )
}

export default RegisterService
