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

import {Heading} from '@instructure/ui-heading'
import {useScope as createI18nScope} from '@canvas/i18n'
import {TextInput} from '@instructure/ui-text-input'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Controller, SubmitHandler, useForm} from 'react-hook-form'
import * as z from 'zod'
import {zodResolver} from '@hookform/resolvers/zod'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'
import {FormMessage} from '@instructure/ui-form-field'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {AccountWithQuotas, IS_INTEGER_REGEX} from './common'

const I18n = createI18nScope('default_account_quotas')

const createValidationSchema = (isRootAccount: boolean) =>
  z.object({
    default_storage_quota_mb: z
      .string()
      .min(1, I18n.t('Course Quota is required.'))
      .regex(IS_INTEGER_REGEX, I18n.t('Course Quota must be an integer.')),
    default_group_storage_quota_mb: z
      .string()
      .min(1, I18n.t('Group Quota is required.'))
      .regex(IS_INTEGER_REGEX, I18n.t('Group Quota must be an integer.')),
    ...(isRootAccount && {
      default_user_storage_quota_mb: z
        .string()
        .min(1, I18n.t('User Quota is required.'))
        .regex(IS_INTEGER_REGEX, I18n.t('User Quota must be an integer.')),
    }),
  })

type FormValues = z.infer<ReturnType<typeof createValidationSchema>>

interface DefaultAccountQuotasProps {
  accountWithQuotas: AccountWithQuotas
}

const DefaultAccountQuotas = ({
  accountWithQuotas: {
    id,
    root_account,
    default_group_storage_quota_mb,
    default_storage_quota_mb,
    default_user_storage_quota_mb,
  },
}: DefaultAccountQuotasProps) => {
  const {
    control,
    formState: {errors, isSubmitting},
    handleSubmit,
  } = useForm({
    defaultValues: {
      default_storage_quota_mb: `${default_storage_quota_mb}`,
      default_group_storage_quota_mb: `${default_group_storage_quota_mb}`,
      default_user_storage_quota_mb: `${default_user_storage_quota_mb}`,
    },
    resolver: zodResolver(createValidationSchema(root_account)),
  })
  const buttonText = isSubmitting ? I18n.t('Updating...') : I18n.t('Update')

  const getWarningMessage = (quota: string): FormMessage[] => {
    const quotaAsNumber = Number(quota)

    if (!isNaN(quotaAsNumber) && quotaAsNumber > 100000) {
      return [{text: I18n.t('This storage quota may exceed typical usage.'), type: 'hint'}]
    }

    return []
  }

  const handleFormSubmit: SubmitHandler<FormValues> = async data => {
    try {
      await doFetchApi({
        path: `/api/v1/accounts/${id}`,
        method: 'PUT',
        body: {
          id,
          account: data,
        },
      })

      showFlashSuccess(I18n.t('Default account quotas updated.'))()
    } catch {
      showFlashError(I18n.t('Failed to update default account quotas.'))()
    }
  }

  return (
    <div>
      <Heading as="h2" level="h3">
        {I18n.t('Default Account Quotas')}
      </Heading>
      <Flex
        as="form"
        direction="column"
        gap="medium"
        margin="medium 0 0 0"
        noValidate={true}
        aria-label={I18n.t('Default Account Quotas form')}
        onSubmit={handleSubmit(handleFormSubmit)}
      >
        <Controller
          name="default_storage_quota_mb"
          control={control}
          render={({field}) => (
            <TextInput
              {...field}
              renderLabel={I18n.t('Course Quota')}
              isRequired={true}
              maxLength={13}
              renderAfterInput={() => <span>{I18n.t('megabytes')}</span>}
              messages={[
                ...getFormErrorMessage(errors, 'default_storage_quota_mb'),
                ...getWarningMessage(field.value),
              ]}
            />
          )}
        />
        {root_account && (
          <Controller
            name="default_user_storage_quota_mb"
            control={control}
            render={({field}) => (
              <TextInput
                {...field}
                renderLabel={I18n.t('User Quota')}
                isRequired={true}
                maxLength={13}
                renderAfterInput={() => <span>{I18n.t('megabytes')}</span>}
                messages={[
                  ...getFormErrorMessage(errors, 'default_user_storage_quota_mb'),
                  ...getWarningMessage(field.value),
                ]}
              />
            )}
          />
        )}
        <Controller
          name="default_group_storage_quota_mb"
          control={control}
          render={({field}) => (
            <TextInput
              {...field}
              renderLabel={I18n.t('Group Quota')}
              isRequired={true}
              maxLength={13}
              renderAfterInput={() => <span>{I18n.t('megabytes')}</span>}
              messages={[
                ...getFormErrorMessage(errors, 'default_group_storage_quota_mb'),
                ...getWarningMessage(field.value),
              ]}
            />
          )}
        />
        <Button
          type="submit"
          color="secondary"
          margin="0 auto 0 0"
          aria-label={buttonText}
          disabled={isSubmitting}
        >
          {buttonText}
        </Button>
      </Flex>
    </div>
  )
}

export default DefaultAccountQuotas
