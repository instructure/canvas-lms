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
import {useScope as createI18nScope} from '@canvas/i18n'
import moment from 'moment-timezone'
import {connect} from 'react-redux'

import {uid} from '@instructure/uid'
import {Menu} from '@instructure/ui-menu'
import {Tooltip} from '@instructure/ui-tooltip'

import BlackoutDatesModal from '../../../shared/components/blackout_dates_modal'
import type {CoursePace, StoreState, ResponsiveSizes} from '../../../types'
import type {BlackoutDate} from '../../../shared/types'
import {getCourse} from '../../../reducers/course'
import {getCoursePace} from '../../../reducers/course_paces'
import {coursePaceActions} from '../../../actions/course_paces'
import {actions as uiActions} from '../../../actions/ui'
import {actions as blackoutDateActions} from '../../../shared/actions/blackout_dates'
import {getBlackoutDates} from '../../../shared/reducers/blackout_dates'
import {getSyncing, getResponsiveSize} from '../../../reducers/ui'
import type {EnvCoursePaces} from '@canvas/global/env/EnvCoursePaces'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import SettingsMenu from './SettingsMenu'

import type {ButtonProps} from '@instructure/ui-buttons'

// Allow unchecked access to module-specific ENV variables
declare const ENV: GlobalEnv & EnvCoursePaces

const I18n = createI18nScope('course_paces_settings')

const {Item: MenuItem} = Menu as any
interface StoreProps {
  readonly blackoutDates: BlackoutDate[]
  readonly coursePace: CoursePace
  readonly isSyncing: boolean
  readonly responsiveSize: ResponsiveSizes
}

interface DispatchProps {
  readonly toggleExcludeWeekends: typeof coursePaceActions.toggleExcludeWeekends
  readonly toggleSelectedDaysToSkip: typeof coursePaceActions.toggleSelectedDaysToSkip
  readonly updateBlackoutDates: typeof blackoutDateActions.updateBlackoutDates
}

interface PassedProps {
  readonly margin?: ButtonProps['margin']
  readonly isBlueprintLocked: boolean | undefined
}

export type ComponentProps = StoreProps & DispatchProps & PassedProps

interface LocalState {
  readonly showBlackoutDatesModal: boolean
  readonly showSettingsPopover: boolean
  readonly blackoutDatesModalKey: string
  readonly showWeightedAssignments: boolean
}

export class Settings extends React.Component<ComponentProps, LocalState> {
  constructor(props: ComponentProps) {
    super(props)
    this.state = {
      showBlackoutDatesModal: false,
      showSettingsPopover: false,
      blackoutDatesModalKey: uid('bod_', 2),
      showWeightedAssignments: false,
    }
  }

  /* Callbacks */

  showBlackoutDatesModal = () => {
    this.setState({
      showBlackoutDatesModal: true,
      blackoutDatesModalKey: uid(),
    })
  }

  closeBlackoutDatesModal = (): void => {
    this.setState({
      showBlackoutDatesModal: false,
    })
  }

  closeWeightedAssignmentsTray = () => {
    this.setState({
      showWeightedAssignments: false,
    })
  }

  handleSaveBlackoutDates = (updatedBlackoutDates: BlackoutDate[]) => {
    this.props.updateBlackoutDates(updatedBlackoutDates)
    this.closeBlackoutDatesModal()
  }

  validateEnd = (date: moment.Moment) => {
    let error: string | undefined

    if (ENV.VALID_DATE_RANGE.start_at.date && date < moment(ENV.VALID_DATE_RANGE.start_at.date)) {
      error = I18n.t('Date is before course start date')
    } else if (
      ENV.VALID_DATE_RANGE.end_at.date &&
      date > moment(ENV.VALID_DATE_RANGE.end_at.date)
    ) {
      error = I18n.t('Date is after course end date')
    }
    return error
  }

  renderManageBlackoutDates = () => {
    if (this.props.coursePace.context_type === 'Course') {
      return (
        <MenuItem
          type="button"
          onSelect={() => {
            this.setState({showSettingsPopover: false})
            this.showBlackoutDatesModal()
          }}
          disabled={this.props.isSyncing}
        >
          {I18n.t('Manage Blackout Dates')}
        </MenuItem>
      )
    }
  }

  /* Renderers */

  render() {
    return (
      <div style={{display: 'inline-block'}}>
        <Tooltip
          renderTip={I18n.t('You cannot edit a locked pace')}
          on={this.props.isBlueprintLocked ? ['hover', 'focus'] : []}
        >
          <BlackoutDatesModal
            key={this.state.blackoutDatesModalKey}
            blackoutDates={this.props.blackoutDates}
            open={this.state.showBlackoutDatesModal}
            onSave={this.handleSaveBlackoutDates}
            onCancel={this.closeBlackoutDatesModal}
          />

          <SettingsMenu
            isSyncing={this.props.isSyncing}
            responsiveSize={this.props.responsiveSize}
            margin={this.props.margin}
            menuPlacement={() => 'bottom end'}
            coursePace={this.props.coursePace}
            showSettingsPopover={this.state.showSettingsPopover}
            showBlackoutDatesModal={this.showBlackoutDatesModal}
            toggleShowSettingsPopover={newState =>
              this.setState({
                showSettingsPopover: newState,
              })
            }
            isBlueprintLocked={this.props.isBlueprintLocked}
            toggleExcludeWeekends={this.props.toggleExcludeWeekends}
            toggleSelectedDaysToSkip={this.props.toggleSelectedDaysToSkip}
          />
        </Tooltip>
      </div>
    )
  }
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    blackoutDates: getBlackoutDates(state),
    // @ts-expect-error
    course: getCourse(state),
    courseId: getCourse(state).id,
    coursePace: getCoursePace(state),
    isSyncing: getSyncing(state),
    responsiveSize: getResponsiveSize(state),
  }
}

export default connect(mapStateToProps, {
  toggleExcludeWeekends: coursePaceActions.toggleExcludeWeekends,
  toggleSelectedDaysToSkip: coursePaceActions.toggleSelectedDaysToSkip,
  loadLatestPaceByContext: coursePaceActions.loadLatestPaceByContext,
  showLoadingOverlay: uiActions.showLoadingOverlay,
  updateBlackoutDates: blackoutDateActions.updateBlackoutDates,
})(Settings)
