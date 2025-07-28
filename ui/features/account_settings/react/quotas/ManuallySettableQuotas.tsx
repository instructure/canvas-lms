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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextInput} from '@instructure/ui-text-input'
import {Controller, SubmitHandler, useForm} from 'react-hook-form'
import * as z from 'zod'
import {zodResolver} from '@hookform/resolvers/zod'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useState} from 'react'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {Link} from '@instructure/ui-link'
import {IS_INTEGER_REGEX} from './common'

const I18n = createI18nScope('manually_settable_quotas')

enum SelectOption {
  Course = 'course',
  Group = 'group',
}

const findEntityValidationSchema = z.object({
  id: z.string().min(1, I18n.t('ID is required.')),
  resource: z.enum([SelectOption.Course, SelectOption.Group]),
})
const updateQuotasValidationSchema = z.object({
  storage_quota_mb: z
    .string()
    .min(1, I18n.t('Quota is required.'))
    .regex(IS_INTEGER_REGEX, I18n.t('Quota must be an integer.')),
})

type FindEntityFormValues = z.infer<typeof findEntityValidationSchema>
type UpdateQuotasFormValues = z.infer<typeof updateQuotasValidationSchema>
type Entity = {name: string; storage_quota_mb: number}

const ManuallySettableQuotas = () => {
  const findEntityForm = useForm({
    defaultValues: {
      id: '',
      resource: SelectOption.Course,
    },
    resolver: zodResolver(findEntityValidationSchema),
  })
  const updateEntityForm = useForm({
    defaultValues: {
      storage_quota_mb: '',
    },
    resolver: zodResolver(updateQuotasValidationSchema),
  })
  const resource = findEntityForm.watch('resource')
  const resourcePlural = `${resource}s`
  const id = findEntityForm.watch('id')
  const [entity, setEntity] = useState<Entity | null>(null)
  const findButtonText = findEntityForm.formState.isSubmitting
    ? I18n.t('Finding...')
    : I18n.t('Find')
  const updateQuotasButtonText = updateEntityForm.formState.isSubmitting
    ? I18n.t('Updating...')
    : I18n.t('Update Quota')

  const searchEntity: SubmitHandler<FindEntityFormValues> = async ({id, resource}) => {
    try {
      const {json} = await doFetchApi<Entity | null>({
        path: `/api/v1/${resourcePlural}/${id}`,
      })

      if (!json) {
        return
      }

      setEntity(json)
      updateEntityForm.reset({storage_quota_mb: `${json.storage_quota_mb}`})
    } catch (error: any) {
      const errorStatus = error?.response?.status

      if (errorStatus === 401) {
        showFlashError(I18n.t('You are not authorized to access that %{resource}.', {resource}))()
      } else {
        showFlashError(I18n.t('Could not find a %{resource} with that ID.', {resource}))()
      }
    }
  }

  const updateQuotas: SubmitHandler<UpdateQuotasFormValues> = async ({storage_quota_mb}) => {
    const updatedEntity = {...entity, storage_quota_mb}
    const body = resource === SelectOption.Course ? {course: updatedEntity} : updatedEntity

    try {
      await doFetchApi({
        path: `/api/v1/${resourcePlural}/${id}`,
        method: 'PUT',
        body,
      })

      showFlashSuccess(I18n.t('Quota updated.'))()
    } catch {
      showFlashError(I18n.t('Quota was not updated.'))()
    }
  }

  return (
    <div>
      <Heading as="h2" level="h3">
        {I18n.t('Manually Settable Quotas')}
      </Heading>
      <Flex
        as="form"
        direction="column"
        gap="medium"
        margin="medium 0 0 0"
        noValidate={true}
        aria-label={I18n.t('Manually Settable Quotas search form')}
        onSubmit={findEntityForm.handleSubmit(searchEntity)}
      >
        <Controller
          control={findEntityForm.control}
          name="resource"
          render={({field}) => (
            <SimpleSelect
              {...field}
              renderLabel={I18n.t('Find course or group')}
              onChange={(_, {value}) => {
                findEntityForm.reset({id: '', resource: value as SelectOption})

                setEntity(null)
              }}
            >
              <SimpleSelect.Option id={SelectOption.Course} value={SelectOption.Course}>
                {I18n.t('Course ID')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id={SelectOption.Group} value={SelectOption.Group}>
                {I18n.t('Group ID')}
              </SimpleSelect.Option>
            </SimpleSelect>
          )}
        />
        <Controller
          control={findEntityForm.control}
          name="id"
          render={({field}) => (
            <TextInput
              {...field}
              renderLabel={I18n.t('ID')}
              isRequired={true}
              maxLength={13}
              messages={getFormErrorMessage(findEntityForm.formState.errors, 'id')}
            />
          )}
        />
        <Button
          type="submit"
          color="secondary"
          margin="0 auto 0 0"
          disabled={findEntityForm.formState.isSubmitting}
          aria-label={findButtonText}
        >
          {findButtonText}
        </Button>
      </Flex>
      {entity && (
        <Flex
          as="form"
          direction="column"
          margin="medium 0 0 0"
          gap="medium"
          noValidate={true}
          aria-label={I18n.t('Manually Settable Quotas update form')}
          onSubmit={updateEntityForm.handleSubmit(updateQuotas)}
        >
          <Controller
            control={updateEntityForm.control}
            name="storage_quota_mb"
            render={({field}) => (
              <TextInput
                {...field}
                isRequired={true}
                maxLength={13}
                renderLabel={
                  <Link href={`/${resourcePlural}/${id}`} target="_blank">
                    {entity.name}
                  </Link>
                }
                renderAfterInput={() => <span>{I18n.t('megabytes')}</span>}
                messages={getFormErrorMessage(
                  updateEntityForm.formState.errors,
                  'storage_quota_mb',
                )}
              />
            )}
          />
          <Button
            type="submit"
            margin="0 auto 0 0"
            disabled={updateEntityForm.formState.isSubmitting}
            aria-label={updateQuotasButtonText}
          >
            {updateQuotasButtonText}
          </Button>
        </Flex>
      )}
    </div>
  )
}

export default ManuallySettableQuotas
