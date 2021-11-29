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
import I18n from 'i18n!pace_plans_settings'
import {connect} from 'react-redux'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Heading} from '@instructure/ui-heading'
import {IconSettingsLine} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {Popover} from '@instructure/ui-popover'
import {View} from '@instructure/ui-view'

import BlackoutDates from './blackout_dates'
import * as PacePlanApi from '../../../api/pace_plan_api'
import {StoreState, PacePlan} from '../../../types'
import {getCourse} from '../../../reducers/course'
import {getExcludeWeekends, getPacePlan, getPlanPublishing} from '../../../reducers/pace_plans'
import {pacePlanActions} from '../../../actions/pace_plans'
import {actions as uiActions} from '../../../actions/ui'
import PacePlanDateSelector from '../projected_dates/date_selector'
import UpdateExistingPlansModal from '../../../shared/components/update_existing_plans_modal'

interface StoreProps {
  readonly courseId: string
  readonly excludeWeekends: boolean
  readonly pacePlan: PacePlan
  readonly planPublishing: boolean
}

interface DispatchProps {
  readonly loadLatestPlanByContext: typeof pacePlanActions.loadLatestPlanByContext
  readonly setEditingBlackoutDates: typeof uiActions.setEditingBlackoutDates
  readonly showLoadingOverlay: typeof uiActions.showLoadingOverlay
  readonly toggleExcludeWeekends: typeof pacePlanActions.toggleExcludeWeekends
  readonly toggleHardEndDates: typeof pacePlanActions.toggleHardEndDates
}

type ComponentProps = StoreProps & DispatchProps

interface LocalState {
  readonly changeMadeToBlackoutDates: boolean
  readonly showBlackoutDatesModal: boolean
  readonly showSettingsPopover: boolean
  readonly showUpdateExistingPlansModal: boolean
}

export class Settings extends React.Component<ComponentProps, LocalState> {
  constructor(props: ComponentProps) {
    super(props)
    this.state = {
      changeMadeToBlackoutDates: false,
      showBlackoutDatesModal: false,
      showSettingsPopover: false,
      showUpdateExistingPlansModal: false
    }
  }

  /* Callbacks */

  showBlackoutDatesModal = () => {
    this.setState({showBlackoutDatesModal: true})
    this.props.setEditingBlackoutDates(true)
  }

  republishAllPlans = () => {
    this.props.showLoadingOverlay('Publishing...')
    PacePlanApi.republishAllPlansForCourse(this.props.courseId).then(
      this.onCloseUpdateExistingPlansModal
    )
  }

  onCloseBlackoutDatesModal = () => {
    this.setState(({changeMadeToBlackoutDates}) => ({
      showBlackoutDatesModal: false,
      showUpdateExistingPlansModal: changeMadeToBlackoutDates,
      changeMadeToBlackoutDates: false
    }))
    if (!this.state.changeMadeToBlackoutDates) {
      this.props.setEditingBlackoutDates(false)
    }
  }

  onCloseUpdateExistingPlansModal = async () => {
    this.setState({showUpdateExistingPlansModal: false})
    await this.props.loadLatestPlanByContext(
      this.props.pacePlan.context_type,
      this.props.pacePlan.context_id
    )
    this.props.setEditingBlackoutDates(false)
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

  renderHardEndDatesCheckbox() {
    return (
      <View as="div" margin="small 0 0" width="100%">
        <Checkbox
          data-testid='require-end-date-toggle'
          label={I18n.t('Require Completion by Specified End Date')}
          checked={this.props.pacePlan.hard_end_dates}
          disabled={this.props.planPublishing}
          onChange={() => this.props.toggleHardEndDates()}
        />
      </View>
    )
  }

  renderHardEndDatesInput() {
    if (!this.props.pacePlan.hard_end_dates) return null

    return (
      <View id="pace-plans-required-end-date-input" as="div" margin="small 0 0" width="100%">
        <PacePlanDateSelector
          type="end-selection"
          width="100%"
          label={<ScreenReaderContent>{I18n.t('End Date')}</ScreenReaderContent>}
        />
      </View>
    )
  }

  render() {
    return (
      <div>
        {this.renderBlackoutDatesModal()}
        <UpdateExistingPlansModal
          open={this.state.showUpdateExistingPlansModal}
          onDismiss={this.onCloseUpdateExistingPlansModal}
          confirm={this.republishAllPlans}
        />
        <Popover
          on="click"
          renderTrigger={
            <IconButton screenReaderLabel={I18n.t('Modify Settings')}>
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
                disabled={this.props.planPublishing}
                onChange={() => this.props.toggleExcludeWeekends()}
              />
            </View>
            <View>
              {this.renderHardEndDatesCheckbox()}
              {this.renderHardEndDatesInput()}
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
    courseId: getCourse(state).id,
    excludeWeekends: getExcludeWeekends(state),
    pacePlan: getPacePlan(state),
    planPublishing: getPlanPublishing(state)
  }
}

export default connect(mapStateToProps, {
  loadLatestPlanByContext: pacePlanActions.loadLatestPlanByContext,
  setEditingBlackoutDates: uiActions.setEditingBlackoutDates,
  showLoadingOverlay: uiActions.showLoadingOverlay,
  toggleExcludeWeekends: pacePlanActions.toggleExcludeWeekends,
  toggleHardEndDates: pacePlanActions.toggleHardEndDates
})(Settings)
