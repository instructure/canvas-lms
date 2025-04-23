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

import React, {type ReactNode, type FC} from 'react'
import {IconButton} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import {
  IconMoreLine,
  IconEmailLine,
  IconUserLine,
  IconDeactivateUserLine,
  IconEditLine,
  IconTrashLine,
  IconLinkLine
} from '@instructure/ui-icons'
import useCoursePeopleContext from '../../hooks/useCoursePeopleContext'
import {useScope as createI18nScope} from '@canvas/i18n'
import {OBSERVER_ENROLLMENT, INACTIVE_ENROLLMENT} from '../../../util/constants'
import type {Enrollment, CustomLink} from '../../../types'

const I18n = createI18nScope('course_people')

type MenuItemProps = {
  href?: string
  label: string
  testId: string
  onSelectHandler?: () => void
  children: ReactNode
}

const MenuItem: FC<MenuItemProps> = ({
  href,
  label,
  testId,
  onSelectHandler,
  children
}) => (
  <Menu.Item
    href={href}
    data-testid={testId}
    onClick={onSelectHandler}
  >
    {children}
    <View margin="0 0 0 x-small">
      {label}
    </View>
  </Menu.Item>
)

export type UserMenuProps = {
  uid: string
  name: string
  htmlUrl: string
  canManage: boolean
  canRemoveUsers: boolean
  enrollments: Enrollment[]
  customLinks: CustomLink[] | null
  onResendInvitation: () => void
  onLinkStudents: () => void
  onEditSections: () => void
  onEditRoles: () => void
  onReactivateUser: () => void
  onDeactivateUser: () => void
  onRemoveUser: () => void
  onCustomLinkSelect: () => void
}

const UserMenu: FC<UserMenuProps> = ({
  uid,
  name,
  htmlUrl,
  canManage,
  canRemoveUsers,
  enrollments,
  customLinks,
  onResendInvitation,
  onLinkStudents,
  onEditSections,
  onEditRoles,
  onReactivateUser,
  onDeactivateUser,
  onRemoveUser,
  onCustomLinkSelect
}) => {
  const {
    activeGranularEnrollmentPermissions = [],
    courseConcluded,
  } = useCoursePeopleContext()

  const isInactive = enrollments.every(e => e.state === INACTIVE_ENROLLMENT)
  const canResendInvitation = !isInactive &&
    enrollments.some(e => activeGranularEnrollmentPermissions.includes(e.type))
  const isObserver = enrollments.some(e => e.type === OBSERVER_ENROLLMENT)
  const canLinkStudents = isObserver && !courseConcluded
  const sectionEditableEnrollments = enrollments.filter(e => e.type !== OBSERVER_ENROLLMENT)
  const canEditSections = !isInactive && !(sectionEditableEnrollments?.length === 0)
  const canEditRoles = canRemoveUsers &&
    !courseConcluded &&
    !(enrollments.some(e => e.type === OBSERVER_ENROLLMENT && e.associatedUser?._id))

  const renderCustomLinks = () => (customLinks || []).map(({_id, url, icon_class, text}) => (
    <Menu.Item key={_id} href={url} onClick={onCustomLinkSelect} data-testid={`custom-link-${_id}-user-${uid}`}>
      <i className={icon_class} />
      <View margin="0 0 0 x-small">{text}</View>
    </Menu.Item>
  ))

  return (
    <Menu
      trigger={
        <IconButton
          size="small"
          renderIcon={<IconMoreLine />}
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Manage %{name}', {name})}
          data-testid={`options-menu-user-${uid}`}
        />
      }
    >
      {canManage && canResendInvitation && (
        <MenuItem
          label={I18n.t('Resend Invitation')}
          onSelectHandler={onResendInvitation}
          testId={`resend-invitation-user-${uid}`}
        >
          <IconEmailLine size="x-small" />
        </MenuItem>
      )}
      {canManage && canLinkStudents && (
        <MenuItem
          label={I18n.t('Link to Students')}
          onSelectHandler={onLinkStudents}
          testId={`link-to-students-user-${uid}`}
        >
          <IconLinkLine size="x-small" />
        </MenuItem>
      )}
      {canManage && canEditSections && (
        <MenuItem
          label={I18n.t('Edit Sections')}
          onSelectHandler={onEditSections}
          testId={`edit-sections-user-${uid}`}
        >
          <IconEditLine size="x-small" />
        </MenuItem>
      )}
      {canManage && canEditRoles && (
        <MenuItem
          label={I18n.t('Edit Roles')}
          onSelectHandler={onEditRoles}
          testId={`edit-roles-user-${uid}`}
        >
          <IconEditLine size="x-small" />
        </MenuItem>
      )}
      <MenuItem
        href={htmlUrl}
        label={I18n.t('User Details')}
        testId={`details-user-${uid}`}
      >
        <IconUserLine size="x-small" />
      </MenuItem>
      {canRemoveUsers && (
        <Menu.Separator />
      )}
      {canRemoveUsers && isInactive && (
        <MenuItem
          label={I18n.t('Re-activate User')}
          onSelectHandler={onReactivateUser}
          testId={`reactivate-user-${uid}`}
        >
          <IconUserLine size="x-small" />
        </MenuItem>
      )}
      {canRemoveUsers && !isInactive && (
        <MenuItem
          label={I18n.t('Deactivate User')}
          onSelectHandler={onDeactivateUser}
          testId={`deactivate-user-${uid}`}
        >
          <IconDeactivateUserLine size="x-small" />
        </MenuItem>
      )}
      {canRemoveUsers && (
        <MenuItem
          label={I18n.t('Remove From Course')}
          onSelectHandler={onRemoveUser}
          testId={`remove-from-course-user-${uid}`}
        >
          <IconTrashLine size="x-small" />
        </MenuItem>
      )}
      {customLinks && customLinks.length > 0 && renderCustomLinks()}
    </Menu>
  )
}

export default UserMenu
