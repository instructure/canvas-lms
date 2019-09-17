/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import I18n from 'i18n!direct_share_user_panel'
import React from 'react'
import {arrayOf, func, string} from 'prop-types'
import {Tag} from '@instructure/ui-elements'
import ContentShareUserSearchSelector from '../components/ContentShareUserSearchSelector'
import basicUser from '../proptypes/user'

DirectShareUserPanel.propTypes = {
  courseId: string,
  selectedUsers: arrayOf(basicUser),
  onUserSelected: func, // basicUser => {}
  onUserRemoved: func // basicUser => {}
}

export default function DirectShareUserPanel({selectedUsers, onUserSelected, onUserRemoved, courseId}) {
  function renderSelectedUserTags() {
    return selectedUsers.map(user => (
      <Tag
        key={user.id}
        dismissible
        title={I18n.t('Remove %{name}', {name: user.display_name})}
        text={user.display_name}
        onClick={() => onUserRemoved(user)}
      />
    ))
  }

  return <ContentShareUserSearchSelector
    courseId={courseId || ENV.COURSE_ID}
    onUserSelected={onUserSelected}
    renderBeforeInput={renderSelectedUserTags}
  />
}
