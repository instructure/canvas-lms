/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {bool, func, oneOf, shape} from 'prop-types'
import {Button} from '@instructure/ui-buttons'
import {IconCheckMarkSolid} from '@instructure/ui-icons'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'

import {FAILURE, STARTED, SUCCESS} from '../assignment/AssignmentActions'

const I18n = useI18nScope('assignment_grade_summary')

function readyButton(props) {
  return <Button {...props}>{I18n.t('Post to Students')}</Button>
}

function startedButton(props) {
  const title = I18n.t('Posting to Students')

  return (
    <Button {...props} color="primary-inverse">
      <Spinner size="x-small" renderTitle={title} />
      <PresentationContent>{title}</PresentationContent>
    </Button>
  )
}

function successButton(props) {
  return (
    <Button {...props} renderIcon={IconCheckMarkSolid} color="primary-inverse">
      {I18n.t('Grades Posted to Students')}
    </Button>
  )
}

export default function PostToStudentsButton(props) {
  const {assignment, onClick, unmuteAssignmentStatus, ...otherProps} = props
  const unmutable = assignment.gradesPublished && assignment.muted
  const canClick = ![STARTED, SUCCESS].includes(unmuteAssignmentStatus)

  const buttonProps = {
    ...otherProps,
    'aria-readonly': !assignment.gradesPublished ? null : !assignment.muted || !canClick,
    disabled: assignment.gradesPublished ? null : true,
    onClick: unmutable && canClick ? onClick : null,
  }

  if (!assignment.muted) {
    return successButton(buttonProps)
  }

  if (unmuteAssignmentStatus === STARTED) {
    return startedButton(buttonProps)
  }

  return readyButton(buttonProps)
}

PostToStudentsButton.propTypes = {
  assignment: shape({
    gradesPublished: bool.isRequired,
    muted: bool.isRequired,
  }).isRequired,
  onClick: func.isRequired,
  unmuteAssignmentStatus: oneOf([FAILURE, STARTED, SUCCESS]),
}

PostToStudentsButton.defaultProps = {
  unmuteAssignmentStatus: null,
}
