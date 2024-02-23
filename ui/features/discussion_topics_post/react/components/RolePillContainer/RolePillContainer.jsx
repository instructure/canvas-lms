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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {Pill} from '@instructure/ui-pill'
import {InlineList} from '@instructure/ui-list'
import {responsiveQuerySizes} from '../../utils'
import {Responsive} from '@instructure/ui-responsive'

const I18n = useI18nScope('discussion_posts')

const ROLE_HIERARCHY = ['Author', 'TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment']

export function RolePillContainer({...props}) {
  // Filter out roles that aren't found in the role hierarchy
  const filteredRoles = props.discussionRoles
    ? props.discussionRoles.filter(role => ROLE_HIERARCHY.includes(role))
    : []
  const baseRolesToDisplay = sortDiscussionRoles(filteredRoles)
  const hasMultipleRoles = baseRolesToDisplay?.length > 1
  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({tablet: true, desktop: true})}
      props={{
        tablet: {
          display: 'inline',
          delimiter: 'pipe',
        },
        desktop: {
          display: 'inline-block',
          delimiter: 'none',
        },
        mobile: {
          display: 'inline',
          delimiter: 'pipe',
        },
      }}
      render={(responsiveProps, matches) => (
        <>
          {baseRolesToDisplay.length > 0 && (
            <InlineList
              delimiter={hasMultipleRoles ? 'pipe' : responsiveProps.delimiter}
              data-testid="pill-container"
            >
              {baseRolesToDisplay.map(baseRole => (
                <InlineList.Item key={baseRole}>
                  {matches.includes('desktop') && !hasMultipleRoles ? (
                    <Pill data-testid={`pill-${baseRole}`}>{baseRole}</Pill>
                  ) : (
                    <Text size="x-small" transform="uppercase" data-testid={`mobile-${baseRole}`}>
                      {baseRole}
                    </Text>
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
    get DesignerEnrollment() {
      return I18n.t('Designer')
    },
    get Author() {
      return I18n.t('Author')
    },
  }

  return types[baseRole]
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
  discussionRoles: PropTypes.array,
}

export default RolePillContainer
