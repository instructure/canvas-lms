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

import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'
import {useScope as createI18nScope} from '@canvas/i18n'
import {clearObservedId, savedObservedId} from '@canvas/observer-picker/ObserverGetObservee'
import {assignLocation} from '@canvas/util/globalUtils'
import {zodResolver} from '@hookform/resolvers/zod'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconAddLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Mask, Overlay} from '@instructure/ui-overlays'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {useMutation, useQuery} from '@tanstack/react-query'
import React from 'react'
import {Controller, type SubmitHandler, useForm} from 'react-hook-form'
import * as z from 'zod'

const I18n = createI18nScope('pairing_code_user_observees')

const defaultValues = {
  pairing_code: '',
}

const createValidationSchema = () =>
  z.object({
    pairing_code: z.string().min(1, I18n.t('Invalid pairing code.')),
  })

export type Observee = {
  id: string
  name: string
}

type FormValues = z.infer<ReturnType<typeof createValidationSchema>>

interface UserObserveesProps {
  userId: string
}

function UserObservees({userId}: UserObserveesProps) {
  const {
    control,
    formState: {errors},
    handleSubmit,
    setValue,
    setFocus,
  } = useForm({defaultValues, resolver: zodResolver(createValidationSchema())})
  const {
    data: observees,
    isLoading,
    isError,
    refetch: refetchObservees,
  } = useQuery({
    queryKey: ['user_observees', userId],
    queryFn: async () => {
      const {json} = await doFetchApi<Array<Observee>>({
        path: `/api/v1/users/${userId}/observees?per_page=100`,
        method: 'GET',
      })

      return json
    },
  })
  const {mutate: addObservee, ...addObserveeMutationState} = useMutation({
    mutationFn: async ({pairing_code}: {pairing_code: string}) => {
      const {json} = await doFetchApi<Observee & {redirect?: string}>({
        path: `/api/v1/users/${userId}/observees`,
        method: 'POST',
        body: {pairing_code},
      })

      return json
    },
    onSuccess: observee => {
      if (observee?.redirect) {
        const isConfirmed = window.confirm(
          I18n.t(
            "In order to complete the process you will be redirected to a login page where you will need to log in with your child's credentials.",
          ),
        )

        if (isConfirmed) {
          assignLocation(observee.redirect)
        }
      } else {
        showFlashSuccess(I18n.t('Now observing %{name}.', {name: observee?.name}))()

        setValue('pairing_code', '')
        setFocus('pairing_code')

        refetchObservees()
      }
    },
    onError: () => {
      showFlashError(I18n.t('Invalid pairing code.'))()

      setFocus('pairing_code')
    },
  })
  const {mutate: removeObservee, ...removeObserveeMutationState} = useMutation({
    mutationFn: async ({observeeId}: {observeeId: string}) => {
      const {json} = await doFetchApi<Observee>({
        path: `/api/v1/users/self/observees/${observeeId}`,
        method: 'DELETE',
      })

      return json
    },
    onSuccess: observee => {
      showFlashSuccess(I18n.t('No longer observing %{name}.', {name: observee?.name}))()

      refetchObservees()
    },
    onError: () => showFlashError(I18n.t('Failed to remove student.'))(),
  })
  const isOverlayOpen = removeObserveeMutationState.isPending || addObserveeMutationState.isPending
  const buttonText = I18n.t('Student')

  const handleRemoveObservee = ({observeeId, name}: {observeeId: string; name: string}) => {
    const isConfirmed = window.confirm(
      I18n.t('Are you sure you want to stop observing %{name}?', {
        name,
      }),
    )

    if (!isConfirmed) {
      return
    }

    const currentObservedId = savedObservedId(userId)
    if (currentObservedId === observeeId) {
      clearObservedId(userId)
    }

    removeObservee({observeeId})
  }

  const handleFormSubmit: SubmitHandler<FormValues> = async data => {
    addObservee(data)
  }

  let content = null

  if (isLoading) {
    content = <Spinner renderTitle={I18n.t('Loading...')} size="small" />
  } else if (isError) {
    content = <Alert variant="error">{I18n.t('Failed to load students.')}</Alert>
  } else if (observees?.length) {
    content = observees.map(observee => (
      <ul key={observee.id}>
        <li>
          <Flex alignItems="start">
            <Text>{observee.name}</Text>
            <Link
              aria-label={I18n.t('Remove %{name}', {name: observee.name})}
              margin="0 0 0 small"
              onClick={() => handleRemoveObservee({observeeId: observee.id, name: observee.name})}
            >
              <Text size="small"> {I18n.t('(Remove)')}</Text>
            </Link>
          </Flex>
        </li>
      </ul>
    ))
  } else {
    content = <Text fontStyle="italic">{I18n.t('No students being observed.')}</Text>
  }

  return (
    <section>
      <Overlay
        open={isOverlayOpen}
        transition="fade"
        label={I18n.t('Loading overlay')}
        shouldContainFocus={true}
        shouldReturnFocus={true}
      >
        <Mask>
          <Spinner renderTitle={I18n.t('Loading...')} size="large" margin="0 0 0 medium" />
        </Mask>
      </Overlay>
      <View as="div" margin="0 0 small 0">
        <Text as="h2" size="x-large">
          {I18n.t('Observing')}
        </Text>
      </View>
      <form noValidate={true} onSubmit={handleSubmit(handleFormSubmit)}>
        <Flex direction="column" gap="small" width={210} alignItems="start">
          <Controller
            control={control}
            name="pairing_code"
            render={({field}) => (
              <TextInput
                {...field}
                renderLabel={I18n.t('Student Pairing Code')}
                isRequired={true}
                messages={getFormErrorMessage(errors, 'pairing_code')}
              />
            )}
          />
          <Button
            type="submit"
            color="primary"
            aria-label={buttonText}
            renderIcon={() => <IconAddLine />}
          >
            {buttonText}
          </Button>
        </Flex>
      </form>

      <Text as="h3" size="large">
        {I18n.t('Students Being Observed')}
      </Text>
      {content}
    </section>
  )
}

export default UserObservees
