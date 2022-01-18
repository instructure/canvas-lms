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

import {AssignmentOverride} from '../../../graphql/AssignmentOverride'
import I18n from 'i18n!discussion_posts'
import PropTypes from 'prop-types'
import React, {useState} from 'react'

import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'

export function DueDatesForParticipantList({...props}) {
  const [isExpanded, setIsExpanded] = useState(false)
  const truncateLength = 10
  const truncateTo = 5
  const isExpandable = props.assignmentOverride?.set?.students?.length > truncateLength

  if (props.assignmentOverride?.set?.students?.length > 0) {
    return (
      <>
        <Text size={props.textSize}>
          {isExpanded || !isExpandable
            ? props.assignmentOverride.set.students.map(student => student.shortName).join(', ') +
              ' '
            : props.assignmentOverride.set.students
                .slice(0, truncateTo)
                .map(student => student.shortName)
                .join(', ')}
        </Text>
        {isExpandable && (
          <Text size={props.textSize}>
            {isExpanded ? ' ' : '... '}
            <Link onClick={() => setIsExpanded(!isExpanded)}>
              {isExpanded
                ? I18n.t('%{count} less', {
                    count: props.assignmentOverride.set.students.length - truncateTo
                  })
                : I18n.t('%{count} more', {
                    count: props.assignmentOverride.set.students.length - truncateTo
                  })}
            </Link>
          </Text>
        )}
      </>
    )
  } else {
    return (
      <Text size={props.textSize} wrap="break-word">
        {props.overrideTitle || props.assignmentOverride?.title}
      </Text>
    )
  }
}

DueDatesForParticipantList.propTypes = {
  assignmentOverride: AssignmentOverride.shape,
  textSize: PropTypes.string,
  overrideTitle: PropTypes.string
}
