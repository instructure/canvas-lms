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
// @ts-ignore: TS doesn't understand i18n scoped imports
import {useScope as useI18nScope} from '@canvas/i18n'
import {connect} from 'react-redux'

import {Button, IconButton} from '@instructure/ui-buttons'
import {IconEyeLine, IconOffLine} from '@instructure/ui-icons'

import {isStudentPace} from '../../reducers/course_paces'
import {getResponsiveSize, getShowProjections} from '../../reducers/ui'
import {ResponsiveSizes, StoreState} from '../../types'
import {actions as uiActions} from '../../actions/ui'

const I18n = useI18nScope('course_paces_show_projections_button')

interface StoreProps {
  readonly responsiveSize: ResponsiveSizes
  readonly showProjections: boolean
  readonly studentPace: boolean
}

interface DispatchProps {
  readonly toggleShowProjections: typeof uiActions.toggleShowProjections
}

interface PassedProps {
  readonly margin?: string
}

type ComponentProps = StoreProps & DispatchProps & PassedProps

export const ShowProjectionsButton: React.FC<ComponentProps> = ({
  margin,
  responsiveSize,
  showProjections,
  studentPace,
  toggleShowProjections
}) => {
  // Don't show the projections button on student paces
  if (studentPace) return null

  const buttonText = showProjections ? I18n.t('Hide Projections') : I18n.t('Show Projections')
  const Icon = showProjections ? IconOffLine : IconEyeLine

  if (responsiveSize === 'small') {
    return (
      <IconButton
        data-testid="projections-icon-button"
        margin={margin}
        screenReaderLabel={buttonText}
        onClick={toggleShowProjections}
      >
        <Icon />
      </IconButton>
    )
  }
  return (
    <Button
      data-test-id="projections-text-button"
      margin={margin}
      renderIcon={Icon}
      onClick={toggleShowProjections}
    >
      {buttonText}
    </Button>
  )
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    responsiveSize: getResponsiveSize(state),
    showProjections: getShowProjections(state),
    studentPace: isStudentPace(state)
  }
}

export default connect(mapStateToProps, {
  toggleShowProjections: uiActions.toggleShowProjections
})(ShowProjectionsButton)
