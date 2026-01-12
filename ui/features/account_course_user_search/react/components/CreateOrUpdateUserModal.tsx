/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React, {useState, useRef, FormEvent} from 'react'
import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'

import {useScope as createI18nScope} from '@canvas/i18n'
import {
  firstNameFirst,
  lastNameFirst,
  nameParts,
} from '@canvas/user-sortable-name/jquery/user_utils'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import registrationErrors from '@canvas/normalize-registration-errors'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import TimeZoneSelect from '@canvas/datetime/react/components/TimeZoneSelect'
import doFetchApi, {FetchApiError} from '@canvas/do-fetch-api-effect'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {FormMessage} from '@instructure/ui-form-field'

const I18n = createI18nScope('account_course_user_search')

const trim = (str = '') => str.trim()

export type User = {
  name?: string
  sortable_name?: string
  short_name?: string
  email?: string
  time_zone?: string
}

type Pseudonym = {
  unique_id?: string
  path?: string
  sis_user_id?: string
  send_confirmation?: boolean
}

type NewUser = {
  user: {
    user: {
      id: string
      name: string
    }
  }
  pseudonym: Pseudonym
  message_sent: boolean
  course: string | null
}

type UpdatedUser = {
  id: string
  name: string
}

type FieldTypes =
  | 'user[name]'
  | 'user[short_name]'
  | 'user[sortable_name]'
  | 'user[email]'
  | 'user[time_zone]'
  | 'pseudonym[unique_id]'
  | 'pseudonym[path]'
  | 'pseudonym[sis_user_id]'
  | 'pseudonym[send_confirmation]'

const defaultErrors: Record<FieldTypes, string | undefined> = {
  'user[name]': undefined,
  'user[short_name]': undefined,
  'user[sortable_name]': undefined,
  'user[email]': undefined,
  'user[time_zone]': undefined,
  'pseudonym[unique_id]': undefined,
  'pseudonym[path]': undefined,
  'pseudonym[sis_user_id]': undefined,
  'pseudonym[send_confirmation]': undefined,
}

interface Props {
  open: boolean
  onClose: () => void
  createOrUpdate: 'create' | 'update'
  url: string
  user?: {
    name: string
    sortable_name?: string
    short_name?: string
    email?: string
    time_zone?: string
  }
  afterSave: () => void
}

declare const ENV: GlobalEnv & {
  customized_login_handle_name?: string
  delegated_authentication?: boolean
  SHOW_SIS_ID_IN_NEW_USER_FORM?: boolean
}

