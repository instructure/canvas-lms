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
import {connect} from 'react-redux'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {IconSettingsLine} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'

import BlackoutDates from './blackout_dates'
import * as PacePlanApi from '../../../api/pace_plan_api'
import {StoreState, PacePlan} from '../../../types'
import {getCourse} from '../../../reducers/course'
import {getPacePlan} from '../../../reducers/pace_plans'
import {pacePlanActions} from '../../../actions/pace_plans'
import {actions as uiActions} from '../../../actions/ui'
import UpdateExistingPlansModal from '../../../shared/components/update_existing_plans_modal'

interface StoreProps {
  readonly courseId: string
  readonly pacePlan: PacePlan
}

interface DispatchProps {
  readonly loadLatestPlanByContext: typeof pacePlanActions.loadLatestPlanByContext
  readonly setEditingBlackoutDates: typeof uiActions.setEditingBlackoutDates
  readonly showLoadingOverlay: typeof uiActions.showLoadingOverlay
}

type ComponentProps = StoreProps & DispatchProps

interface LocalState {
  readonly showBlackoutDatesModal: boolean
  readonly showUpdateExistingPlansModal: boolean
  readonly changeMadeToBlackoutDates: boolean
}

export class Settings extends React.Component<ComponentProps, LocalState> {
  /* Lifecycle */

  constructor(props: ComponentProps) {
    super(props)
    this.state = {
      showBlackoutDatesModal: false,
      showUpdateExistingPlansModal: false,
      changeMadeToBlackoutDates: false
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

  render() {
    return (
      <div>
        {this.renderBlackoutDatesModal()}
        <UpdateExistingPlansModal
          open={this.state.showUpdateExistingPlansModal}
          onDismiss={this.onCloseUpdateExistingPlansModal}
          confirm={this.republishAllPlans}
        />
        <IconButton onClick={this.showBlackoutDatesModal} screenReaderLabel="Settings">
          <IconSettingsLine />
        </IconButton>
      </div>
    )
  }
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    courseId: getCourse(state).id,
    pacePlan: getPacePlan(state)
  }
}

export default connect(mapStateToProps, {
  loadLatestPlanByContext: pacePlanActions.loadLatestPlanByContext,
  setEditingBlackoutDates: uiActions.setEditingBlackoutDates,
  showLoadingOverlay: uiActions.showLoadingOverlay
})(Settings)
