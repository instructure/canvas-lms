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
import Button from '@instructure/ui-buttons/lib/components/Button'
import IconCheckMark from '@instructure/ui-icons/lib/Solid/IconCheckMark'
import PresentationContent from '@instructure/ui-a11y/lib/components/PresentationContent'
import Spinner from '@instructure/ui-elements/lib/components/Spinner'
import I18n from 'i18n!assignment_grade_summary'

import {FAILURE, STARTED, SUCCESS} from '../assignment/AssignmentActions'

function readyButton(props) {
  return <Button {...props}>{I18n.t('Display to Students')}</Button>
}

function startedButton(props) {
  const title = I18n.t('Displaying to Students')

  return (
    <Button {...props} variant="light">
      <Spinner size="x-small" title={title} /> <PresentationContent>{title}</PresentationContent>
    </Button>
  )
}

function successButton(props) {
  return (
    <Button {...props} icon={IconCheckMark} variant="light">
      {I18n.t('Grades Visible to Students')}
    </Button>
  )
}

export default function DisplayToStudentsButton(props) {
  const {assignment, onClick, unmuteAssignmentStatus, ...otherProps} = props
  const unmutable = assignment.gradesPublished && assignment.muted
  const canClick = ![STARTED, SUCCESS].includes(unmuteAssignmentStatus)

  const buttonProps = {
    ...otherProps,
    'aria-readonly': !assignment.gradesPublished ? null : !assignment.muted || !canClick,
    disabled: assignment.gradesPublished ? null : true,
    onClick: unmutable && canClick ? onClick : null
  }

  if (!assignment.muted) {
    return successButton(buttonProps)
  }

  if (unmuteAssignmentStatus === STARTED) {
    return startedButton(buttonProps)
  }

  return readyButton(buttonProps)
}

DisplayToStudentsButton.propTypes = {
  assignment: shape({
    gradesPublished: bool.isRequired,
    muted: bool.isRequired
  }).isRequired,
  onClick: func.isRequired,
  unmuteAssignmentStatus: oneOf([FAILURE, STARTED, SUCCESS])
}

DisplayToStudentsButton.defaultProps = {
  unmuteAssignmentStatus: null
}
