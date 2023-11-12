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

import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {Tooltip} from '@instructure/ui-tooltip'
import {Button, IconButton} from '@instructure/ui-buttons'
import {IconEditLine, IconPlusLine, IconTrashLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Table} from '@instructure/ui-table'
import {
  Enrollment,
  EnrollmentType,
  MODULE_NAME,
  PROVIDER,
  TempEnrollPermissions,
  User,
} from './types'
import {deleteEnrollment} from './api/enrollment'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {createAnalyticPropsGenerator} from './util/analytics'
import {TempEnrollAvatar} from './TempEnrollAvatar'

const I18n = useI18nScope('temporary_enrollment')

// initialize analytics props
const analyticProps = createAnalyticPropsGenerator(MODULE_NAME)

interface Props {
  enrollments: Enrollment[]
  user: User
  onEdit?: (enrollment: User, tempEnrollments: Enrollment[]) => void
  onDelete?: (enrollmentId: number) => void
  onAddNew?: () => void
  enrollmentType: EnrollmentType
  tempEnrollPermissions: TempEnrollPermissions
}

export function getRelevantUserFromEnrollment(enrollment: Enrollment) {
  return enrollment.temporary_enrollment_provider ?? enrollment.user
}

export function getEnrollmentUserDisplayName(enrollment: Enrollment) {
  return getRelevantUserFromEnrollment(enrollment).name
}

export function groupEnrollmentsByPairingId(enrollments: Enrollment[]) {
  return enrollments.reduce((groupedById, enrollment) => {
    const groupId = enrollment.temporary_enrollment_pairing_id
    if (!groupedById[groupId]) {
      groupedById[groupId] = []
    }
    groupedById[groupId].push(enrollment)
    return groupedById
  }, {} as Record<number, Enrollment[]>)
}

/**
 * Confirms and deletes an enrollment
 *
 * @param {number} courseId ID of course to delete enrollment from
 * @param {number} enrollmentId ID of enrollment to be deleted
 * @param {function} onDelete Callback function called after enrollment is deleted,
 *                            likely passed in via props and used to update state
 */
async function handleConfirmAndDeleteEnrollment(
  courseId: string,
  enrollmentId: number,
  onDelete?: (id: number) => void
) {
  // TODO is there a good inst ui component for confirmation dialog?
  // eslint-disable-next-line no-alert
  const userConfirmed = window.confirm(I18n.t('Are you sure you want to delete this enrollment?'))

  if (userConfirmed) {
    try {
      await deleteEnrollment(courseId, enrollmentId, onDelete)

      showFlashAlert({
        type: 'success',
        message: I18n.t('Enrollment deleted successfully'),
      })
    } catch (error) {
      showFlashAlert({
        type: 'error',
        message: I18n.t('Enrollment could not be deleted'),
      })
    }
  }
}

