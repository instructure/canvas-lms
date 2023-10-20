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
import {arrayOf, bool, func, oneOf, shape, string} from 'prop-types'
import {omit} from 'lodash'
import {Button} from '@instructure/ui-buttons'
import {IconCheckMarkSolid} from '@instructure/ui-icons'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'

import {FAILURE, STARTED, SUCCESS} from '../../grades/GradeActions'

const I18n = useI18nScope('assignment_grade_summary')

function buttonProps(props) {
  return omit(props, 'graderName')
}

function readyButton(props) {
  return (
    <Button {...buttonProps(props)}>
      <PresentationContent>{I18n.t('Accept')}</PresentationContent>
      <ScreenReaderContent>
        {I18n.t('Accept grades by %{graderName}', {graderName: props.graderName})}
      </ScreenReaderContent>
    </Button>
  )
}

function startedButton(props) {
  const title = I18n.t('Accepting')

  return (
    <Button {...buttonProps(props)} color="primary-inverse">
      <Spinner size="x-small" renderTitle={title} />
      <PresentationContent>{title}</PresentationContent>
    </Button>
  )
}

function successButton(props) {
  return (
    <Button
      {...buttonProps(props)}
      renderIcon={IconCheckMarkSolid}
      variant={props.disabled ? 'default' : 'light'}
    >
      {I18n.t('Accepted')}
    </Button>
  )
}

export default function AcceptGradesButton(props) {
  const {acceptGradesStatus, onClick, selectionDetails, ...otherProps} = props
  const actionReady = ![STARTED, SUCCESS].includes(acceptGradesStatus)

  const buttonProps = {
    ...otherProps,
    'aria-readonly': actionReady ? null : true,
    disabled: selectionDetails.allowed ? null : true,
    onClick: selectionDetails.allowed && actionReady ? onClick : null,
  }

  if (acceptGradesStatus === STARTED) {
    return startedButton(buttonProps)
  }

  if (acceptGradesStatus === SUCCESS) {
    return successButton(buttonProps)
  }

  if (selectionDetails.allowed && selectionDetails.provisionalGradeIds.length === 0) {
    buttonProps.disabled = acceptGradesStatus == null // initially loaded without any grades to select
    return successButton(buttonProps)
  }

  return readyButton(buttonProps)
}

AcceptGradesButton.propTypes = {
  id: string.isRequired,
  acceptGradesStatus: oneOf([FAILURE, STARTED, SUCCESS]),
  graderName: string.isRequired,
  onClick: func.isRequired,
  selectionDetails: shape({
    allowed: bool.isRequired,
    provisionalGradeIds: arrayOf(string).isRequired,
  }).isRequired,
}

AcceptGradesButton.defaultProps = {
  acceptGradesStatus: null,
}
