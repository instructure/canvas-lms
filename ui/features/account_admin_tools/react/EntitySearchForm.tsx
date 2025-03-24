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

import React, {useEffect, useState} from 'react'
import {Controller, useForm, type SubmitHandler} from 'react-hook-form'
import * as z from 'zod'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {zodResolver} from '@hookform/resolvers/zod'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {Mask, Overlay} from '@instructure/ui-overlays'
import {Spinner} from '@instructure/ui-spinner'

const I18n = createI18nScope('entity_search_form')

const createValidationSchema = (fieldName: string) =>
  z.object({
    entityId: z.string().min(1, I18n.t('%{fieldName} is required.', {fieldName})),
  })

type FormValues = z.infer<ReturnType<typeof createValidationSchema>>

export interface EntitySearchFormProps {
  title: string
  isDisabled: boolean
  inputConfig: {
    label: string
    placeholder: string
  }
  onSubmit: (entityId: string) => Promise<void>
}

export const EntitySearchForm = ({
  title,
  isDisabled,
  inputConfig,
  onSubmit,
}: EntitySearchFormProps) => {
  const [isLoading, setIsLoading] = useState(false)
  const {
    control,
    formState: {errors},
    reset,
    handleSubmit,
  } = useForm({
    defaultValues: {entityId: ''},
    resolver: zodResolver(createValidationSchema(inputConfig.placeholder)),
  })
  const buttonText = I18n.t('Find')

  const handleFormSubmit: SubmitHandler<FormValues> = async ({entityId}) => {
    try {
      setIsLoading(true)

      await onSubmit(entityId)
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    reset()
  }, [reset, title])

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} noValidate={true}>
      <Overlay
        open={isLoading}
        transition="fade"
        label={I18n.t('Loading overlay')}
        shouldContainFocus={true}
        shouldReturnFocus={true}
      >
        <Mask>
          <Spinner renderTitle={I18n.t('Loading...')} size="large" margin="0 0 0 medium" />
        </Mask>
      </Overlay>
      <Text as="h2" size="x-large">
        {title}
      </Text>
      <Flex gap="small" alignItems="center" height={95}>
        <Flex.Item align="start">
          <Controller
            control={control}
            name="entityId"
            render={({field}) => (
              <TextInput
                {...field}
                isRequired={true}
                maxLength={50}
                renderLabel={inputConfig.label}
                placeholder={inputConfig.placeholder}
                disabled={isDisabled}
                messages={getFormErrorMessage(errors, 'entityId')}
              />
            )}
          />
        </Flex.Item>
        <Button
          type="submit"
          color="primary"
          disabled={isDisabled}
          data-testid="entity-search-form-submit"
        >
          {buttonText}
        </Button>
      </Flex>
    </form>
  )
}
