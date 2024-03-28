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
import React, {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {TextInput} from '@instructure/ui-text-input'
import {Table} from '@instructure/ui-table'
import {Flex} from '@instructure/ui-flex'
import {createAnalyticPropsGenerator} from './util/analytics'
import {TempEnrollAvatar} from './TempEnrollAvatar'
import type {User, DuplicateUser} from './types'
import {EMPTY_USER, MODULE_NAME} from './types'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

declare const ENV: GlobalEnv

const I18n = useI18nScope('temporary_enrollment')

// initialize analytics props
const analyticProps = createAnalyticPropsGenerator(MODULE_NAME)

interface Props {
  user: User
  page: number
  searchFail: Function
  searchSuccess: Function
  canReadSIS?: boolean
  foundUser?: User | null
  wasReset?: boolean
}

export function TempEnrollSearch(props: Props) {
  // 'cc_path' | 'unique_id' | 'sis_user_id'
  const [searchType, setSearchType] = useState('cc_path')
  const [message, setMessage] = useState('')
  const [loading, setLoading] = useState(false)
  const [search, setSearch] = useState('')
  const [userDetails, setUserDetails] = useState<User>(EMPTY_USER)
  const [duplicateUsers, setDuplicateUsers] = useState<DuplicateUser[]>([])
  const [selectedDuplicateUser, setSelectedDuplicateUser] = useState<DuplicateUser>({
    user_id: '',
    user_name: '',
  })

  const handleSearchTypeChange = (_event: ChangeEvent<HTMLInputElement>, value: string) => {
    setSearchType(value)
  }

  const handleSearchChange = (event: ChangeEvent<HTMLInputElement>) => {
    if (event.target !== null) {
      setSearch(event.target.value)
    }
  }

  const handleDuplicateUserSelection = (event: ChangeEvent<HTMLElement>) => {
    const target = event.target as HTMLTextAreaElement
    const selection = duplicateUsers.find((dupeUser: DuplicateUser) => {
      if (dupeUser.user_id === target.value) {
        return dupeUser
      }
      return null
    })
    if (selection) {
      const attrs = {
        id: selection.user_id,
        name: selection.user_name,
        primary_email: selection.email,
        login_id: selection.login_id,
        sis_user_id: selection.sis_user_id,
      }
      setSelectedDuplicateUser({user_id: selection.user_id, user_name: selection.user_name})
      props.searchSuccess(attrs)
    }
  }

  // user_lists.json does not always return email, sis id, and login
  const fetchUserDetails = async (user: User) => {
    try {
      const {json} = await doFetchApi({
        path: `/api/v1/users/${user.user_id}/profile`,
        method: 'GET',
      })
      setUserDetails(json)
      setMessage('')
      props.searchSuccess(json)
    } catch (error: any) {
      setMessage(error)
      setUserDetails(EMPTY_USER)
      props.searchFail()
    } finally {
      setLoading(false)
    }
  }

  const processSearchApiResponse = (response: any) => {
    if (response.users.length > 0) {
      const foundUser = response.users[0]
      if (typeof foundUser === 'undefined') {
        setMessage(I18n.t('User could not be found.'))
        setUserDetails(EMPTY_USER)
        props.searchFail()
        setLoading(false)
      } else if (response.users.length === 1 && foundUser.user_id !== props.user.id) {
        fetchUserDetails(foundUser)
      } else {
        setMessage(
          I18n.t('The user found matches the provider. Please search for a new recipient user.')
        )
        setUserDetails(EMPTY_USER)
        props.searchFail()
        setLoading(false)
      }
    } else if (response.duplicates.length > 0) {
      setDuplicateUsers(response.duplicates[0])
      setLoading(false)
    }
  }

  useEffect(() => {
    if (props.wasReset) {
      setMessage('')
      setSelectedDuplicateUser({user_id: '', user_name: ''})
      setUserDetails(EMPTY_USER)
    }
    if (props.page === 1 && !props.foundUser) {
      setLoading(true)

      const findUser = async () => {
        try {
          const {json} = await doFetchApi({
            path: `/accounts/${ENV.ACCOUNT_ID}/user_lists.json`,
            method: 'POST',
            params: {user_list: search, v2: true, search_type: searchType},
          })
          processSearchApiResponse(json)
        } catch (error: any) {
          setMessage(error.message)
          setUserDetails(EMPTY_USER)

          props.searchFail()

          setLoading(false)
        }
      }

      findUser()
    } else if (props.foundUser) {
      setUserDetails({...props.foundUser})
    }
    // useEffect hook should only be triggered when page is changed
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.page])

  let exampleText = ''
  let labelText = ''
  let descText = ''

  switch (searchType) {
    case 'cc_path':
      exampleText = 'lsmith@myschool.edu'
      descText = I18n.t('Enter the email address of the user you would like to temporarily enroll')
      labelText = I18n.t('Email Address')
      break
    case 'unique_id':
      exampleText = 'lsmith'
      descText = I18n.t('Enter the login ID of the user you would like to temporarily enroll')
      labelText = I18n.t('Login ID')
      break
    case 'sis_user_id':
      exampleText = 'student_2708'
      descText = I18n.t('Enter the SIS ID of the user you would like to temporarily enroll')
      labelText = I18n.t('SIS ID')
      break
  }

  if (loading) {
    return (
      <Flex justifyItems="center" alignItems="center">
        <Spinner renderTitle={I18n.t('Retrieving user information')} />
      </Flex>
    )
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
              {I18n.t('Find a recipient of temporary enrollments from %{name}', {
                name: props.user.name,
              })}
            </Text>
          </Flex.Item>
        </Flex>
      </Flex.Item>
    )
  }

  const renderDupeList = () => {
    const list = duplicateUsers.map((dupeUser: DuplicateUser, i: number) => {
      const k = `dupeuser_${i}`
      const checked = selectedDuplicateUser.user_id === dupeUser.user_id
      return (
        <Table.Row key={k}>
          <Table.RowHeader>
            <RadioInput
              value={dupeUser.user_id}
              name={dupeUser.user_name}
              onChange={handleDuplicateUserSelection}
              checked={checked}
              label={
                <ScreenReaderContent>
                  {I18n.t('Click to select user %{name}', {name: dupeUser.user_name})}
                </ScreenReaderContent>
              }
            />
          </Table.RowHeader>
          <Table.Cell>{dupeUser.user_name}</Table.Cell>
          <Table.Cell>{dupeUser.email}</Table.Cell>
          <Table.Cell>{dupeUser.login_id}</Table.Cell>
          {props.canReadSIS ? <Table.Cell>{dupeUser.sis_user_id || ''}</Table.Cell> : null}
          <Table.Cell>{dupeUser.account_name || ''}</Table.Cell>
        </Table.Row>
      )
    })
    return list
  }

  const renderDuplicates = () => {
    return (
      <div>
        <Table
          caption={
            <Text>
              {I18n.t('Possible matches for "%{searchType}". Select the desired one below.', {
                searchType: labelText,
              })}
            </Text>
          }
        >
          <Table.Head>
            <Table.Row>
              <Table.ColHeader id="dupesection-select">
                <ScreenReaderContent>{I18n.t('User Selection')}</ScreenReaderContent>
              </Table.ColHeader>
              <Table.ColHeader id="dupesection-name">{I18n.t('Name')}</Table.ColHeader>
              <Table.ColHeader id="dupesection-email">{I18n.t('Email Address')}</Table.ColHeader>
              <Table.ColHeader id="dupesection-loginid">{I18n.t('Login ID')}</Table.ColHeader>
              {props.canReadSIS ? (
                <Table.ColHeader id="dupesection-sisid">{I18n.t('SIS ID')}</Table.ColHeader>
              ) : null}
              <Table.ColHeader id="dupesection-inst">{I18n.t('Institution')}</Table.ColHeader>
            </Table.Row>
          </Table.Head>
          <Table.Body>{renderDupeList()}</Table.Body>
        </Table>
      </div>
    )
  }

  if (props.page === 1 && userDetails?.name !== '') {
    // user confirmation page
    return (
      <Flex gap="medium" direction="column">
        {renderSubHeader()}
        <Flex.Item shouldGrow={true}>
          <Alert variant="success" margin="0">
            {I18n.t('%{name} is ready to be assigned temporary enrollments.', {
              name: userDetails.name,
            })}
          </Alert>
        </Flex.Item>
        <Flex.Item shouldGrow={true}>
          <Table caption={<ScreenReaderContent>{I18n.t('User information')}</ScreenReaderContent>}>
            <Table.Head>
              <Table.Row>
                <Table.ColHeader id="usertable-name">{I18n.t('Name')}</Table.ColHeader>
                <Table.ColHeader id="usertable-email">{I18n.t('Email Address')}</Table.ColHeader>
                <Table.ColHeader id="usertable-loginid">{I18n.t('Login ID')}</Table.ColHeader>
                {props.canReadSIS ? (
                  <Table.ColHeader id="usertable-sisid">{I18n.t('SIS ID')}</Table.ColHeader>
                ) : null}
              </Table.Row>
            </Table.Head>
            <Table.Body>
              <Table.Row>
                <Table.RowHeader>{userDetails.name}</Table.RowHeader>
                <Table.Cell>{userDetails.primary_email}</Table.Cell>
                <Table.Cell>{userDetails.login_id}</Table.Cell>
                {props.canReadSIS ? <Table.Cell>{userDetails.sis_user_id}</Table.Cell> : null}
              </Table.Row>
            </Table.Body>
          </Table>
        </Flex.Item>
      </Flex>
    )
  } else if (props.page === 1 && duplicateUsers?.length > 0) {
    return (
      <Flex gap="medium" direction="column">
        {renderSubHeader()}
        <Flex.Item shouldGrow={true}>
          <Alert variant="warning" margin="0">
            {I18n.t(
              'Multiple users with the same %{search_type} were found. Please select desired user from the list below.',
              {
                search_type: labelText,
              }
            )}
          </Alert>
        </Flex.Item>
        {renderDuplicates()}
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
            description={I18n.t('Add recipient by')}
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
          <TextInput
            renderLabel={
              <>
                {labelText}
                <ScreenReaderContent>{descText}</ScreenReaderContent>
              </>
            }
            value={search}
            placeholder={exampleText}
            onChange={handleSearchChange}
            {...analyticProps('TextInput')}
          />
        </Flex.Item>
      </Flex>
    )
  }
}
