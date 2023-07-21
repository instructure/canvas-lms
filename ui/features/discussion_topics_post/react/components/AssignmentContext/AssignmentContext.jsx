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

import React from 'react'
import {responsiveQuerySizes} from '../../utils/index'

import {Responsive} from '@instructure/ui-responsive'
import PropTypes from 'prop-types'
import {DueDatesForParticipantList} from '../DueDatesForParticipantList/DueDatesForParticipantList'

const I18n = useI18nScope('discussion_posts')

export function AssignmentContext({...props}) {
  let groupDisplayText = null
  if (props.group) {
    groupDisplayText = props.group
  } else if (props.assignmentOverride?.set?.__typename !== 'AdhocStudents') {
    groupDisplayText = I18n.t('Everyone')
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({tablet: true, desktop: true})}
      props={{
        tablet: {
          textSize: 'x-small',
          displayText: null,
        },
        desktop: {
          textSize: 'small',
          displayText: groupDisplayText,
        },
      }}
      render={responsiveProps => {
        return responsiveProps.displayText ? (
          <DueDatesForParticipantList
            textSize={responsiveProps.textSize}
            assignmentOverride={props.assignmentOverride}
            overrideTitle={responsiveProps.displayText}
          />
        ) : null
      }}
    />
  )
}

AssignmentContext.propTypes = {
  group: PropTypes.string,
  assignmentOverride: PropTypes.object,
}

AssignmentContext.defaultProps = {
  group: '',
  assignmentOverride: null,
}
