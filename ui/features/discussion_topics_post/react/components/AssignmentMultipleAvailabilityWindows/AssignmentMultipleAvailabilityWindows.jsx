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

import {useScope as useI18nScope} from '@canvas/i18n'

import PropTypes from 'prop-types'
import React from 'react'
import {responsiveQuerySizes} from '../../utils/index'

import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Responsive} from '@instructure/ui-responsive'

const I18n = useI18nScope('discussion_posts')

export function AssignmentMultipleAvailabilityWindows({...props}) {
  return (
    <span className="discussions-show-multiple-due-dates">
      <Link
        isWithinText={false}
        as="button"
        onClick={() => {
          props.onSetDueDateTrayOpen(true)
        }}
        data-testid="show-due-dates-button"
      >
        <Responsive
          match="media"
          query={responsiveQuerySizes({tablet: true, desktop: true})}
          props={{
            tablet: {
              text: I18n.t('Due Dates (%{dueDateCount})', {
                dueDateCount: props.assignmentOverrides.length,
              }),
              textSize: 'x-small',
            },
            desktop: {
              text: I18n.t('Show Due Dates (%{dueDateCount})', {
                dueDateCount: props.assignmentOverrides.length,
              }),
              textSize: 'small',
            },
          }}
          render={responsiveProps => (
            <Text weight="bold" size={responsiveProps.textSize}>
              {responsiveProps.text}
            </Text>
          )}
        />
      </Link>
    </span>
  )
}

AssignmentMultipleAvailabilityWindows.propTypes = {
  assignmentOverrides: PropTypes.array,
  onSetDueDateTrayOpen: PropTypes.func,
}
