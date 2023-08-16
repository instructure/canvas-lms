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

import React, {useEffect, useMemo, useState} from 'react'
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
import {EnrollmentTree, NodeStructure} from './EnrollmentTree'
import {Flex} from '@instructure/ui-flex'
import {unstable_batchedUpdates} from 'react-dom'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'

interface Role {
  id: string
  base_role_name: string
}
interface SelectedEnrollment {
  course: string
  section: string
}
interface Permissions {
  teacher: boolean
  ta: boolean
  student: boolean
  observer: boolean
  designer: boolean
}
interface Props {
  readonly enrollment: any
  readonly user: {
    name: string
    avatar_url?: string
    id: string
  }
  readonly permissions: Permissions
  readonly roles: {id: string; label: string; base_role_name: string}[]
  readonly goBack: Function
  readonly doSubmit: () => boolean
  readonly setEnrollmentStatus: Function
}
interface RoleChoice {
  id: string
  baseRoleName: string
}

type RoleName =
  | 'StudentEnrollment'
  | 'TaEnrollment'
  | 'TeacherEnrollment'
  | 'DesignerEnrollment'
  | 'ObserverEnrollment'
type PermissionName = 'teacher' | 'ta' | 'student' | 'observer' | 'designer'

const I18n = useI18nScope('temporary_enrollment')
// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
// @ts-expect-error
const FlexItem = Flex.Item as any
const rolePermissionMapping: Record<RoleName, PermissionName> = {
  StudentEnrollment: 'student',
  TaEnrollment: 'ta',
  TeacherEnrollment: 'teacher',
  DesignerEnrollment: 'designer',
  ObserverEnrollment: 'observer',
}

function removeStringSuffix(mainString: string, suffix: string): string {
  if (mainString.endsWith(suffix)) {
    return mainString.slice(0, -suffix.length)
  }
  return mainString
}

function getDayBoundaries(date = new Date()) {
  const start = new Date(date)
  const end = new Date(date)

  start.setHours(0, 0, 0, 0)
  end.setHours(24, 0, 0, 0)

  return [start, end]
}

