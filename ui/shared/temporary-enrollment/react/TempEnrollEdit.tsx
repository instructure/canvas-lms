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
import {Text} from '@instructure/ui-text'
import {Avatar} from '@instructure/ui-avatar'
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

const I18n = useI18nScope('temporary_enrollment')

// initialize analytics props
const analyticProps = createAnalyticPropsGenerator(MODULE_NAME)

interface Props {
  readonly enrollments: Enrollment[]
  readonly user: User
  readonly onEdit?: (enrollment: User) => void
  readonly onDelete?: (enrollmentId: number) => void
  readonly onAddNew?: () => void
  readonly contextType: EnrollmentType
  readonly tempEnrollPermissions: TempEnrollPermissions
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
  courseId: number,
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

  const handleEditClick = (enrollment: Enrollment) => {
    if (canEdit) {
      props.onEdit?.(enrollment.user)
    } else {
      // eslint-disable-next-line no-console
      console.error('User does not have permission to edit enrollment')
    }
  }

  const handleDeleteClick = (enrollment: Enrollment) => {
    if (canDelete) {
      handleConfirmAndDeleteEnrollment(enrollment.course_id, enrollment.id, props.onDelete)
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

  const renderActionIcons = (enrollment: Enrollment) => (
    <Flex margin="0 small 0 0">
      {canEdit && (
        <Flex.Item>
          <Tooltip renderTip={I18n.t('Edit')}>
            <IconButton
              data-testid="edit-button"
              withBorder={false}
              withBackground={false}
              size="small"
              screenReaderLabel={I18n.t('Edit')}
              onClick={() => handleEditClick(enrollment)}
              {...analyticProps('Edit')}
            >
              <IconEditLine title={I18n.t('Edit')} />
            </IconButton>
          </Tooltip>
        </Flex.Item>
      )}

      {canDelete && (
        <Flex.Item>
          <Tooltip renderTip={I18n.t('Delete')}>
            <IconButton
              data-testid="delete-button"
              withBorder={false}
              withBackground={false}
              size="small"
              screenReaderLabel={I18n.t('Delete')}
              onClick={() => handleDeleteClick(enrollment)}
              {...analyticProps('Delete')}
            >
              <IconTrashLine title={I18n.t('Delete')} />
            </IconButton>
          </Tooltip>
        </Flex.Item>
      )}
    </Flex>
  )

  const renderAvatar = () => {
    return (
      <Flex>
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

        <Flex.Item>
          <div>
            <Text size="large">{props.user.name}</Text>
          </div>
        </Flex.Item>
      </Flex>
    )
  }

  return (
    <>
      <Flex wrap="wrap" margin="0 small 0 0">
        <Flex.Item>{renderAvatar()}</Flex.Item>

        {canAdd && props.contextType === PROVIDER && (
          <Flex.Item margin="0 0 0 auto">
            <Button
              data-testid="add-button"
              onClick={handleAddNewClick}
              aria-label={I18n.t('Create temporary enrollment')}
              {...analyticProps('Create')}
            >
              <IconPlusLine />

              {I18n.t('Recipient')}
            </Button>
          </Flex.Item>
        )}
      </Flex>

      <Table caption={<ScreenReaderContent>{I18n.t('User information')}</ScreenReaderContent>}>
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="usertable-name">{I18n.t('Name')}</Table.ColHeader>
            <Table.ColHeader id="usertable-email">{I18n.t('Enrollment Period')}</Table.ColHeader>
            <Table.ColHeader id="usertable-loginid">{I18n.t('Enrollment Type')}</Table.ColHeader>
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
          {props.enrollments.map(enrollment => (
            <Table.Row key={enrollment.id}>
              <Table.RowHeader>{enrollment.user.name}</Table.RowHeader>
              <Table.Cell>
                {formatDateTime(enrollment.start_at)} - {formatDateTime(enrollment.end_at)}
              </Table.Cell>
              <Table.Cell>{enrollment.type}</Table.Cell>
              {(canEdit || canDelete) && <Table.Cell>{renderActionIcons(enrollment)}</Table.Cell>}
            </Table.Row>
          ))}
        </Table.Body>
      </Table>
    </>
  )
}
