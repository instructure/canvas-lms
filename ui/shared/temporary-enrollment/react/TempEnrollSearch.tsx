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

import React, {ChangeEvent, useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Avatar} from '@instructure/ui-avatar'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'
import {Spinner} from '@instructure/ui-spinner'
import {TextInput} from '@instructure/ui-text-input'
import {Table} from '@instructure/ui-table'
import {Flex} from '@instructure/ui-flex'
import {createAnalyticPropsGenerator} from './util/analytics'
import {EMPTY_USER, MODULE_NAME, User} from './types'

const I18n = useI18nScope('temporary_enrollment')

// initialize analytics props
const analyticProps = createAnalyticPropsGenerator(MODULE_NAME)

interface Props {
  readonly user: User
  readonly page: number
  readonly searchFail: Function
  readonly searchSuccess: Function
  readonly canReadSIS?: boolean
  readonly accountId: string
  readonly foundEnroll?: User | null
}

export function TempEnrollSearch(props: Props) {
  // 'cc_path' | 'unique_id' | 'sis_user_id'
  const [searchType, setSearchType] = useState('cc_path')
  const [message, setMessage] = useState('')
  const [loading, setLoading] = useState(false)
  const [search, setSearch] = useState('')
  const [enrollment, setEnrollment] = useState<User>(EMPTY_USER)

  const handleSearchTypeChange = (event: ChangeEvent<HTMLInputElement>, value: string) => {
    setSearchType(value)
  }

  const handleSearchChange = (event: ChangeEvent<HTMLInputElement>) => {
    if (event.target !== null) {
      setSearch(event.target.value)
    }
  }

  // user_lists.json does not always return email, sis id, and login
  const fetchUserDetails = async (user: any) => {
    try {
      const {json} = await doFetchApi({
        path: `/api/v1/users/${user.user_id}`,
        method: 'GET',
      })
      setEnrollment(json)
      setMessage('')
      props.searchSuccess(json)
    } catch (error: any) {
      setMessage(error)
      setEnrollment(EMPTY_USER)
      props.searchFail()
    } finally {
      setLoading(false)
    }
  }

  const processSearchApiResponse = (response: any) => {
    const foundUser = response.users[0]
    if (typeof foundUser === 'undefined') {
      setMessage(I18n.t('User could not be found.'))
      setEnrollment(EMPTY_USER)
      props.searchFail()
      setLoading(false)
    } else if (response.users.length === 1 && foundUser.user_id !== props.user.id) {
      // api could return more than 1, which we don't want
      fetchUserDetails(foundUser)
    } else {
      setMessage(
        I18n.t('The user found matches the source user. Please search for a different user.')
      )
      setEnrollment(EMPTY_USER)
      props.searchFail()
      setLoading(false)
    }
  }

  const renderAvatar = () => {
    return (
      <>
        <Text weight="bold">
          {I18n.t('Find a recipient of temporary enrollments from %{name}', {
            name: props.user.name,
          })}
        </Text>

        <Flex margin="small 0 small 0">
          <Flex.Item>
            <Avatar
              size="large"
              margin="0 small 0 0"
              name={props.user.name}
              src={props.user.avatar_url}
              data-fs-exclude={true}
              data-heap-redact-attributes="name"
            />
          </Flex.Item>

          <Flex.Item shouldShrink={true}>
            <Text size="large">{props.user.name}</Text>
          </Flex.Item>
        </Flex>
      </>
    )
  }

  useEffect(() => {
    if (props.page === 1 && !props.foundEnroll) {
      setLoading(true)

      const findUser = async () => {
        try {
          const {json} = await doFetchApi({
            path: `/accounts/${props.accountId}/user_lists.json`,
            method: 'POST',
            params: {user_list: search, v2: true, search_type: searchType},
          })

          processSearchApiResponse(json)
        } catch (error: any) {
          setMessage(error.message)
          setEnrollment(EMPTY_USER)

          props.searchFail()

          setLoading(false)
        }
      }

      findUser()
    } else if (props.foundEnroll) {
      setEnrollment({...props.foundEnroll})
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

  if (props.page === 1 && enrollment.name !== '') {
    // user confirmation page
    return (
      <>
        {renderAvatar()}
        <Alert variant="success">
          {I18n.t('%{name} is ready to be assigned temporary enrollments.', {
            name: enrollment.name,
          })}
        </Alert>
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
              <Table.RowHeader>{enrollment.name}</Table.RowHeader>
              <Table.Cell>{enrollment.email}</Table.Cell>
              <Table.Cell>{enrollment.login_id}</Table.Cell>
              {props.canReadSIS ? <Table.Cell>{enrollment.sis_user_id}</Table.Cell> : null}
            </Table.Row>
          </Table.Body>
        </Table>
      </>
    )
  } else {
    return (
      <>
        {renderAvatar()}
        {message === '' ? <></> : <Alert variant="error">{message}</Alert>}
        <RadioInputGroup
          name="search_type"
          defaultValue={searchType}
          description={I18n.t('Find user by')}
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
        <fieldset style={{margin: '1rem 0'}}>
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
        </fieldset>
      </>
    )
  }
}
