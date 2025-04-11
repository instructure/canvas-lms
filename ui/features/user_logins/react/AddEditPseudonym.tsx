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

import {useEffect} from 'react'
import {Controller, useForm, type SubmitHandler} from 'react-hook-form'
import * as z from 'zod'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {Modal} from '@instructure/ui-modal'
import {zodResolver} from '@hookform/resolvers/zod'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import PseudonymModel from '@canvas/pseudonyms/backbone/models/Pseudonym'

const I18n = createI18nScope('add_edit_pseudonym')

const createValidationSchema = (
  isEdit: boolean,
  accountIdPasswordPolicyMap: AddEditPseudonymProps['accountIdPasswordPolicyMap'],
  defaultPolicy: PasswordPolicy,
) =>
  z
    .object({
      unique_id: z.string().min(1, I18n.t('Login is required.')),
      sis_user_id: z.string().optional(),
      integration_id: z.string().optional(),
      account_id: z.number().optional(),
      password: z.string(),
      password_confirmation: z.string(),
    })
    .superRefine(({account_id, password, password_confirmation}, ctx) => {
      const anyPasswordProvided = password.length || password_confirmation.length

      if (!isEdit && anyPasswordProvided) {
        const policy =
          accountIdPasswordPolicyMap && account_id
            ? (accountIdPasswordPolicyMap[account_id] ?? defaultPolicy)
            : defaultPolicy
        const {minimum_character_length} = policy
        const minCharacterLength = Number(minimum_character_length)
        const isTooShort = password.length < minCharacterLength

        if (isTooShort) {
          ctx.addIssue({
            code: z.ZodIssueCode.custom,
            message: I18n.t('Must be at least %{minCharacterLength} characters.', {
              minCharacterLength,
            }),
            path: ['password'],
            fatal: true,
          })

          return z.NEVER
        }

        if (password !== password_confirmation) {
          ctx.addIssue({
            code: z.ZodIssueCode.custom,
            message: I18n.t('Passwords do not match.'),
            path: ['password_confirmation'],
          })
        }
      }
    })

type FormValues = z.infer<ReturnType<typeof createValidationSchema>>

interface PasswordPolicy {
  maximum_login_attempts?: string
  minimum_character_length?: string
  allow_login_suspension?: string
  require_number_characters?: string
  require_symbol_characters?: string
}

interface Pseudonym {
  id: string
  unique_id: string
  sis_user_id?: string
  integration_id?: string
  account_id: number
}

export interface AddEditPseudonymProps {
  userId: string
  pseudonym?: Pseudonym
  canManageSis: boolean
  canChangePassword: boolean
  isDelegatedAuth: boolean
  accountSelectOptions: Array<{label: string; value: number}>
  accountIdPasswordPolicyMap?: Record<string, PasswordPolicy>
  defaultPolicy: PasswordPolicy
  isEdit: boolean
  onClose: () => void
  onSubmit: (pseudonym: Pseudonym) => void
}