export default function CreateOrUpdateUserModal(props: Props) {
  const customized_login_handle_name = ENV.customized_login_handle_name
  const delegated_authentication = ENV.delegated_authentication
  const showSIS = ENV.SHOW_SIS_ID_IN_NEW_USER_FORM

  const nameRef = useRef<HTMLInputElement | null>(null)
  const uniqueRef = useRef<HTMLInputElement | null>(null)
  const pathRef = useRef<HTMLInputElement | null>(null)
  const emailRef = useRef<HTMLInputElement | null>(null)
  const sisRef = useRef<HTMLInputElement | null>(null)

  // we only want to populate some of the user fields
  const [userFields, setUserFields] = useState<User>(
    props.user
      ? {
          name: props.user.name,
          sortable_name: props.user.sortable_name,
          short_name: props.user.short_name,
          email: props.user.email,
          time_zone: props.user.time_zone,
        }
      : {},
  )
  const [pseudonymFields, setPseudonymFields] = useState<Pseudonym>({send_confirmation: true})
  const [errors, setErrors] = useState<Record<FieldTypes, string | undefined>>(defaultErrors)
  const [isLoading, setIsLoading] = useState(false)

  const getFieldValue = (field: FieldTypes) => {
    if (field.startsWith('user[')) {
      const fieldName = field.replace('user[', '').replace(']', '') as keyof User
      return userFields[fieldName]
    } else if (field.startsWith('pseudonym[')) {
      const fieldName = field.replace('pseudonym[', '').replace(']', '') as keyof Pseudonym
      return pseudonymFields[fieldName]
    }
  }

  const resetFields = () => {
    setUserFields(
      props.user
        ? {
            name: props.user.name,
            sortable_name: props.user.sortable_name,
            short_name: props.user.short_name,
            email: props.user.email,
            time_zone: props.user.time_zone,
          }
        : {},
    )
    setPseudonymFields({send_confirmation: true})
    setErrors(defaultErrors)
  }

  const updateUser = (userFields: User, field: FieldTypes, value: string | boolean) => {
    const fieldName = field.replace('user[', '').replace(']', '') as keyof User
    return {...userFields, [fieldName]: value}
  }

  const updatePseudonym = (
    pseudonymFields: Pseudonym,
    field: FieldTypes,
    value: string | boolean,
  ) => {
    const fieldName = field.replace('pseudonym[', '').replace(']', '') as keyof Pseudonym
    return {...pseudonymFields, [fieldName]: value}
  }

  const onChange = (field: FieldTypes, value: string | boolean) => {
    // set sensible defaults for sortable_name and short_name
    if (field.startsWith('user[')) {
      let updatedUser = updateUser(userFields, field, value)

      if (field === 'user[name]') {
        // shamelessly copypasted from user_sortable_name.js
        const sortableNameParts = nameParts(trim(updatedUser.sortable_name), undefined)
        if (
          !trim(updatedUser.sortable_name) ||
          trim(firstNameFirst(sortableNameParts)) === trim(userFields.name)
        ) {
          const newSortableName = lastNameFirst(nameParts(value, sortableNameParts[1]))
          updatedUser = updateUser(updatedUser, 'user[sortable_name]', newSortableName)
        }
        if (
          !trim(updatedUser.short_name) ||
          trim(updatedUser.short_name) === trim(userFields.name)
        ) {
          updatedUser = updateUser(updatedUser, 'user[short_name]', value)
        }
      }
      setUserFields(updatedUser)
    } else if (field.startsWith('pseudonym[')) {
      const updatedPseudonym = updatePseudonym(pseudonymFields, field, value)
      setPseudonymFields(updatedPseudonym)
    }
    runValidation(field, true, value)
  }

  const postUser = async (userData: User) => {
    const {json} = await doFetchApi<NewUser>({
      path: props.url,
      method: 'POST',
      body: {user: userData, pseudonym: pseudonymFields},
    })
    if (json) {
      // I can't explain why there's double user here, but it is what the API returns
      const userName = json.user.user.name
      const wrapper = `<a href='/users/${json.user.user.id}'>$1</a>`
      const message = json.message_sent
        ? I18n.t(
            '*%{userName}* saved successfully! They should receive an email confirmation shortly.',
            {userName, wrapper},
          )
        : I18n.t('*%{userName}* saved successfully!', {userName, wrapper})
      showFlashSuccess(message)()
    }
  }

  const putUser = async (userData: User) => {
    const {json} = await doFetchApi<UpdatedUser>({
      path: props.url,
      method: 'PUT',
      body: {user: userData},
    })
    if (json) {
      const userName = json.name || I18n.t('New user')
      const wrapper = `<a href='/users/${json.id}'>$1</a>`
      const message = I18n.t('*%{userName}* saved successfully!', {userName, wrapper})
      showFlashSuccess(message)()
    }
  }

  const onSubmit = async (event: FormEvent) => {
    event.preventDefault()
    // CoursesToolbar is wrapped in a form, so we need to stop propagation
    event.stopPropagation()

    const skipSubmit = hasErrors(false)
    if (skipSubmit) {
      return
    }
    setIsLoading(true)

    // exclude email if it's blank
    let userData: User = {...userFields}
    if (userData.email === '' || userData.email == null) {
      const {email, ...rest} = userData
      userData = rest
    }
    try {
      if (props.createOrUpdate === 'create') {
        await postUser(userData)
      } else {
        await putUser(userData)
      }
      resetFields()
      props.onClose()
      props.afterSave()
    } catch (error) {
      // if the error is a FetchApiError, it has a response with json.errors
      try {
        if (error instanceof FetchApiError) {
          const errorJson = await error.response.json()
          const fetchErrors = registrationErrors(errorJson.errors, undefined)
          setErrors(prevErrors => ({
            ...defaultErrors,
            ...prevErrors,
            ...fetchErrors,
          }))
        } else {
          showFlashError(I18n.t('Something went wrong saving user details'))(error as Error)
        }
      } catch (error) {
        // if we can't parse the error, flash a generic error message
        showFlashError(I18n.t('Something went wrong saving user details'))(error as Error)
      }
    } finally {
      setIsLoading(false)
    }
  }

  const hasErrors = (overrideError: boolean = true) => {
    let hasError = false
    const showCustomizedLoginId = customized_login_handle_name || delegated_authentication

    if (props.createOrUpdate === 'create' && showCustomizedLoginId) {
      if (runValidation('pseudonym[path]', overrideError) && pathRef.current) {
        hasError = true
        pathRef.current.focus()
      }
    }
    if (props.createOrUpdate === 'create') {
      if (runValidation('pseudonym[sis_user_id]', overrideError) && sisRef.current) {
        hasError = true
        sisRef.current.focus()
      }
      if (runValidation('pseudonym[unique_id]', overrideError) && uniqueRef.current) {
        hasError = true
        uniqueRef.current.focus()
      }
    } else {
      if (runValidation('user[email]', overrideError) && emailRef.current) {
        hasError = true
        emailRef.current.focus()
      }
    }
    if (runValidation('user[name]', overrideError) && nameRef.current) {
      hasError = true
      nameRef.current.focus()
    }
    const errorArray = Object.values(errors)
    const failed = errorArray.some(errorMsg => {
      return errorMsg !== undefined && errorMsg !== ''
    })
    return failed || hasError
  }

  const runValidation = (
    field: FieldTypes,
    overrideError: boolean,
    currentValue?: string | boolean,
  ) => {
    // return true/false after state is set
    let isInvalid = true
    const updatedValue = currentValue !== undefined ? currentValue : getFieldValue(field)
    // required fields are blank
    if (updatedValue === '' || updatedValue === undefined) {
      if (field === 'user[name]') {
        setErrors(prevErrors => ({...prevErrors, [field]: I18n.t('Name is required')}))
      } else if (field === 'pseudonym[unique_id]') {
        setErrors(prevErrors => ({...prevErrors, [field]: I18n.t('Email is required')}))
      } else if (field === 'pseudonym[path]') {
        const message = customized_login_handle_name
          ? I18n.t('%{login_handle} is required', {
              login_handle: customized_login_handle_name,
            })
          : I18n.t('Email is required')
        setErrors(prevErrors => ({...prevErrors, [field]: message}))
      } else {
        isInvalid = false
      }
      // email requires format validation
    } else if (field === 'user[email]' && typeof updatedValue === 'string') {
      // we are doing the same validation the backend does
      // so we are requiring a domain for the email
      const splitEmail = updatedValue.split('@')
      const domain = splitEmail.length > 1 ? splitEmail[1] : ''
      if (domain === '') {
        setErrors(prevErrors => ({
          ...prevErrors,
          [field]: I18n.t('Email is invalid'),
        }))
      } else {
        if (overrideError) {
          setErrors(prevErrors => ({...prevErrors, [field]: undefined}))
        }
        isInvalid = false
      }
    } else if (overrideError) {
      setErrors(prevErrors => ({...prevErrors, [field]: undefined}))
      isInvalid = false
    } else {
      // run the validation on existing value if we aren't overriding the error (aka submitting)
      const errorMsg = errors[field]
      isInvalid = errorMsg !== undefined
    }
    return isInvalid
  }

  // api responds with an array of errors, frontend validation are strings
  const renderMessage = (message: string | string[] | undefined): FormMessage[] => {
    if (message === undefined) return []
    if (Array.isArray(message)) {
      return message.map(msg => ({text: msg, type: 'newError'}))
    } else {
      return [{text: message, type: 'newError'}]
    }
  }

  const renderNameFields = () => {
    const nameField = 'user[name]'
    const shortField = 'user[short_name]'
    const sortField = 'user[sortable_name]'

    const nameErrors = renderMessage(errors[nameField])
    const nameHint: FormMessage[] = [
      {type: 'hint', text: I18n.t('This name will be used by teachers for grading.')},
    ]
    return (
      <>
        <TextInput
          data-testid="full-name"
          name={nameField}
          renderLabel={I18n.t('Full Name')}
          isRequired={true}
          onChange={e => {
            onChange(nameField, e.target.value)
          }}
          value={userFields.name?.toString() || ''}
          elementRef={el => {
            nameRef.current = el as HTMLInputElement
          }}
          messages={nameErrors.length > 0 ? nameErrors : nameHint}
        />
        <TextInput
          data-testid="short-name"
          name={shortField}
          renderLabel={I18n.t('Display Name')}
          onChange={e => {
            onChange(shortField, e.target.value)
          }}
          value={userFields.short_name?.toString() || ''}
          messages={[
            {
              type: 'hint',
              text: I18n.t('People will see this name in discussions, messages and comments'),
            },
          ]}
        />
        <TextInput
          data-testid="sortable-name"
          name={sortField}
          renderLabel={I18n.t('Sortable Name')}
          onChange={e => onChange(sortField, e.target.value)}
          value={userFields.sortable_name?.toString() || ''}
          messages={[{type: 'hint', text: I18n.t('This name appears in sorted lists')}]}
        />
      </>
    )
  }

  const renderCreateFields = () => {
    const showCustomizedLoginId = customized_login_handle_name || delegated_authentication
    const uniqueField = 'pseudonym[unique_id]'
    const pathField = 'pseudonym[path]'
    const sisField = 'pseudonym[sis_user_id]'
    const confirmationField = 'pseudonym[send_confirmation]'

    const emailErrors = renderMessage(errors[uniqueField])
    const sisErrors = renderMessage(errors[sisField])
    const emailHint: FormMessage[] = [
      {type: 'hint', text: I18n.t('This email will be used for login')},
    ]
    return (
      <>
        <TextInput
          name={uniqueField}
          data-testid="unique-id"
          renderLabel={customized_login_handle_name || I18n.t('Email')}
          isRequired={true}
          onChange={e => onChange(uniqueField, e.target.value)}
          value={pseudonymFields.unique_id?.toString() || ''}
          elementRef={el => {
            uniqueRef.current = el as HTMLInputElement
          }}
          messages={emailErrors.length > 0 ? emailErrors : emailHint}
        />
        {showCustomizedLoginId ? (
          <TextInput
            data-testid="path"
            name={pathField}
            renderLabel={I18n.t('Email')}
            isRequired={true}
            onChange={e => onChange(pathField, e.target.value)}
            value={pseudonymFields.path?.toString() || ''}
            elementRef={el => {
              pathRef.current = el as HTMLInputElement
            }}
          />
        ) : null}
        {showSIS ? (
          <TextInput
            data-testid="sis-id"
            name={sisField}
            renderLabel={I18n.t('SIS ID')}
            onChange={e => onChange(sisField, e.target.value)}
            value={pseudonymFields.sis_user_id?.toString() || ''}
            messages={sisErrors.length > 0 ? sisErrors : undefined}
            elementRef={el => {
              sisRef.current = el as HTMLInputElement
            }}
          />
        ) : null}
        <Checkbox
          data-testid="confirmation-checkbox"
          name={confirmationField}
          label={I18n.t('Email the user about this account creation')}
          onChange={e => onChange(confirmationField, e.target.checked)}
          checked={pseudonymFields.send_confirmation}
        />
      </>
    )
  }

  const renderUpdateFields = () => {
    const emailField = 'user[email]'
    const timeField = 'user[time_zone]'

    const emailErrors = renderMessage(errors[emailField])
    const emailHint: FormMessage[] = [
      {text: I18n.t('This email will be used for login.'), type: 'hint'},
    ]
    return (
      <>
        <TextInput
          data-testid="email"
          name={emailField}
          renderLabel={I18n.t('Default Email')}
          onChange={e => onChange(emailField, e.target.value)}
          value={userFields.email?.toString()}
          elementRef={el => {
            emailRef.current = el as HTMLInputElement
          }}
          messages={emailErrors.length > 0 ? emailErrors : emailHint}
        />
        <TimeZoneSelect
          data-testid="time-zone"
          id="timeZoneSelect"
          name={timeField}
          label={I18n.t('Time Zone')}
          timezones={TimeZoneSelect.defaultProps?.timezones || []}
          priority_zones={TimeZoneSelect.defaultProps?.priority_zones || []}
          onChange={(_e, value) => onChange(timeField, value)}
          value={userFields.time_zone || ''}
        />
      </>
    )
  }

  return (
    <>
      <Modal
        open={props.open}
        onDismiss={props.onClose}
        size="medium"
        label={
          props.createOrUpdate === 'create' ? I18n.t('Add a New User') : I18n.t('Edit User Details')
        }
      >
        <form style={{margin: '0px'}} onSubmit={onSubmit} noValidate={true}>
          <Modal.Body>
            <Flex gap="inputFields" direction="column">
              {renderNameFields()}
              {props.createOrUpdate === 'create' ? renderCreateFields() : renderUpdateFields()}
            </Flex>
          </Modal.Body>
          <Modal.Footer>
            <Flex gap="buttons">
              <Button data-testid="cancel-button" onClick={props.onClose} disabled={isLoading}>
                {I18n.t('Cancel')}
              </Button>
              <Button
                data-testid="submit-button"
                type="submit"
                color="primary"
                disabled={isLoading}
              >
                {props.createOrUpdate === 'create' ? I18n.t('Add User') : I18n.t('Save')}
              </Button>
            </Flex>
          </Modal.Footer>
        </form>
      </Modal>
    </>
  )
}
