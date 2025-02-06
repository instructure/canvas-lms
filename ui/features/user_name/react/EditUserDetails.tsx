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

import React, {useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import * as z from 'zod'
import {Controller, useForm} from 'react-hook-form'
import {zodResolver} from '@hookform/resolvers/zod'
import {TextInput} from '@instructure/ui-text-input'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'
import {SimpleSelect} from '@instructure/ui-simple-select'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {computeShortAndSortableNamesFromName} from '@canvas/user-sortable-name/react'

const I18n = createI18nScope('user_name')

export interface UserDetails {
  name: string
  short_name: string
  sortable_name: string
  email?: string
  time_zone: string
}

const createValidationSchema = (canManageUserDetails: boolean) =>
  z.object({
    name: z.string().optional(),
    short_name: z.string().optional(),
    sortable_name: z.string().optional(),
    ...(canManageUserDetails && {
      email: z
        .string()
        .email(I18n.t('Invalid email address.'))
        .or(z.literal('')),
      time_zone: z.string().optional(),
    }),
  })

export interface EditUserDetailsProps {
  userId: string
  userDetails: UserDetails
  timezones: Array<{name: string; name_with_hour_offset: string}>
  canManageUserDetails: boolean
  onSubmit: (user: UserDetails) => void
  onClose: () => void
}

const EditUserDetails = ({
  userId,
  userDetails,
  timezones,
  canManageUserDetails,
  onSubmit,
  onClose,
}: EditUserDetailsProps) => {
  const {
    control,
    formState: {errors, isSubmitting},
    getValues,
    setValue,
    handleSubmit,
    setFocus,
  } = useForm({
    defaultValues: userDetails,
    resolver: zodResolver(createValidationSchema(canManageUserDetails)),
  })
  const title = I18n.t('Edit User Details')
  const buttonText = isSubmitting ? I18n.t('Updating User Details...') : I18n.t('Update Details')

  const handleFormSubmit = async (user: UserDetails) => {
    let userData = user
    if (user.email === '') {
      const {email, ...rest} = user
      userData = rest
    }
    try {
      const {json} = await doFetchApi<UserDetails>({
        path: `/users/${userId}`,
        method: 'PATCH',
        body: {user: userData},
      })

      onSubmit(json!)
    } catch {
      showFlashError(I18n.t('Updating user details failed, please try again.'))()
    }
  }

  useEffect(() => {
    setFocus('name')
  }, [setFocus])

  return (
    <Modal
      as="form"
      open={true}
      onDismiss={onClose}
      size="small"
      label={title}
      shouldCloseOnDocumentClick={false}
      onSubmit={handleSubmit(handleFormSubmit)}
      noValidate={true}
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
          <Text>
            {I18n.t(
              "You can update some of this user's information, but they can change it back if they choose.",
            )}
          </Text>
          <Controller
            name="name"
            control={control}
            render={({field}) => (
              <TextInput
                {...field}
                onChange={(event, name) => {
                  const {name: prior_name, short_name, sortable_name} = getValues()
                  const computedNames = computeShortAndSortableNamesFromName({
                    prior_name,
                    name,
                    short_name,
                    sortable_name,
                  })

                  field.onChange(event)
                  setValue('short_name', computedNames.short_name)
                  setValue('sortable_name', computedNames.sortable_name)
                }}
                renderLabel={I18n.t('Full Name')}
                messages={getFormErrorMessage(errors, 'name')}
              />
            )}
          />
          <Controller
            name="short_name"
            control={control}
            render={({field}) => (
              <TextInput
                {...field}
                renderLabel={I18n.t('Display Name')}
                messages={getFormErrorMessage(errors, 'short_name')}
              />
            )}
          />
          <Controller
            name="sortable_name"
            control={control}
            render={({field}) => (
              <TextInput
                {...field}
                renderLabel={I18n.t('Sortable Name')}
                messages={getFormErrorMessage(errors, 'sortable_name')}
              />
            )}
          />
          {canManageUserDetails && (
            <>
              <Controller
                name="time_zone"
                control={control}
                render={({field}) => (
                  <SimpleSelect
                    {...field}
                    renderLabel={I18n.t('Time Zone')}
                    messages={getFormErrorMessage(errors, 'time_zone')}
                    onChange={(_, {value}) => field.onChange(value)}
                  >
                    {timezones.map(({name, name_with_hour_offset}) => (
                      <SimpleSelect.Option key={name} id={name} value={name}>
                        {name_with_hour_offset}
                      </SimpleSelect.Option>
                    ))}
                  </SimpleSelect>
                )}
              />
              <Controller
                name="email"
                control={control}
                render={({field}) => (
                  <TextInput
                    {...field}
                    renderLabel={I18n.t('Default Email')}
                    messages={getFormErrorMessage(errors, 'email')}
                  />
                )}
              />
            </>
          )}
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Flex gap="x-small">
          <Button type="button" color="secondary" onClick={onClose}>
            {I18n.t('Cancel')}
          </Button>
          <Button type="submit" color="primary" disabled={isSubmitting} aria-label={buttonText}>
            {buttonText}
          </Button>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default EditUserDetails
