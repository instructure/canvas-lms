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
import {Text} from '@instructure/ui-text'
import {Pill} from '@instructure/ui-pill'
import {InlineList} from '@instructure/ui-list'
import {responsiveQuerySizes} from '../../utils'
import {Responsive} from '@instructure/ui-responsive'

const ROLE_HIERARCHY = ['Author', 'TeacherEnrollment', 'TaEnrollment']

export function RolePillContainer({...props}) {
  const baseRolesToDisplay = sortDiscussionRoles(props.discussionRoles)
  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          display: 'inline',
          delimiter: 'pipe'
        },
        desktop: {
          display: 'inline-block',
          delimiter: 'none'
        }
      }}
      render={(responsiveProps, matches) => (
        <>
          {baseRolesToDisplay.length > 0 && (
            <InlineList delimiter={responsiveProps.delimiter} data-testid="pill-container">
              {baseRolesToDisplay.map(baseRole => (
                <InlineList.Item key={baseRole}>
                  {matches.includes('mobile') ? (
                    <Text size="x-small" transform="uppercase" data-testid={`mobile-${baseRole}`}>
                      {baseRole}
                    </Text>
                  ) : (
                    <Pill data-testid={`pill-${baseRole}`}>{baseRole}</Pill>
                  )}
                </InlineList.Item>
              ))}
            </InlineList>
          )}
        </>
      )}
    />
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
  roleNameArray = Array.isArray(roleNameArray) ? roleNameArray : []

  roleNameArray.sort((roleNameA, roleNameB) => {
    const roleASortScore = ROLE_HIERARCHY.indexOf(roleNameA)
    const roleABortScore = ROLE_HIERARCHY.indexOf(roleNameB)
    return roleASortScore - roleABortScore
  })

  const roleNames = roleNameArray.map(rawName => {
    return roleName(rawName)
  })
  return roleNames
}

RolePillContainer.propTypes = {
  /**
   * String Array of user roles
   */
  discussionRoles: PropTypes.array
}

export default RolePillContainer
