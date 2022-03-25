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
import {useScope as useI18nScope} from '@canvas/i18n'
import moment from 'moment-timezone'
import {connect} from 'react-redux'

import {CondensedButton, IconButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {IconSettingsLine} from '@instructure/ui-icons'
import {Popover} from '@instructure/ui-popover'
import {View} from '@instructure/ui-view'
import {uid} from '@instructure/uid'

import BlackoutDatesModal from '../../../shared/components/blackout_dates_modal'
import {StoreState, CoursePace} from '../../../types'
import {Course, BlackoutDate} from '../../../shared/types'
import {getCourse} from '../../../reducers/course'
import {getExcludeWeekends, getCoursePace, getPacePublishing} from '../../../reducers/course_paces'
import {coursePaceActions} from '../../../actions/course_paces'
import {actions as uiActions} from '../../../actions/ui'
import {actions as blackoutDateActions} from '../../../shared/actions/blackout_dates'
import {getBlackoutDates} from '../../../shared/reducers/blackout_dates'

const I18n = useI18nScope('course_paces_settings')

interface StoreProps {
  readonly blackoutDates: BlackoutDate[]
  readonly course: Course
  readonly courseId: string
  readonly excludeWeekends: boolean
  readonly coursePace: CoursePace
  readonly pacePublishing: boolean
}

interface DispatchProps {
  readonly loadLatestPaceByContext: typeof coursePaceActions.loadLatestPaceByContext
  readonly setEndDate: typeof coursePaceActions.setEndDate
  readonly showLoadingOverlay: typeof uiActions.showLoadingOverlay
  readonly toggleExcludeWeekends: typeof coursePaceActions.toggleExcludeWeekends
  readonly updateBlackoutDates: typeof blackoutDateActions.updateBlackoutDates
}

interface PassedProps {
  readonly margin?: string
}

type ComponentProps = StoreProps & DispatchProps & PassedProps

interface LocalState {
  readonly showBlackoutDatesModal: boolean
  readonly showSettingsPopover: boolean
  readonly blackoutDatesModalKey: string
}

export class Settings extends React.Component<ComponentProps, LocalState> {
  constructor(props: ComponentProps) {
    super(props)
    this.state = {
      showBlackoutDatesModal: false,
      showSettingsPopover: false,
      blackoutDatesModalKey: uid('bod_', 2)
    }
  }

  /* Callbacks */

  showBlackoutDatesModal = () => {
    this.setState({showBlackoutDatesModal: true})
  }

  closeBlackoutDatesModal = (): void => {
    this.setState({
      showBlackoutDatesModal: false,
      blackoutDatesModalKey: uid()
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

  /* Renderers */

  render() {
    if (this.props.coursePace.context_type === 'Enrollment') {
      return null
    }
    return (
      <div style={{display: 'inline-block'}}>
        {ENV.FEATURES.course_paces_blackout_dates && (
          <BlackoutDatesModal
            key={this.state.blackoutDatesModalKey}
            blackoutDates={this.props.blackoutDates}
            open={this.state.showBlackoutDatesModal}
            onSave={this.handleSaveBlackoutDates}
            onCancel={this.closeBlackoutDatesModal}
          />
        )}
        <Popover
          on="click"
          renderTrigger={
            <IconButton screenReaderLabel={I18n.t('Modify Settings')} margin={this.props.margin}>
              <IconSettingsLine />
            </IconButton>
          }
          placement="bottom start"
          isShowingContent={this.state.showSettingsPopover}
          onShowContent={() => this.setState({showSettingsPopover: true})}
          onHideContent={() => this.setState({showSettingsPopover: false})}
          withArrow={false}
        >
          <View as="div" padding="small">
            <View as="div">
              <Checkbox
                data-testid="skip-weekends-toggle"
                label={I18n.t('Skip Weekends')}
                checked={this.props.excludeWeekends}
                disabled={this.props.pacePublishing}
                onChange={() => this.props.toggleExcludeWeekends()}
              />
            </View>
            {ENV.FEATURES.course_paces_blackout_dates && (
              <View as="div">
                <CondensedButton
                  onClick={() => {
                    this.setState({showSettingsPopover: false})
                    this.showBlackoutDatesModal()
                  }}
                  margin="small 0 0"
                >
                  {I18n.t('Manage Blackout Dates')}
                </CondensedButton>
              </View>
            )}
          </View>
        </Popover>
      </div>
    )
  }
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    blackoutDates: getBlackoutDates(state),
    course: getCourse(state),
    courseId: getCourse(state).id,
    excludeWeekends: getExcludeWeekends(state),
    coursePace: getCoursePace(state),
    pacePublishing: getPacePublishing(state)
  }
}

export default connect(mapStateToProps, {
  loadLatestPaceByContext: coursePaceActions.loadLatestPaceByContext,
  setEndDate: coursePaceActions.setEndDate,
  showLoadingOverlay: uiActions.showLoadingOverlay,
  toggleExcludeWeekends: coursePaceActions.toggleExcludeWeekends,
  updateBlackoutDates: blackoutDateActions.updateBlackoutDates
})(Settings)
