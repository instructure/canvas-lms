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

import React, {useDeferredValue} from 'react'
import {Controller, useForm, type SubmitHandler} from 'react-hook-form'
import * as z from 'zod'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'
import {zodResolver} from '@hookform/resolvers/zod'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {View} from '@instructure/ui-view'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Mask, Overlay} from '@instructure/ui-overlays'
import {Spinner} from '@instructure/ui-spinner'
import PseudonymModel from '@canvas/pseudonyms/backbone/models/Pseudonym'

const I18n = createI18nScope('confirm_change_password')

type CC = {
  path: string
  confirmation_code: string
}

type Pseudonym = {
  id: string
  user_name: string
}

export type PasswordPolicyAndPseudonym = {
  policy: {
    maximum_login_attempts?: string
    minimum_character_length?: string
    allow_login_suspension?: string
    require_number_characters?: string
    require_symbol_characters?: string
  }
  pseudonym: {unique_id: string; account_display_name: string}
}

const createValidationSchema = (
  passwordPoliciesAndPseudonyms: ConfirmChangePasswordProps['passwordPoliciesAndPseudonyms'],
) =>
  z
    .object({
      id: z.string(),
      password: z.string(),
      password_confirmation: z.string(),
    })
    .superRefine(({id, password, password_confirmation}, ctx) => {
      const passwordPolicyAndPseudonym = passwordPoliciesAndPseudonyms[id]

      if (!passwordPolicyAndPseudonym?.policy) {
        return
      }

      const {minimum_character_length} = passwordPolicyAndPseudonym.policy
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
    })

type FormValues = z.infer<ReturnType<typeof createValidationSchema>>

export interface ConfirmChangePasswordProps {
  pseudonym: Pseudonym
  defaultPolicy: PasswordPolicyAndPseudonym['policy']
  passwordPoliciesAndPseudonyms: {[pseudonymId: string]: PasswordPolicyAndPseudonym}
  cc: CC
}

const ConfirmChangePassword = ({
  pseudonym,
  defaultPolicy,
  passwordPoliciesAndPseudonyms,
  cc,
}: ConfirmChangePasswordProps) => {
  const {
    control,
    formState: {errors, isSubmitting},
    handleSubmit,
    setError,
    setFocus,
  } = useForm({
    defaultValues: {
      id: pseudonym.id,
      password: '',
      password_confirmation: '',
    },
    resolver: zodResolver(createValidationSchema(passwordPoliciesAndPseudonyms)),
  })
  const isSubmittingDeferred = useDeferredValue(isSubmitting)
  const passwordPolicyAndPseudonymEntries = Object.entries(passwordPoliciesAndPseudonyms)
  const buttonText = isSubmitting ? I18n.t('Updating Password...') : I18n.t('Update Password')

  const handleFormSubmit: SubmitHandler<FormValues> = async data => {
    try {
      await doFetchApi({
        path: `/pseudonyms/${pseudonym.id}/change_password/${cc.confirmation_code}`,
        method: 'POST',
        body: {
          pseudonym: data,
        },
      })

      window.location.href = '/login/canvas?password_changed=1'
    } catch (error: any) {
      const isJsonResponse = error?.response?.headers
        ?.get('Content-Type')
        ?.includes('application/json')
      const errorResponse = isJsonResponse && (await error?.response?.json())

      if (errorResponse?.errors?.nonce) {
        window.location.href = '/login/canvas'
      } else if (error?.response?.status === 400 && errorResponse) {
        const policy = passwordPoliciesAndPseudonyms[data.id]
          ? passwordPoliciesAndPseudonyms[data.id].policy
          : defaultPolicy
        const normalizedError: Record<
          keyof FormValues,
          Array<string>
        > = PseudonymModel.prototype.normalizeErrors(errorResponse.pseudonym, policy)

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
        showFlashError(I18n.t('An error occurred while updating your password.'))()
      }
    }
  }

  return (
    <>
      <Overlay
        open={isSubmittingDeferred}
        transition="fade"
        label={I18n.t('Loading overlay')}
        shouldContainFocus={true}
        shouldReturnFocus={true}
      >
        <Mask>
          <Spinner renderTitle={I18n.t('Loading...')} size="large" margin="0 0 0 medium" />
        </Mask>
      </Overlay>
      <View as="section" padding="small">
        <View as="div" margin="0 0 small 0">
          <Text as="h2" size="x-large">
            {I18n.t('Change login password for %{userName}', {userName: pseudonym.user_name})}
          </Text>
        </View>
        <form noValidate={true} onSubmit={handleSubmit(handleFormSubmit)}>
          <Flex gap="small" direction="column">
            {passwordPolicyAndPseudonymEntries.length > 1 ? (
              <Controller
                control={control}
                name="id"
                render={({field}) => (
                  <SimpleSelect
                    {...field}
                    renderLabel={I18n.t('Which login to change')}
                    onChange={(_, {value}) => field.onChange(value)}
                  >
                    {passwordPolicyAndPseudonymEntries.map(
                      ([pseudonymId, {pseudonym: currentPseudonym}]) => (
                        <SimpleSelect.Option key={pseudonymId} id={pseudonymId} value={pseudonymId}>
                          {`${currentPseudonym.unique_id} - ${currentPseudonym.account_display_name}`}
                        </SimpleSelect.Option>
                      ),
                    )}
                  </SimpleSelect>
                )}
              />
            ) : (
              <Text size="large" weight="bold">
                {cc.path}
              </Text>
            )}
            <Controller
              control={control}
              name="password"
              rules={{
                deps: ['password_confirmation'],
              }}
              render={({field}) => (
                <TextInput
                  {...field}
                  renderLabel={I18n.t('New Password')}
                  type="password"
                  isRequired={true}
                  messages={getFormErrorMessage(errors, 'password')}
                />
              )}
            />
            <Controller
              control={control}
              name="password_confirmation"
              rules={{
                deps: ['password'],
              }}
              render={({field}) => (
                <TextInput
                  {...field}
                  renderLabel={I18n.t('Confirm New Password')}
                  type="password"
                  isRequired={true}
                  messages={getFormErrorMessage(errors, 'password_confirmation')}
                />
              )}
            />
            <Flex justifyItems="end" margin="x-small 0">
              <Button color="primary" type="submit" aria-label={buttonText}>
                {buttonText}
              </Button>
            </Flex>
          </Flex>
        </form>
      </View>
    </>
  )
}

export default ConfirmChangePassword
