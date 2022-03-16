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
import moment from 'moment-timezone'
import {connect} from 'react-redux'

import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Heading} from '@instructure/ui-heading'
import {IconSettingsLine} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {Popover} from '@instructure/ui-popover'
import {View} from '@instructure/ui-view'

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import BlackoutDates from './blackout_dates'
import * as CoursePaceApi from '../../../api/course_pace_api'
import {StoreState, CoursePace} from '../../../types'
import {Course} from '../../../shared/types'
import {getCourse} from '../../../reducers/course'
import {getExcludeWeekends, getCoursePace, getPacePublishing} from '../../../reducers/course_paces'
import {coursePaceActions} from '../../../actions/course_paces'
import {actions as uiActions} from '../../../actions/ui'
import UpdateExistingPacesModal from '../../../shared/components/update_existing_paces_modal'

const I18n = useI18nScope('course_paces_settings')

interface StoreProps {
  readonly course: Course
  readonly courseId: string
  readonly excludeWeekends: boolean
  readonly coursePace: CoursePace
  readonly pacePublishing: boolean
}

interface DispatchProps {
  readonly loadLatestPaceByContext: typeof coursePaceActions.loadLatestPaceByContext
  readonly setEditingBlackoutDates: typeof uiActions.setEditingBlackoutDates
  readonly setEndDate: typeof coursePaceActions.setEndDate
  readonly showLoadingOverlay: typeof uiActions.showLoadingOverlay
  readonly toggleExcludeWeekends: typeof coursePaceActions.toggleExcludeWeekends
}

interface PassedProps {
  readonly margin?: string
}

type ComponentProps = StoreProps & DispatchProps & PassedProps

interface LocalState {
  readonly changeMadeToBlackoutDates: boolean
  readonly showBlackoutDatesModal: boolean
  readonly showSettingsPopover: boolean
  readonly showUpdateExistingPacesModal: boolean
}

export class Settings extends React.Component<ComponentProps, LocalState> {
  constructor(props: ComponentProps) {
    super(props)
    this.state = {
      changeMadeToBlackoutDates: false,
      showBlackoutDatesModal: false,
      showSettingsPopover: false,
      showUpdateExistingPacesModal: false
    }
  }

  /* Callbacks */

  showBlackoutDatesModal = () => {
    this.setState({showBlackoutDatesModal: true})
    this.props.setEditingBlackoutDates(true)
  }

  republishAllPaces = () => {
    this.props.showLoadingOverlay('Publishing...')
    CoursePaceApi.republishAllPacesForCourse(this.props.courseId)
      .then(this.onCloseUpdateExistingPacesModal)
      .catch(err => {
        showFlashAlert({
          message: I18n.t('Failed publishing pace'),
          err,
          type: 'error'
        })
      })
  }

  onCloseBlackoutDatesModal = () => {
    this.setState(({changeMadeToBlackoutDates}) => ({
      showBlackoutDatesModal: false,
      showUpdateExistingPacesModal: changeMadeToBlackoutDates,
      changeMadeToBlackoutDates: false
    }))
    if (!this.state.changeMadeToBlackoutDates) {
      this.props.setEditingBlackoutDates(false)
    }
  }

  onCloseUpdateExistingPacesModal = async () => {
    this.setState({showUpdateExistingPacesModal: false})
    await this.props.loadLatestPaceByContext(
      this.props.coursePace.context_type,
      this.props.coursePace.context_id
    )
    this.props.setEditingBlackoutDates(false)
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

  renderBlackoutDatesModal() {
    return (
      <Modal
        open={this.state.showBlackoutDatesModal}
        onDismiss={() => this.setState({showBlackoutDatesModal: false})}
        label="Blackout Dates"
        shouldCloseOnDocumentClick
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="medium"
            variant="icon"
            onClick={this.onCloseBlackoutDatesModal}
          >
            Close
          </CloseButton>
          <Heading>Blackout Dates</Heading>
        </Modal.Header>

        <Modal.Body>
          <View as="div" width="36rem">
            <BlackoutDates onChange={() => this.setState({changeMadeToBlackoutDates: true})} />
          </View>
        </Modal.Body>

        <Modal.Footer>
          <Button color="secondary" onClick={this.onCloseBlackoutDatesModal}>
            Close
          </Button>
          &nbsp;
        </Modal.Footer>
      </Modal>
    )
  }

  render() {
    if (this.props.coursePace.context_type === 'Enrollment') {
      return null
    }
    return (
      <div style={{display: 'inline-block'}}>
        {this.renderBlackoutDatesModal()}
        <UpdateExistingPacesModal
          open={this.state.showUpdateExistingPacesModal}
          onDismiss={this.onCloseUpdateExistingPacesModal}
          confirm={this.republishAllPaces}
        />
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
            {/* Commented out since we're not implementing these features yet */}
            {/* </View> */}
            {/* <CondensedButton */}
            {/*  onClick={() => { */}
            {/*    this.setState({showSettingsPopover: false}) */}
            {/*    this.showBlackoutDatesModal() */}
            {/*  }} */}
            {/*  margin="small 0 0" */}
            {/* > */}
            {/*  <AccessibleContent alt={I18n.t('View Blackout Dates')}> */}
            {/*    {I18n.t('Blackout Dates')} */}
            {/*  </AccessibleContent> */}
            {/* </CondensedButton> */}
          </View>
        </Popover>
      </div>
    )
  }
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    course: getCourse(state),
    courseId: getCourse(state).id,
    excludeWeekends: getExcludeWeekends(state),
    coursePace: getCoursePace(state),
    pacePublishing: getPacePublishing(state)
  }
}

export default connect(mapStateToProps, {
  loadLatestPaceByContext: coursePaceActions.loadLatestPaceByContext,
  setEditingBlackoutDates: uiActions.setEditingBlackoutDates,
  setEndDate: coursePaceActions.setEndDate,
  showLoadingOverlay: uiActions.showLoadingOverlay,
  toggleExcludeWeekends: coursePaceActions.toggleExcludeWeekends
})(Settings)