const AddEditPseudonym = ({
  userId,
  pseudonym,
  canManageSis,
  canChangePassword,
  isDelegatedAuth,
  accountSelectOptions,
  accountIdPasswordPolicyMap,
  defaultPolicy,
  isEdit,
  onClose,
  onSubmit,
}: AddEditPseudonymProps) => {
  const defaultValues = {
    unique_id: pseudonym?.unique_id ?? '',
    sis_user_id: pseudonym?.sis_user_id ?? '',
    integration_id: pseudonym?.integration_id ?? '',
    account_id: pseudonym?.account_id ?? accountSelectOptions?.[0]?.value,
    password: '',
    password_confirmation: '',
  }
  const {
    control,
    formState: {errors, isSubmitting},
    handleSubmit,
    setError,
    setFocus,
  } = useForm({
    defaultValues,
    resolver: zodResolver(
      createValidationSchema(isEdit, accountIdPasswordPolicyMap, defaultPolicy),
    ),
  })
  const title = isEdit ? I18n.t('Update Login') : I18n.t('Add Login')
  const buttonText = isSubmitting ? (isEdit ? I18n.t('Updating...') : I18n.t('Adding...')) : title
  const shouldShowPasswordFields = !isEdit || canChangePassword

  useEffect(() => {
    setFocus('unique_id')
  }, [setFocus])

  const handleFormSubmit: SubmitHandler<FormValues> = async data => {
    const payload: Partial<FormValues> = {...data}
    const path = `/users/${userId}/pseudonyms${isEdit ? `/${pseudonym?.id}` : ''}`
    const method = isEdit ? 'PUT' : 'POST'
    const arePasswordsEmpty = !payload.password && !payload.password_confirmation

    if (!shouldShowPasswordFields || arePasswordsEmpty) {
      delete payload.password
      delete payload.password_confirmation
    }

    if (!canManageSis) {
      delete payload.sis_user_id
      delete payload.integration_id
    }

    try {
      const {json} = await doFetchApi<Pseudonym>({
        path,
        method,
        body: {
          pseudonym: payload,
        },
      })

      onSubmit(json!)
    } catch (error: any) {
      const isJsonResponse = error?.response?.headers
        ?.get('Content-Type')
        ?.includes('application/json')
      const errorResponse = isJsonResponse && (await error?.response?.json())

      if (error?.response?.status === 401) {
        showFlashError(
          I18n.t('You do not have sufficient privileges to make the change requested.'),
        )()
      } else if (error?.response?.status === 400 && errorResponse) {
        const {account_id} = data
        const policy =
          accountIdPasswordPolicyMap && account_id
            ? (accountIdPasswordPolicyMap[account_id] ?? defaultPolicy)
            : defaultPolicy
        const normalizedError: Record<
          keyof FormValues,
          Array<string>
        > = PseudonymModel.prototype.normalizeErrors(errorResponse.errors, policy)

        for (const key in normalizedError) {
          const fieldName = key as keyof FormValues

          for (const message of normalizedError[fieldName]) {
            setError(fieldName, {
              message,
            })
            setFocus(fieldName)
          }
        }
      } else {
        showFlashError(
          I18n.t('An error occurred while %{operation} login.', {
            operation: isEdit ? 'updating' : 'adding',
          }),
        )()
      }
    }
  }

  return (
    <Modal
      as="form"
      open={true}
      noValidate={true}
      onDismiss={onClose}
      size="small"
      label={title}
      shouldCloseOnDocumentClick={false}
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
        <Flex direction="column" gap="small">
          <Controller
            control={control}
            name="unique_id"
            render={({field}) => (
              <TextInput
                {...field}
                autoComplete="off"
                isRequired={true}
                renderLabel={I18n.t('Login')}
                messages={getFormErrorMessage(errors, 'unique_id')}
              />
            )}
          />
          {canManageSis && (
            <>
              <Controller
                control={control}
                name="sis_user_id"
                render={({field}) => (
                  <TextInput
                    {...field}
                    renderLabel={I18n.t('SIS ID')}
                    messages={getFormErrorMessage(errors, 'sis_user_id')}
                  />
                )}
              />
              <Controller
                control={control}
                name="integration_id"
                render={({field}) => (
                  <TextInput
                    {...field}
                    renderLabel={I18n.t('Integration ID')}
                    messages={getFormErrorMessage(errors, 'integration_id')}
                  />
                )}
              />
            </>
          )}
          {!isEdit && accountSelectOptions.length && (
            <Controller
              control={control}
              name="account_id"
              render={({field}) => (
                <SimpleSelect
                  {...field}
                  renderLabel={I18n.t('Account')}
                  messages={getFormErrorMessage(errors, 'account_id')}
                  onChange={(_, {value}) => field.onChange(value)}
                >
                  {accountSelectOptions.map(({label, value}) => (
                    <SimpleSelect.Option id={`${value}`} key={value} value={value}>
                      {label}
                    </SimpleSelect.Option>
                  ))}
                </SimpleSelect>
              )}
            />
          )}
          {shouldShowPasswordFields && (
            <>
              <Controller
                control={control}
                name="password"
                render={({field}) => (
                  <TextInput
                    {...field}
                    autoComplete="new-password"
                    type="password"
                    renderLabel={I18n.t('Password')}
                    messages={getFormErrorMessage(errors, 'password')}
                  />
                )}
              />
              <Controller
                control={control}
                name="password_confirmation"
                render={({field}) => (
                  <TextInput
                    {...field}
                    autoComplete="new-password"
                    type="password"
                    renderLabel={I18n.t('Confirm Password')}
                    messages={getFormErrorMessage(errors, 'password_confirmation')}
                  />
                )}
              />
            </>
          )}
          {isDelegatedAuth && (
            <Text
              size="small"
              color="secondary"
              dangerouslySetInnerHTML={{
                __html: I18n.t(
                  "Note: This login's account uses delegated authentication, but allows fallback Canvas password authentication. The password fields in this form update the fallback Canvas password, <b>not</b> the delegated authentication.",
                ),
              }}
            />
          )}
        </Flex>
      </Modal.Body>
      <Modal.Footer>
        <Button type="button" color="secondary" margin="0 x-small 0 0" onClick={onClose}>
          {I18n.t('Cancel')}
        </Button>
        <Button
          type="submit"
          color="primary"
          aria-label={buttonText}
          disabled={isSubmitting}
          data-testid="add-edit-pseudonym-submit"
        >
          {buttonText}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default AddEditPseudonym
