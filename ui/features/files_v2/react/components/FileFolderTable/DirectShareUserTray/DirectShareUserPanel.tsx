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

import React, {type Ref, useCallback} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Tag} from '@instructure/ui-tag'
import ContentShareUserSearchSelector, {
  type ContentShareUserSearchSelectorRef,
  type BasicUser,
} from './ContentShareUserSearchSelector'
import {IconUserLine} from '@instructure/ui-icons'

type DirectShareUserPanelProps = {
  selectedUsers: BasicUser[]
  onUserSelected: (user?: BasicUser) => void
  onUserRemoved: (user: BasicUser) => void
  courseId: string
  selectorRef?: Ref<ContentShareUserSearchSelectorRef>
}

const I18n = createI18nScope('files_v2')

const DirectShareUserPanel = ({
  selectedUsers,
  onUserSelected,
  onUserRemoved,
  courseId,
  selectorRef,
}: DirectShareUserPanelProps) => {
  const renderSelectedUserTags = useCallback(() => {
    if (selectedUsers.length > 0) {
      return selectedUsers.map(user => (
        <Tag
          key={user.id}
          dismissible
          title={I18n.t('Remove %{name}', {name: user.name})}
          text={user.name}
          onClick={() => onUserRemoved(user)}
        />
      ))
    } else {
      return <IconUserLine data-testid="direct-share-user-icon" inline={false} />
    }
  }, [onUserRemoved, selectedUsers])

  return (
    <ContentShareUserSearchSelector
      ref={selectorRef}
      courseId={courseId}
      onUserSelected={onUserSelected}
      selectedUsers={selectedUsers}
      renderBeforeInput={renderSelectedUserTags}
    />
  )
}

export default DirectShareUserPanel
