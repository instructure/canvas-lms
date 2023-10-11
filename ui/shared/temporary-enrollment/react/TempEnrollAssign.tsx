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

import React, {
  ChangeEvent,
  Dispatch,
  SetStateAction,
  SyntheticEvent,
  useEffect,
  useMemo,
  useState,
} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Avatar} from '@instructure/ui-avatar'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
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
import {
  getDayBoundaries,
  getFromLocalStorage,
  removeStringAffix,
  safeDateConversion,
  updateLocalStorageObject,
} from './util/helpers'
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
    readonly name: string
    readonly avatar_url?: string
    readonly id: string
  }
  readonly permissions: Permissions
  readonly roles: {id: string; label: string; base_role_name: string}[]
  readonly goBack: Function
  readonly doSubmit: () => boolean
  readonly setEnrollmentStatus: Function
  readonly isInAssignEditMode: boolean
}
interface RoleChoice {
  id: string
  name: string
}
interface StoredData {
  roleChoice: RoleChoice
  startDate: Date
  endDate: Date
}

type RoleName =
  | 'StudentEnrollment'
  | 'TaEnrollment'
  | 'TeacherEnrollment'
  | 'DesignerEnrollment'
  | 'ObserverEnrollment'
type PermissionName = 'teacher' | 'ta' | 'student' | 'observer' | 'designer'

const I18n = useI18nScope('temporary_enrollment')
const rolePermissionMapping: Record<RoleName, PermissionName> = {
  StudentEnrollment: 'student',
  TaEnrollment: 'ta',
  TeacherEnrollment: 'teacher',
  DesignerEnrollment: 'designer',
  ObserverEnrollment: 'observer',
}

export const tempEnrollAssignData = 'tempEnrollAssignData'
const defaultRoleChoice: RoleChoice = {
  id: '',
  name: '',
}

// get data from local storage or set defaults
function getStoredData(): StoredData {
  // destructure result into local variables
  const [defaultStartDate, defaultEndDate] = getDayBoundaries()

  const defaultStoredData: StoredData = {
    roleChoice: defaultRoleChoice,
    // start and end Date of the current day
    startDate: defaultStartDate,
    endDate: defaultEndDate,
  }
  const rawStoredData: Partial<StoredData> =
    getFromLocalStorage<StoredData>(tempEnrollAssignData) || {}

  const parsedStartDate = safeDateConversion(rawStoredData.startDate)
  const parsedEndDate = safeDateConversion(rawStoredData.endDate)

  // return local data or defaults
  return {
    roleChoice: rawStoredData.roleChoice || defaultStoredData.roleChoice,
    startDate: parsedStartDate || defaultStoredData.startDate,
    endDate: parsedEndDate || defaultStoredData.endDate,
  }
}

export function TempEnrollAssign(props: Props) {
  const storedData = getStoredData()

  const [errorMsg, setErrorMsg] = useState('')
  const [listEnroll, setListEnroll] = useState<{}[]>([])
  const [loading, setLoading] = useState(true)
  const [startDate, setStartDate] = useState<Date>(storedData.startDate)
  const [endDate, setEndDate] = useState<Date>(storedData.endDate)
  const [roleChoice, setRoleChoice] = useState<RoleChoice>(storedData.roleChoice)

  const roleOptions = []

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

  /**
   * Handle change to date value in the DateTimeInput component
   *
   * Update the date state and localStorage values
   *
   * @param {SyntheticEvent<Element, Event>} event Event object
   * @param {Dispatch<SetStateAction<Date>>} setDateState React state setter
   * @param {string} localStorageKey localStorage key to update
   * @param {string} [dateValue] Optional date value, which may not be a valid date
   *                             (e.g. bad user input or corrupted localStorage value)
   * @returns {void}
   */
  const handleDateChange = (
    event: SyntheticEvent<Element, Event>,
    setDateState: Dispatch<SetStateAction<Date>>,
    localStorageKey: string,
    dateValue?: string
  ): void => {
    const validatedDate = safeDateConversion(dateValue)

    // only update state and localStorage if the date is valid
    if (validatedDate) {
      setDateState(validatedDate)
      updateLocalStorageObject(tempEnrollAssignData, {[localStorageKey]: validatedDate})
    } else {
      // eslint-disable-next-line no-console
      console.error('Invalid date in handleDateChange:', dateValue)
    }
  }

  const handleStartDateChange = (event: SyntheticEvent<Element, Event>, dateValue?: string) => {
    handleDateChange(event, setStartDate, 'startDate', dateValue)
  }

  const handleEndDateChange = (event: SyntheticEvent<Element, Event>, dateValue?: string) => {
    handleDateChange(event, setEndDate, 'endDate', dateValue)
  }

  const handleRoleSearchChange = (event: ChangeEvent, selectedOption: {id: string}) => {
    const foundRole: Role | undefined = props.roles.find(role => role.id === selectedOption.id)
    const name = foundRole ? removeStringAffix(foundRole.base_role_name, 'Enrollment') : ''

    setRoleChoice({
      id: selectedOption.id,
      name,
    })

    updateLocalStorageObject(tempEnrollAssignData, {
      roleChoice: {
        id: selectedOption.id,
        name,
      },
    })
  }

  const handleValidationError = (message: string) => {
    setErrorMsg(message)
    props.setEnrollmentStatus(false)
    setLoading(false)
  }

  const handleCollectSelectedEnrollments = (tree: NodeStructure[]): SelectedEnrollment[] => {
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

  const handleProcessEnrollments = async (submitEnrolls: SelectedEnrollment[]) => {
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

  const handleCreateTempEnroll = async (tree: NodeStructure[]) => {
    setLoading(true)

    if (endDate.getTime() <= startDate.getTime()) {
      return handleValidationError(I18n.t('The start date must be before the end date'))
    }

    if (roleChoice.id === '') {
      return handleValidationError(I18n.t('Please select a role before submitting'))
    }

    const submitEnrolls = handleCollectSelectedEnrollments(tree)

    if (submitEnrolls.length === 0) {
      return handleValidationError(
        I18n.t('Please select at least one enrollment before submitting')
      )
    }

    await handleProcessEnrollments(submitEnrolls)
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
        {!props.isInAssignEditMode && (
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
        )}
        <Grid.Row vAlign="middle">
          <Grid.Col>
            <Flex margin="small 0 small 0">
              <Flex.Item>
                <Avatar
                  size="small"
                  margin="0 small 0 0"
                  name={props.user.name}
                  src={props.user.avatar_url}
                  data-fs-exclude={true}
                  data-heap-redact-attributes="name"
                />
              </Flex.Item>
              <Flex.Item shouldShrink={true}>
                <Text>
                  {I18n.t('%{enroll} will receive temporary enrollments from %{user}', {
                    enroll: props.enrollment.name,
                    user: props.user.name,
                  })}
                </Text>
              </Flex.Item>
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
              data-testid="start-date-input"
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
              data-testid="end-date-input"
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
                'Canvas will enroll %{recipient} as a %{role} in %{source}’s selected courses from %{start} - %{end}',
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
          createEnroll={handleCreateTempEnroll}
        />
      ) : (
        <EnrollmentTree list={listEnroll} roles={props.roles} selectedRole={roleChoice} />
      )}
    </>
  )
}
