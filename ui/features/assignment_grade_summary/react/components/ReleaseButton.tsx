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
import {Button} from '@instructure/ui-buttons'
import {IconCheckMarkSolid} from '@instructure/ui-icons'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'

import {
  SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS,
  STARTED,
  SUCCESS,
} from '../assignment/AssignmentActions'

const I18n = createI18nScope('assignment_grade_summary')

function readyButton(props: any) {
  return (
    <Button {...props} color="primary">
      {I18n.t('Release Grades')}
    </Button>
  )
}

function startedButton(props: any) {
  const title = I18n.t('Releasing Grades')

  return (
    <Button {...props} color="primary-inverse">
      <Spinner size="x-small" renderTitle={title} />
      <PresentationContent>{title}</PresentationContent>
    </Button>
  )
}

function successButton(props: any) {
  return (
    <Button {...props} renderIcon={IconCheckMarkSolid} color="primary-inverse">
      {I18n.t('Grades Released')}
    </Button>
  )
}

interface ReleaseButtonProps {
  gradesReleased: boolean
  onClick: () => void
  releaseGradesStatus?: string | null
  [key: string]: any
}

export default function ReleaseButton(props: ReleaseButtonProps) {
  const {gradesReleased, onClick, releaseGradesStatus = null, ...otherProps} = props
  const isValidSelection = releaseGradesStatus !== SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS
  const canClick =
    !(gradesReleased || [STARTED, SUCCESS].includes(releaseGradesStatus as string)) &&
    isValidSelection
  const buttonProps = {
    ...otherProps,
    disabled: !isValidSelection || null,
    'aria-readonly': !canClick,
    onClick: canClick ? onClick : null,
  }

  if (gradesReleased) {
    return successButton(buttonProps)
  }

  if (releaseGradesStatus === STARTED) {
    return startedButton(buttonProps)
  }

  return readyButton(buttonProps)
}
