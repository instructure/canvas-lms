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
import {raw} from '@instructure/html-escape'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconUserLine} from '@instructure/ui-icons'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import AutoCompleteSelect from '../../../shared/auto-complete-select/react/AutoCompleteSelect'
import {useRef, useState} from 'react'
import {
  AccountSelectOption,
  createUserToMergeQueryKey,
  fetchUserWithRelations,
  User,
} from './common'
import {queryClient} from '@canvas/query'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'
import {Controller, SubmitHandler, useForm} from 'react-hook-form'
import * as z from 'zod'
import {zodResolver} from '@hookform/resolvers/zod'
import {getFormErrorMessage} from '@canvas/forms/react/react-hook-form/utils'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useQuery} from '@tanstack/react-query'

const I18n = createI18nScope('merge_users')

enum FindByOptions {
  UserId,
  Name,
}

const createValidationSchema = () =>
  z.object({
    destinationAccountId: z.string().optional(),
    destinationUserId: z.string().min(1, I18n.t('Required')),
  })

type FormValues = z.infer<ReturnType<typeof createValidationSchema>>

const defaultValues: FormValues = {
  destinationAccountId: undefined,
  destinationUserId: '',
}

export interface FindUserToMergeProps {
  sourceUserId: string
  accountSelectOptions: Array<AccountSelectOption>
  onFind: (destinationUserId: string) => void
}

const FindUserToMerge = ({sourceUserId, accountSelectOptions, onFind}: FindUserToMergeProps) => {
  const {
    data: sourceUser,
    isLoading,
    isError,
  } = useQuery({
    queryKey: createUserToMergeQueryKey(sourceUserId!),
    queryFn: async () => fetchUserWithRelations(sourceUserId!),
  })
  const {
    control,
    reset,
    formState: {errors, isSubmitting},
    watch,
    handleSubmit,
  } = useForm({
    defaultValues,
    resolver: zodResolver(createValidationSchema()),
  })
  const [findBy, setFindBy] = useState(FindByOptions.UserId)
  const isFindBySelectFocused = useRef(false)
  const destinationAccountId = watch('destinationAccountId')
  const buttonText = isSubmitting ? I18n.t('Selecting...') : I18n.t('Select')

  const handleFormSubmit: SubmitHandler<FormValues> = async ({destinationUserId}) => {
    if (sourceUserId === destinationUserId) {
      showFlashError(I18n.t("You can't merge an account with itself."))()
      return
    }

    try {
      const user = await fetchUserWithRelations(destinationUserId)

      queryClient.setQueryData(createUserToMergeQueryKey(destinationUserId), user)

      onFind(destinationUserId)
    } catch (error: any) {
      if (error?.response?.status === 404) {
        showFlashError(I18n.t('No active user with that ID was found.'))()
      } else {
        showFlashError(I18n.t('Failed to load user to merge. Please try again later.'))()
      }
    }
  }

  let content

  if (isLoading && !sourceUser) {
    content = (
      <Spinner renderTitle={I18n.t('Loading source user...')} size="large" margin="large auto" />
    )
  } else if (isError) {
    content = (
      <Alert variant="error">
        {I18n.t('Failed to load user to merge. Please try again later.')}
      </Alert>
    )
  } else if (sourceUser) {
    content = (
      <>
        <Text
          dangerouslySetInnerHTML={{
            __html: raw(
              I18n.t('Merge <b>%{userName} %{userEmail}</b> into the selected user.', {
                userName: sourceUser.name,
                userEmail: sourceUser.email ? `(${sourceUser.email})` : '',
              }),
            ),
          }}
        />
        <Flex
          as="form"
          margin="large 0 0 0"
          wrap="wrap"
          gap="medium"
          alignItems="start"
          noValidate={true}
          onSubmit={handleSubmit(handleFormSubmit)}
        >
          {accountSelectOptions.length && (
            <SimpleSelect
              ref={ref => {
                ref?.focus()
                isFindBySelectFocused.current = true
              }}
              data-testid="find-by-select"
              renderLabel={I18n.t('Find by')}
              onChange={(_, {value}) => {
                const currentFindBy = value as FindByOptions

                setFindBy(currentFindBy)

                reset({
                  destinationUserId: '',
                  destinationAccountId:
                    currentFindBy === FindByOptions.UserId
                      ? undefined
                      : `${accountSelectOptions[0].id}`,
                })
              }}
            >
              <SimpleSelect.Option id={`${FindByOptions.UserId}`} value={FindByOptions.UserId}>
                {I18n.t('User ID')}
              </SimpleSelect.Option>
              <SimpleSelect.Option id={`${FindByOptions.Name}`} value={FindByOptions.Name}>
                {I18n.t('Name')}
              </SimpleSelect.Option>
            </SimpleSelect>
          )}
          {findBy === FindByOptions.UserId ? (
            <Controller
              control={control}
              name="destinationUserId"
              render={({field}) => (
                <TextInput
                  {...field}
                  ref={ref => {
                    field.ref(ref)

                    if (!isFindBySelectFocused.current) {
                      ref?.focus()
                    }
                  }}
                  isRequired={true}
                  renderLabel={I18n.t('User ID')}
                  placeholder={I18n.t('Enter user ID')}
                  width="300px"
                  messages={getFormErrorMessage(errors, 'destinationUserId')}
                />
              )}
            />
          ) : (
            <>
              <Controller
                control={control}
                name="destinationAccountId"
                render={({field}) => (
                  <SimpleSelect
                    {...field}
                    renderLabel={I18n.t('Root Account')}
                    onChange={(_, {value}) => {
                      reset({destinationUserId: '', destinationAccountId: `${value}`})
                    }}
                  >
                    {accountSelectOptions.map(({id, name}) => (
                      <SimpleSelect.Option key={id} id={id} value={id}>
                        {name}
                      </SimpleSelect.Option>
                    ))}
                  </SimpleSelect>
                )}
              />
              <Controller
                control={control}
                name="destinationUserId"
                render={({field: {ref, ...fieldWithoutRef}}) => (
                  <AutoCompleteSelect<User>
                    {...fieldWithoutRef}
                    isRequired={true}
                    key={destinationAccountId}
                    maxLength={255}
                    inputRef={ref}
                    renderLabel={I18n.t('User')}
                    placeholder={I18n.t('Enter a user name')}
                    assistiveText={I18n.t('Type to search')}
                    url={`/api/v1/accounts/${destinationAccountId}/users`}
                    renderOptionLabel={option => option.name}
                    renderBeforeInput={<IconUserLine inline={false} />}
                    onInputChange={event => {
                      fieldWithoutRef.onChange(event)
                    }}
                    onRequestSelectOption={(_, {id}) => {
                      fieldWithoutRef.onChange(id)
                    }}
                    messages={getFormErrorMessage(errors, 'destinationUserId')}
                  />
                )}
              />
            </>
          )}
          <Flex.Item margin="xx-small 0 0 0">
            <Button
              type="submit"
              color="secondary"
              margin="medium 0 0 0"
              disabled={isSubmitting}
              aria-label={buttonText}
            >
              {buttonText}
            </Button>
          </Flex.Item>
        </Flex>
      </>
    )
  }

  return (
    <Flex direction="column">
      <Heading level="h1" margin="0 0 small 0">
        {I18n.t('Merge Users')}
      </Heading>
      {content}
    </Flex>
  )
}

export default FindUserToMerge
