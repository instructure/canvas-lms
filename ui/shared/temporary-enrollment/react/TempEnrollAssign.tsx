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
import React, {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
// @ts-ignore
import {Avatar} from '@instructure/ui-avatar'
// @ts-ignore
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
// @ts-ignore
import {Grid} from '@instructure/ui-grid'
import {Text} from '@instructure/ui-text'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Spinner} from '@instructure/ui-spinner'
import RoleSearchSelect from './RoleSearchSelect'
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'

const I18n = useI18nScope('temporary_enrollment')

interface Props {
  readonly enrollment: any
  readonly user: {
    name: string
    avatar_url?: string
    id: string
  }
  readonly permissions: {
    teacher: boolean
    ta: boolean
    student: boolean
    observer: boolean
    designer: boolean
  }
  readonly roles: {id: string; label: string; base_role_name: string}[]
  readonly goBack: Function
}

export function TempEnrollAssign(props: Props) {
  const [roleChoice, setRoleChoice] = useState('')
  const [dateMsg, setDateMsg] = useState('')
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [listEnroll, setListEnroll] = useState<{}[]>([])
  const [loading, setLoading] = useState(true)

  // setting default dates
  const defaultStart = new Date()
  const defaultEnd = new Date(defaultStart)
  defaultEnd.setDate(defaultEnd.getDate() + 1)
  defaultStart.setHours(0, 0, 0)
  defaultEnd.setHours(0, 0, 0)
  const [startDate, setStartDate] = useState(defaultStart)
  const [endDate, setEndDate] = useState(defaultEnd)

  const statesList = ['active', 'completed', 'invited']

  const handleEnrollments = (json: []) => {
    setListEnroll([...json])
  }

  useEffect(() => {
    if (endDate.getTime() <= startDate.getTime()) {
      setDateMsg(I18n.t('The start date must be before the end date'))
    } else {
      setDateMsg('')
    }
  }, [endDate, startDate])

  useEffect(() => {
    const getEnrollments = async () => {
      try {
        const {json} = await doFetchApi({
          path: `/api/v1/users/${props.user.id}/enrollments`,
          params: {state: statesList},
        })
        handleEnrollments(json)
      } finally {
        setLoading(false)
      }
    }
    getEnrollments()
    // only refresh when user updates
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.user.id])

  const roleOptions = []

  for (const r of props.roles) {
    let hasPermission
    switch (r.base_role_name) {
      case 'StudentEnrollment':
        hasPermission = props.permissions.student
        break
      case 'TaEnrollment':
        hasPermission = props.permissions.ta
        break
      case 'TeacherEnrollment':
        hasPermission = props.permissions.teacher
        break
      case 'DesignerEnrollment':
        hasPermission = props.permissions.designer
        break
      case 'ObserverEnrollment':
        hasPermission = props.permissions.observer
        break
      default:
        hasPermission = false
        break
    }
    if (hasPermission) {
      roleOptions.push(
        <RoleSearchSelect.Option
          key={r.id}
          id={r.id}
          value={r.id}
          label={r.label}
          aria-label={r.id}
        />
      )
    }
  }

  let roleLabel = props.roles.find(r => r.id === roleChoice)?.label
  if (roleLabel === undefined) {
    roleLabel = I18n.t('ROLE')
  }

  if (loading) {
    return <Spinner renderTitle="Retrieving user enrollments" size="large" />
  }
  return (
    <Grid>
      <Grid.Row>
        <Grid.Col width={1}>
          <Button
            onClick={() => {
              props.goBack()
            }}
          >
            {I18n.t('Back')}
          </Button>
        </Grid.Col>
      </Grid.Row>
      <Grid.Row vAlign="middle">
        <Grid.Col width={1}>
          <Avatar
            size="small"
            margin="small"
            name={props.user.name}
            src={props.user.avatar_url}
            data-fs-exclude={true}
            data-heap-redact-attributes="name"
          />
        </Grid.Col>
        <Grid.Col>
          <Text>
            {I18n.t('%{enroll} will receive temporary enrollments from %{user}', {
              enroll: props.enrollment.name,
              user: props.user.name,
            })}
          </Text>
        </Grid.Col>
      </Grid.Row>
      {dateMsg === '' ? null : (
        <Grid.Row>
          <Grid.Col width={10}>
            <Alert variant="error">{I18n.t('The end date must be after the start date')}</Alert>
          </Grid.Col>
        </Grid.Row>
      )}
      <Grid.Row vAlign="top">
        <Grid.Col width={8}>
          <DateTimeInput
            data-testId="start-date-input"
            layout="columns"
            isRequired={true}
            description={
              <ScreenReaderContent>
                {I18n.t('Start Date for %{enroll}', {enroll: props.enrollment.name})}
              </ScreenReaderContent>
            }
            dateRenderLabel={I18n.t('Begins On')}
            timeRenderLabel={I18n.t('Time')}
            prevMonthLabel={I18n.t('Prev')}
            nextMonthLabel={I18n.t('Next')}
            value={startDate.toISOString()}
            onChange={(e: any, value: any) => {
              setStartDate(new Date(value))
            }}
            invalidDateTimeMessage={I18n.t('The chosen date and time is invalid.')}
          />
        </Grid.Col>
        <Grid.Col>
          <RoleSearchSelect
            noResultsLabel={I18n.t('No roles available')}
            noSearchMatchLabel={I18n.t('')}
            id="termFilter"
            placeholder={I18n.t('Select a Role')}
            isLoading={false}
            label={I18n.t('Find Role')}
            value={roleChoice}
            onChange={(e: any) => setRoleChoice(e.target.id)}
          >
            {roleOptions}
          </RoleSearchSelect>
        </Grid.Col>
      </Grid.Row>
      <Grid.Row>
        <Grid.Col width={8}>
          <DateTimeInput
            data-testId="end-date-input"
            layout="columns"
            isRequired={true}
            description={
              <ScreenReaderContent>
                {I18n.t('End Date for %{enroll}', {enroll: props.enrollment.name})}
              </ScreenReaderContent>
            }
            dateRenderLabel={I18n.t('Until')}
            timeRenderLabel={I18n.t('Time')}
            prevMonthLabel={I18n.t('Prev')}
            nextMonthLabel={I18n.t('Next')}
            value={endDate.toISOString()}
            onChange={(e: any, value: any) => {
              setEndDate(new Date(value))
            }}
            invalidDateTimeMessage={I18n.t('The chosen date and time is invalid.')}
          />
        </Grid.Col>
      </Grid.Row>
      <Grid.Row>
        <Grid.Col>
          <Text>
            {I18n.t(
              "Canvas will enroll %{recipient} as a %{role} in %{source}'s selected courses from %{start} - %{end}",
              {
                recipient: props.enrollment.name,
                role: roleLabel,
                source: props.user.name,
                start: startDate.toLocaleString([], {
                  year: 'numeric',
                  month: 'numeric',
                  day: 'numeric',
                  hour: '2-digit',
                  minute: '2-digit',
                }),
                end: endDate.toLocaleString([], {
                  year: 'numeric',
                  month: 'numeric',
                  day: 'numeric',
                  hour: '2-digit',
                  minute: '2-digit',
                }),
              }
            )}
          </Text>
        </Grid.Col>
      </Grid.Row>
    </Grid>
  )
}