export function TempEnrollEdit(props: Props) {
  const formatDateTime = useDateTimeFormat('date.formats.short_with_time')

  // destructure and cache permission checks (for use in eager and lazy evaluations)
  const {canEdit, canDelete, canAdd} = props.tempEnrollPermissions

  const canEditOrDelete = canEdit || canDelete

  const enrollmentTypeLabel =
    props.enrollmentType === PROVIDER ? I18n.t('Recipient') : I18n.t('Provider')

  const enrollmentGroups = groupEnrollmentsByPairingId(props.enrollments)

  const handleEditClick = (enrollments: Enrollment[]) => {
    if (canEdit) {
      props.onEdit?.(getRelevantUserFromEnrollment(enrollments[0]), enrollments)
    } else {
      // eslint-disable-next-line no-console
      console.error('User does not have permission to edit enrollment')
    }
  }

  const handleDeleteClick = (enrollments: Enrollment[]) => {
    if (canDelete) {
      // TODO loop over tempEnrollmentsPairing and delete each enrollment
      handleConfirmAndDeleteEnrollment(enrollments[0].course_id, enrollments[0].id, props.onDelete)
    } else {
      // eslint-disable-next-line no-console
      console.error('User does not have permission to delete enrollment')
    }
  }

  const handleAddNewClick = () => {
    if (canAdd) {
      props.onAddNew?.()
    } else {
      // eslint-disable-next-line no-console
      console.error('User does not have permission to add enrollment')
    }
  }

  const renderActionIcons = (enrollments: Enrollment[]) => (
    <>
      {canEdit && (
        <Tooltip renderTip={I18n.t('Edit')}>
          <IconButton
            data-testid="edit-button"
            withBorder={false}
            withBackground={false}
            size="small"
            screenReaderLabel={I18n.t('Edit')}
            onClick={() => handleEditClick(enrollments)}
            {...analyticProps('Edit')}
          >
            <IconEditLine title={I18n.t('Edit')} />
          </IconButton>
        </Tooltip>
      )}

      {canDelete && (
        <Tooltip renderTip={I18n.t('Delete')}>
          <IconButton
            data-testid="delete-button"
            withBorder={false}
            withBackground={false}
            size="small"
            screenReaderLabel={I18n.t('Delete')}
            onClick={() => handleDeleteClick(enrollments)}
            {...analyticProps('Delete')}
          >
            <IconTrashLine title={I18n.t('Delete')} />
          </IconButton>
        </Tooltip>
      )}
    </>
  )

  return (
    <Flex gap="medium" direction="column">
      <Flex.Item padding="xx-small">
        <Flex wrap="wrap" gap="x-small" justifyItems="space-between">
          <Flex.Item>
            <TempEnrollAvatar user={props.user} />
          </Flex.Item>
          {canAdd && props.enrollmentType === PROVIDER && (
            <Flex.Item>
              <Button
                data-testid="add-button"
                onClick={handleAddNewClick}
                aria-label={I18n.t('Create temporary enrollment')}
                {...analyticProps('Create')}
                renderIcon={IconPlusLine}
              >
                {I18n.t('Recipient')}
              </Button>
            </Flex.Item>
          )}
        </Flex>
      </Flex.Item>
      <Flex.Item shouldGrow={true} padding="xx-small">
        <Table caption={<ScreenReaderContent>{I18n.t('User information')}</ScreenReaderContent>}>
          <Table.Head>
            <Table.Row>
              <Table.ColHeader id="usertable-name">
                {enrollmentTypeLabel} {I18n.t('Name')}
              </Table.ColHeader>
              <Table.ColHeader id="usertable-email">
                {I18n.t('Recipient Enrollment Period')}
              </Table.ColHeader>
              <Table.ColHeader id="usertable-loginid">
                {I18n.t('Recipient Enrollment Type')}
              </Table.ColHeader>
              {(canEdit || canDelete) && (
                <Table.ColHeader id="header-user-option-links" width="1">
                  <ScreenReaderContent>
                    {I18n.t('Temporary enrollment option links')}
                  </ScreenReaderContent>
                </Table.ColHeader>
              )}
            </Table.Row>
          </Table.Head>
          <Table.Body>
            {Object.entries(enrollmentGroups).map(([pairingId, enrollmentGroup]) => {
              const firstEnrollment: Enrollment = enrollmentGroup[0]
              return (
                <Table.Row key={pairingId}>
                  <Table.RowHeader>{getEnrollmentUserDisplayName(firstEnrollment)}</Table.RowHeader>
                  <Table.Cell>
                    {`${formatDateTime(firstEnrollment.start_at)} - ${formatDateTime(
                      firstEnrollment.end_at
                    )}`}
                  </Table.Cell>
                  <Table.Cell>{firstEnrollment.type}</Table.Cell>
                  {canEditOrDelete && (
                    <Table.Cell textAlign="end">{renderActionIcons(enrollmentGroup)}</Table.Cell>
                  )}
                </Table.Row>
              )
            })}
          </Table.Body>
        </Table>
      </Flex.Item>
    </Flex>
  )
}
