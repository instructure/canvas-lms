/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import I18n from 'i18n!discussion_posts'

import {Pill} from '@instructure/ui-pill'
import {Flex} from '@instructure/ui-flex'

export const MOCK_ROLE_PILLS = {
  discussionRoles: ['Author', 'TaEnrollment', 'TeacherEnrollment']
}

const ROLE_HIERARCHY = ['Author', 'TeacherEnrollment', 'TaEnrollment']

export function RolePillContainer({...props}) {
  const baseRolesToDisplay = sortDiscussionRoles(props.discussionRoles)
  return (
    <>
      {baseRolesToDisplay.length > 0 && (
        <Flex display="inline-flex" data-testid="pill-container">
          {baseRolesToDisplay.map(baseRole => {
            return (
              <Flex padding="none small none none" key={baseRole}>
                <Pill>{roleName(baseRole)}</Pill>
              </Flex>
            )
          })}
        </Flex>
      )}
    </>
  )
}

function roleName(baseRole) {
  const types = {
    get TeacherEnrollment() {
      return I18n.t('Teacher')
    },
    get TaEnrollment() {
      return I18n.t('TA')
    },
    get Author() {
      return I18n.t('Author')
    }
  }

  return types[baseRole] || baseRole
}

function sortDiscussionRoles(roleNameArray) {
  if (roleNameArray === null || roleNameArray === undefined) {
    return []
  }

  roleNameArray.sort((roleNameA, roleNameB) => {
    const roleASortScore = ROLE_HIERARCHY.indexOf(roleNameA)
    const roleABortScore = ROLE_HIERARCHY.indexOf(roleNameB)
    return roleASortScore - roleABortScore
  })
  return roleNameArray
}

RolePillContainer.propTypes = {
  /**
   * String Array of user roles
   */
  discussionRoles: PropTypes.array
}

export default RolePillContainer
