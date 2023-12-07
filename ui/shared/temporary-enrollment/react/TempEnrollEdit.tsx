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
import type {Enrollment, EnrollmentType, TempEnrollPermissions, User} from './types'
import {MODULE_NAME, PROVIDER} from './types'
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
  onDelete?: (enrollmentIds: string[]) => void
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
 * Confirms with the user and then attempts to delete a list of enrollments,
 * calls the onDelete callback for each successfully deleted enrollment
 *
 * @param {Enrollment[]} tempEnrollments Enrollments to be deleted
 * @param {function} onDelete Callback function
 * @returns {Promise<void>}
 */
async function handleConfirmAndDeleteEnrollment(
  tempEnrollments: Enrollment[],
  onDelete?: (enrollmentIds: string[]) => void
): Promise<void> {
  // TODO is there a good inst ui component for confirmation dialog?
  // eslint-disable-next-line no-alert
  const userConfirmed = window.confirm(I18n.t('Are you sure you want to delete this enrollment?'))
  if (userConfirmed) {
    const results = await Promise.allSettled(
      tempEnrollments.map(enrollment =>
        deleteEnrollment(enrollment.course_id, enrollment.id)
          .then(() => ({status: 'success', id: enrollment.id}))
          .catch(() => ({status: 'error', id: enrollment.id}))
      )
    )
    const successfulDeletions = results
      .filter(result => result.status === 'fulfilled')
      .map(result => (result as PromiseFulfilledResult<{status: string; id: string}>).value.id)
    if (successfulDeletions.length > 0) {
      showFlashAlert({
        type: 'success',
        message: `${successfulDeletions.length} enrollments deleted successfully.`,
      })
      if (onDelete) {
        onDelete(successfulDeletions)
      }
    }
    const errorCount = results.filter(result => result.status === 'rejected').length
    if (errorCount > 0) {
      showFlashAlert({
        type: 'error',
        message: `${errorCount} enrollments could not be deleted.`,
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
      handleConfirmAndDeleteEnrollment(enrollments, props.onDelete)
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
    <Flex gap="xxx-small" wrap="no-wrap" justifyItems="end">
      {canEdit && (
        <Flex.Item shouldShrink={true}>
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
              <IconEditLine />
            </IconButton>
          </Tooltip>
        </Flex.Item>
      )}

      {canDelete && (
        <Flex.Item shouldShrink={true}>
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
              <IconTrashLine />
            </IconButton>
          </Tooltip>
        </Flex.Item>
      )}
    </Flex>
  )

  return (
    <Flex gap="medium" direction="column">
      <Flex.Item overflowY="visible">
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
      <Flex.Item shouldGrow={true}>
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
                <Table.ColHeader id="header-user-option-links">
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
                  {canEditOrDelete && <Table.Cell>{renderActionIcons(enrollmentGroup)}</Table.Cell>}
                </Table.Row>
              )
            })}
          </Table.Body>
        </Table>
      </Flex.Item>
    </Flex>
  )
}
