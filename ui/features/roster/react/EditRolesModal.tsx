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
import {Role} from '@canvas/global/env/EnvCommon'
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import CanvasSelect from '@canvas/instui-bindings/react/Select'
import {useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Enrollment} from 'api'
import doFetchApi, {DoFetchApiResults} from '@canvas/do-fetch-api-effect'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('link_to_students')

export type RemovableEnrollment = Enrollment & {can_be_removed?: boolean}

interface Props {
  currentEnrollments: RemovableEnrollment[]
  availableRoles: Role[]
  userId: string
  onClose: () => void
  onSubmit: (newEnrollment: RemovableEnrollment[], deletedEnrollment: RemovableEnrollment[]) => void
}

export default function EditRolesModal(props: Props) {
  const {currentEnrollments, availableRoles, userId} = props
  const [isLoading, setIsLoading] = useState(false)
  const [roleId, setRoleId] = useState<string>(currentEnrollments[0].role_id)

  const deleteEnrollments = async (): Promise<RemovableEnrollment[]> => {
    const deleteEnrollments: Promise<DoFetchApiResults<{enrollment: RemovableEnrollment}>>[] = []
    currentEnrollments.forEach(enrollment => {
      if (roleId !== enrollment.role_id) {
        const deleteResponse = doFetchApi<{enrollment: RemovableEnrollment}>({
          path: `unenroll/${enrollment.id}`,
          method: 'DELETE',
        })
        deleteEnrollments.push(deleteResponse)
      }
    })
    const enrollmentResponses = await Promise.all(deleteEnrollments)
    return enrollmentResponses.map(response => response.json?.enrollment) as RemovableEnrollment[]
  }

  const createEnrollments = async (): Promise<RemovableEnrollment[]> => {
    const newEnrollments: Promise<DoFetchApiResults<RemovableEnrollment>>[] = []
    // section ids that already have the new role
    const existing_section_ids = currentEnrollments
      .filter(en => en.role_id === roleId)
      .map(en => en.course_section_id)
    const sectionLimited = currentEnrollments.every(en => en.limit_privileges_to_course_section)
    currentEnrollments.forEach(enrollment => {
      if (
        roleId !== enrollment.role_id &&
        !existing_section_ids.includes(enrollment.course_section_id)
      ) {
        const enrollmentBody = {
          enrollment: {
            user_id: userId,
            role_id: roleId,
            limit_privileges_to_course_section: sectionLimited,
            enrollment_state: enrollment.enrollment_state,
          },
        }
        const newEnrollment = doFetchApi<RemovableEnrollment>({
          path: `/api/v1/sections/${enrollment.course_section_id}/enrollments`,
          method: 'POST',
          body: enrollmentBody,
        })
        newEnrollments.push(newEnrollment)
      }
    })
    const enrollmentResponses = await Promise.all(newEnrollments)
    return enrollmentResponses.map(response => {
      // we need to mark these as removable; otherwise, the UI won't let us change roles again
      return {...response.json, can_be_removed: true}
    }) as RemovableEnrollment[]
  }

  const updateEnrollments = async () => {
    // createEnrollments/deleteEnrollments are async functions
    // they both wait on an array of fetch requests to complete, then return Promise<RemovableEnrollment[]>
    // adding the results to a promise array and calling Promise.all allows these to run simultaneously
    // and will only progress when all enrollment POST/DELETE requests are completed
    const promises = [createEnrollments(), deleteEnrollments()]
    const [newEnrollments, deletedEnrollments] = await Promise.all(promises)
    return [newEnrollments.filter(Boolean), deletedEnrollments.filter(Boolean)]
  }

  const handleRoleSelect = (value: string) => {
    const newRole = availableRoles.find(role => role.id === value)
    if (newRole) {
      setRoleId(newRole.id)
    }
  }

  const handleUpdate = async () => {
    if (currentEnrollments.every(en => roleId === en.role_id)) {
      props.onClose()
      return
    }
    setIsLoading(true)
    try {
      const [newEnrollments, deletedEnrollments] = await updateEnrollments()
      props.onSubmit(newEnrollments, deletedEnrollments)
      showFlashSuccess(I18n.t('Successfully updated roles'))()
      props.onClose()
    } catch (error) {
      showFlashError(I18n.t('Failed to update roles'))(error as Error)
    } finally {
      setIsLoading(false)
    }
  }
  const multipleRolesWarning = I18n.t(
    `This user has multiple roles in the course. Changing their role here will overwrite all of their current enrollments.`,
  )
  return (
    <Modal
      onSubmit={event => {
        event.preventDefault()
        handleUpdate()
      }}
      as="form"
      open={true}
      label={I18n.t('Edit Roles')}
      size="small"
      id="edit_roles"
    >
      <Modal.Header>
        <Heading>{I18n.t('Edit Roles')}</Heading>
        <CloseButton onClick={props.onClose} screenReaderLabel={I18n.t('Close')} placement="end" />
      </Modal.Header>
      <Modal.Body>
        {isLoading ? (
          <View as="div" margin="medium none" textAlign="center">
            <Spinner renderTitle={I18n.t('Updating roles')} />
          </View>
        ) : (
          <Flex gap="inputFields" direction="column">
            {currentEnrollments.length > 1 ? <Text>{multipleRolesWarning}</Text> : null}
            <CanvasSelect
              data-testid="edit-roles-select"
              label={I18n.t('Role:')}
              id="courseRole"
              value={roleId}
              onChange={(_e, value) => handleRoleSelect(value)}
            >
              {availableRoles.map(role => (
                <CanvasSelect.Option
                  key={role.id}
                  id={role.id}
                  value={role.id}
                  data-testid={`${role.label}-option`}
                >
                  {role.label}
                </CanvasSelect.Option>
              ))}
            </CanvasSelect>
          </Flex>
        )}
      </Modal.Body>
      <Modal.Footer>
        <Flex gap="buttons">
          <Button onClick={props.onClose} disabled={isLoading} data-testid="cancel-modal">
            {I18n.t('Cancel')}
          </Button>
          <Button color="primary" type="submit" disabled={isLoading} data-testid="update-roles">
            {I18n.t('Update')}
          </Button>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}