export function TempEnrollAssign(props: Props) {
  const roleOptions = []

  const [roleChoice, setRoleChoice] = useState<RoleChoice>({
    id: '',
    baseRoleName: '',
  })
  const [errorMsg, setErrorMsg] = useState('')
  const [listEnroll, setListEnroll] = useState<{}[]>([])
  const [loading, setLoading] = useState(true)
  const [startDate, setStartDate] = useState(getDayBoundaries()[0])
  const [endDate, setEndDate] = useState(getDayBoundaries()[1])

  // using useMemo to compute and memoize roleLabel thus avoiding unnecessary re-renders
  const roleLabel = useMemo(() => {
    const selectedRole = props.roles.find(role => role.id === roleChoice.id)

    return selectedRole ? selectedRole.label : I18n.t('ROLE')
  }, [props.roles, roleChoice.id])

  const formatDateTime = useDateTimeFormat('date.formats.full_with_weekday')

  useEffect(() => {
    if (endDate.getTime() <= startDate.getTime()) {
      setErrorMsg(I18n.t('The start date must be before the end date'))
    } else if (errorMsg !== '') {
      setErrorMsg('')
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [endDate, startDate])

  useEffect(() => {
    const fetchData = async () => {
      try {
        setErrorMsg('')

        const result = await doFetchApi({
          path: `/api/v1/users/${props.user.id}/enrollments`,
          params: {state: ['active', 'completed', 'invited']},
        })

        setListEnroll([...result.json])
      } catch (error) {
        // eslint-disable-next-line no-console
        console.error('User enrollments API request error:', error)

        setErrorMsg(
          I18n.t('There was an error while requesting user enrollments, please try again')
        )
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [props.user.id])

  function handleRoleSearchChange(event: React.ChangeEvent, selectedOption: {id: string}) {
    const foundRole: Role | undefined = props.roles.find(role => role.id === selectedOption.id)
    const baseRoleName = foundRole ? removeStringSuffix(foundRole.base_role_name, 'Enrollment') : ''

    setRoleChoice({
      id: selectedOption.id,
      baseRoleName,
    })
  }

  function handleStartDateChange(event: React.SyntheticEvent<Element, Event>, dateValue?: string) {
    if (dateValue) {
      setStartDate(new Date(dateValue))
    }
  }

  function handleEndDateChange(event: React.SyntheticEvent<Element, Event>, dateValue?: string) {
    if (dateValue) {
      setEndDate(new Date(dateValue))
    }
  }

  function handleValidationError(message: string) {
    setErrorMsg(message)
    props.setEnrollmentStatus(false)
    setLoading(false)
  }

  function collectSelectedEnrollments(tree: NodeStructure[]): SelectedEnrollment[] {
    const selectedEnrolls: SelectedEnrollment[] = []

    for (const role in tree) {
      for (const course of tree[role].children) {
        for (const section of course.children) {
          // check if the section is selected, or if the course is selected and has only one section
          if (section.isCheck || (course.children.length === 1 && course.isCheck)) {
            // omitting the first character of the ID (assumed prefix)
            selectedEnrolls.push({
              course: course.id.slice(1),
              section: section.id.slice(1),
            })
          }
        }
      }
    }

    return selectedEnrolls
  }

  async function processEnrollments(submitEnrolls: SelectedEnrollment[]) {
    let success = true

    try {
      setErrorMsg('')
      const fetchPromises = submitEnrolls.map(enroll => createEnrollmentForSection(enroll))
      await Promise.all(fetchPromises)
    } catch (error) {
      setErrorMsg(I18n.t('Failed to create temporary enrollment, please try again'))
      success = false
    } finally {
      // using unstable_batchedUpdates to avoid getting the following error:
      // “Can't perform a React state update on an unmounted component”
      unstable_batchedUpdates(() => {
        props.setEnrollmentStatus(success)
        setLoading(false)
      })
    }
  }

  async function createEnrollmentForSection(enroll: SelectedEnrollment) {
    return doFetchApi({
      path: `/api/v1/sections/${enroll.section}/enrollments`,
      params: {
        enrollment: {
          user_id: props.enrollment.id,
          temporary_enrollment_source_user_id: props.user.id,
          start_at: startDate.toISOString(),
          end_at: endDate.toISOString(),
          role_id: roleChoice.id,
        },
      },
      method: 'POST',
    })
  }

  async function createTempEnroll(tree: NodeStructure[]) {
    setLoading(true)

    if (endDate.getTime() <= startDate.getTime()) {
      return handleValidationError(I18n.t('The start date must be before the end date'))
    }

    if (roleChoice.id === '') {
      return handleValidationError(I18n.t('Please select a role before submitting'))
    }

    const submitEnrolls = collectSelectedEnrollments(tree)

    if (submitEnrolls.length === 0) {
      return handleValidationError(
        I18n.t('Please select at least one enrollment before submitting')
      )
    }

    await processEnrollments(submitEnrolls)
  }

  for (const role of props.roles) {
    const permissionName = rolePermissionMapping[role.base_role_name as RoleName]

    if (permissionName) {
      const hasPermission = props.permissions[permissionName]

      if (hasPermission) {
        roleOptions.push(
          <RoleSearchSelect.Option
            key={role.id}
            id={role.id}
            value={role.id}
            label={role.label}
            aria-label={role.id}
          />
        )
      }
    }
  }

  if (loading) {
    return <Spinner renderTitle="Retrieving user enrollments" size="large" />
  }
  return (
    <>
      <Grid>
        <Grid.Row>
          <Grid.Col>
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
          <Grid.Col>
            <Flex margin="small 0 small 0">
              <FlexItem>
                <Avatar
                  size="small"
                  margin="0 small 0 0"
                  name={props.user.name}
                  src={props.user.avatar_url}
                  data-fs-exclude={true}
                  data-heap-redact-attributes="name"
                />
              </FlexItem>
              <FlexItem shouldShrink={true}>
                <Text>
                  {I18n.t('%{enroll} will receive temporary enrollments from %{user}', {
                    enroll: props.enrollment.name,
                    user: props.user.name,
                  })}
                </Text>
              </FlexItem>
            </Flex>
          </Grid.Col>
        </Grid.Row>
        {errorMsg && (
          <Grid.Row>
            <Grid.Col width={10}>
              <Alert variant="error">{errorMsg}</Alert>
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
              onChange={handleStartDateChange}
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
              label={I18n.t('Select role')}
              value={roleChoice.id}
              onChange={handleRoleSearchChange}
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
              onChange={handleEndDateChange}
              invalidDateTimeMessage={I18n.t('The chosen date and time is invalid.')}
            />
          </Grid.Col>
        </Grid.Row>
        <Grid.Row>
          <Grid.Col>
            <Text as="p" data-testid="temp-enroll-summary">
              {I18n.t(
                "Canvas will enroll %{recipient} as a %{role} in %{source}'s selected courses from %{start} - %{end}",
                {
                  recipient: props.enrollment.name,
                  role: roleLabel,
                  source: props.user.name,
                  start: formatDateTime(startDate),
                  end: formatDateTime(endDate),
                }
              )}
            </Text>
          </Grid.Col>
        </Grid.Row>
      </Grid>
      {props.doSubmit() ? (
        <EnrollmentTree
          list={listEnroll}
          roles={props.roles}
          selectedRole={roleChoice}
          createEnroll={createTempEnroll}
        />
      ) : (
        <EnrollmentTree list={listEnroll} roles={props.roles} selectedRole={roleChoice} />
      )}
    </>
  )
}
