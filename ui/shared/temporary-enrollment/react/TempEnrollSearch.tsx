/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import type {ChangeEvent} from 'react'
import React, {useEffect, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {TextArea} from '@instructure/ui-text-area'
import {Flex} from '@instructure/ui-flex'
import {createAnalyticPropsGenerator} from './util/analytics'
import {TempEnrollAvatar} from './TempEnrollAvatar'
import type {User, DuplicateUser} from './types'
import {MODULE_NAME} from './types'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import {TempEnrollSearchConfirmation} from './TempEnrollSearchConfirmation'

declare const ENV: GlobalEnv

const I18n = createI18nScope('temporary_enrollment')

// initialize analytics props
const analyticProps = createAnalyticPropsGenerator(MODULE_NAME)

interface Props {
  user: User
  page: number
  searchFail: () => void
  searchSuccess: (enrollments: User[]) => void
  canReadSIS: boolean
  foundUsers: User[]
  wasReset?: boolean
  duplicateReq: boolean
}

export function TempEnrollSearch(props: Props) {
  // 'cc_path' | 'unique_id' | 'sis_user_id'
  const [searchType, setSearchType] = useState('cc_path')
  const [message, setMessage] = useState('')
  const [loading, setLoading] = useState(false)
  const [search, setSearch] = useState('')
  const [searchMessage, setSearchMessage] = useState('')
  const [duplicateUsers, setDuplicateUsers] = useState<Record<string, DuplicateUser[]>>({})
  const [foundUsers, setFoundUsers] = useState<User[]>(props.foundUsers)
  const textAreaRef = useRef<TextArea | null>(null)

  const handleSearchTypeChange = (_event: ChangeEvent<HTMLInputElement>, value: string) => {
    setSearchType(value)
  }

  const handleSearchChange = (event: ChangeEvent<HTMLInputElement>) => {
    if (event.target !== null) {
      const searchValue = event.target.value
      setSearch(searchValue)
      setSearchMessage('')
    }
  }

  const handleSearchBlur = () => {
    if (search.length === 0) {
      setSearchMessage(I18n.t('Search value is required.'))
    }
  }

  const processSearchApiResponse = (response: any) => {
    const foundUserList = response.users
    // MISSING OR NO USERS
    const hasNoUsers = response.duplicates.length === 0 && foundUserList === 0
    const isUndefined = typeof response.users[0] === 'undefined' && response.duplicates.length === 0
    if (response.missing.length > 0 || hasNoUsers || isUndefined) {
      // failed search; users were not found
      setMessage(I18n.t('A user could not be found.'))
      props.searchFail()
      return
    }

    // DUPLICATES
    const map: Record<string, DuplicateUser[]> = {}
    response.duplicates.forEach((dupePair: DuplicateUser[]) => {
      const key = dupePair[0].address
      // get dupe sets without provider if included
      const withoutProvider = dupePair.filter(dupeUser => {
        return dupeUser.user_id !== props.user.id
      })
      // if a dupe set is length of 1, add to foundList
      if (withoutProvider.length === 1) {
        foundUserList.push(withoutProvider[0])
      } else {
        map[key] = withoutProvider
      }
    })
    setDuplicateUsers(map)

    // FOUND USERS
    if (containsProvider(foundUserList)) {
      setMessage(
        I18n.t('One of the users found matches the provider. Please search for a different user.'),
      )
      props.searchFail()
      return
    }
    setFoundUsers(foundUserList)
    setMessage('')
  }

  const containsProvider = (userList: User[]) => {
    return userList.some(user => user.user_id === props.user.id)
  }

  useEffect(() => {
    if (props.page === 1 && props.foundUsers.length === 0) {
      if (search.length === 0) {
        textAreaRef.current?.focus()
        props.searchFail()
        return
      }
      setLoading(true)
      const findUser = async () => {
        try {
          const searchArray = search.split(',')
          const searchFirst = searchArray
          const {json} = await doFetchApi({
            path: `/accounts/${ENV.ACCOUNT_ID}/user_lists.json`,
            method: 'POST',
            params: {user_list: searchFirst, v2: true, search_type: searchType},
          })
          processSearchApiResponse(json)
        } catch (error: any) {
          setMessage(error.message)
          props.searchFail()
        }
        setLoading(false)
      }
      findUser()
    } else if (props.page === 1 && props.foundUsers.length > 0) {
      setFoundUsers(props.foundUsers)
    } else {
      setDuplicateUsers({})
    }
    // useEffect hook should only be triggered when page is changed
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.page])

  let exampleText = ''
  let labelText = ''
  let descText = ''

  switch (searchType) {
    case 'cc_path':
      exampleText = 'lsmith@myschool.edu, mfoster@myschool.edu'
      descText = I18n.t(
        'Enter the email addresses of the users you would like to temporarily enroll',
      )
      labelText = I18n.t('Email Addresses')
      break
    case 'unique_id':
      exampleText = 'lsmith, mfoster'
      descText = I18n.t('Enter the login IDs of the users you would like to temporarily enroll')
      labelText = I18n.t('Login IDs')
      break
    case 'sis_user_id':
      exampleText = 'student_2708, student_3693'
      descText = I18n.t('Enter the SIS IDs of the users you would like to temporarily enroll')
      labelText = I18n.t('SIS IDs')
      break
  }

  const renderSubHeader = () => {
    return (
      <Flex.Item>
        <Flex gap="x-small" direction="column">
          <Flex.Item>
            <TempEnrollAvatar user={props.user} />
          </Flex.Item>
          <Flex.Item shouldGrow={true}>
            <Text weight="bold">
              {I18n.t('Find recipient(s) of temporary enrollments from %{name}', {
                name: props.user.name,
              })}
            </Text>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    )
  }

  const duplicateCount = Object.keys(duplicateUsers).length
  if (loading) {
    return (
      <Flex justifyItems="center" alignItems="center">
        <Spinner renderTitle={I18n.t('Retrieving user information')} />
      </Flex>
    )
  } else if (props.page === 1 && (foundUsers.length > 0 || duplicateCount > 0)) {
    return (
      <Flex gap="medium" direction="column">
        {renderSubHeader()}
        <TempEnrollSearchConfirmation
          foundUsers={foundUsers}
          duplicateUsers={duplicateUsers}
          searchFailure={props.searchFail}
          readySubmit={(enrollments: User[]) => props.searchSuccess(enrollments)}
          canReadSIS={props.canReadSIS}
          duplicateReq={props.duplicateReq}
        />
      </Flex>
    )
  } else {
    return (
      <Flex gap="medium" direction="column">
        {renderSubHeader()}
        {message && (
          <Flex.Item shouldGrow={true}>
            <Alert variant="error" margin="0">
              {message}
            </Alert>
          </Flex.Item>
        )}
        <Flex.Item shouldGrow={true} overflowY="visible">
          <RadioInputGroup
            name="search_type"
            defaultValue={searchType}
            description={I18n.t('Add recipient(s) by')}
            onChange={handleSearchTypeChange}
            layout="columns"
          >
            <RadioInput
              id="peoplesearch_radio_cc_path"
              key="cc_path"
              value="cc_path"
              label={I18n.t('Email Address')}
              {...analyticProps('EmailAddress')}
            />
            <RadioInput
              id="peoplesearch_radio_unique_id"
              key="unique_id"
              value="unique_id"
              label={I18n.t('Login ID')}
              {...analyticProps('LoginID')}
            />
            {props.canReadSIS ? (
              <RadioInput
                id="peoplesearch_radio_sis_user_id"
                key="sis_user_id"
                value="sis_user_id"
                label={I18n.t('SIS ID')}
                {...analyticProps('SISID')}
              />
            ) : null}
          </RadioInputGroup>
        </Flex.Item>
        <Flex.Item overflowY="visible">
          <TextArea
            required={true}
            label={
              <>
                {labelText}
                <ScreenReaderContent>{descText}</ScreenReaderContent>
              </>
            }
            autoGrow={false}
            resize="vertical"
            height="9em"
            value={search}
            placeholder={exampleText}
            // @ts-expect-error
            onChange={handleSearchChange}
            onBlur={handleSearchBlur}
            ref={ref => (textAreaRef.current = ref)}
            messages={searchMessage === '' ? [] : [{type: 'newError', text: searchMessage}]}
            data-testid="search_area"
          />
        </Flex.Item>
      </Flex>
    )
  }
}
