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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {IconWarningSolid} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {StoreState, PacePlan} from '../../../types'
import {getPacePlan, getExcludeWeekends, isPlanCompleted} from '../../../reducers/pace_plans'
import {getDivideIntoWeeks} from '../../../reducers/ui'
import {actions as uiActions} from '../../../actions/ui'
import {autoSavingActions as pacePlanActions} from '../../../actions/pace_plans'
import DaysSelector from './days_selector'
import WeeksSelector from './weeks_selector'
import StartDateSelector from './start_date_selector'
import EndDateSelector from './end_date_selector'
import {Heading} from '@instructure/ui-heading'

const CheckboxWrapper = ({children}) => <View maxWidth="10.5rem">{children}</View>

interface StoreProps {
  readonly pacePlan: PacePlan
  readonly ignoreWeeks: boolean
  readonly excludeWeekends: boolean
  readonly planCompleted: boolean
  readonly enrollmentHardEndDatePlan: boolean
}

interface DispatchProps {
  readonly toggleDivideIntoWeeks: typeof uiActions.toggleDivideIntoWeeks
  readonly toggleExcludeWeekends: typeof pacePlanActions.toggleExcludeWeekends
  readonly toggleHardEndDates: typeof pacePlanActions.toggleHardEndDates
  readonly setAdjustingHardEndDatesAfter: typeof uiActions.setAdjustingHardEndDatesAfter
}

type ComponentProps = StoreProps & DispatchProps

interface LocalState {
  readonly showHardEndDateModal: boolean
}

export class PlanLengthPicker extends React.Component<ComponentProps, LocalState> {
  /* Lifecycle */

  constructor(props: ComponentProps) {
    super(props)
    this.state = {showHardEndDateModal: false}
  }

  /* Callbacks */

  toggleExcludeWeekends = () => {
    let saveParams = {}

    if (this.props.enrollmentHardEndDatePlan) {
      saveParams = {compress_items_after: 0}
      this.props.setAdjustingHardEndDatesAfter(-1) // Set this to -1 so that all date inputs are disabled
    }

    this.props.toggleExcludeWeekends(saveParams)
  }

  toggleHardEndDates = () => {
    this.props.toggleHardEndDates()
    this.setState({showHardEndDateModal: false})
  }

  /* Renderers */

  hardEndDatesModalBodyText = () => {
    if (this.props.pacePlan.hard_end_dates) {
      return `
        Are you sure you want to remove the requirement that students complete the course by a specified
        end date? Due dates will be calculated from the student plan start dates.
      `
    } else {
      return `
        Are you sure you want to require that students complete the course by a specified end date?
        Due dates will be weighted towards the end of the course.
      `
    }
  }

  render() {
    return (
      <Flex width="32.5rem" alignItems="center">
        <View width="100%">
          <Flex justifyItems="space-between">
            <div>
              <StartDateSelector />
            </div>
            <div>
              <EndDateSelector />
            </div>
            <div>
              <WeeksSelector />
            </div>
            <div>
              <DaysSelector />
            </div>
          </Flex>
          <Flex alignItems="start" justifyItems="space-between" margin="medium 0 0">
            <CheckboxWrapper>
              <Checkbox
                label="Skip Weekends"
                checked={this.props.excludeWeekends}
                onChange={this.toggleExcludeWeekends}
                disabled={this.props.planCompleted}
              />
            </CheckboxWrapper>
            <CheckboxWrapper>
              <Checkbox
                label="Require Completion by Specified End Date"
                checked={this.props.pacePlan.hard_end_dates}
                onChange={() => this.setState({showHardEndDateModal: true})}
                disabled={this.props.planCompleted || !this.props.pacePlan.end_date}
              />
            </CheckboxWrapper>
            <CheckboxWrapper>
              <Checkbox
                label="Divide into Weeks"
                checked={this.props.ignoreWeeks}
                onChange={this.props.toggleDivideIntoWeeks}
                disabled={this.props.planCompleted}
              />
            </CheckboxWrapper>
          </Flex>
        </View>

        <Modal
          open={this.state.showHardEndDateModal}
          onDismiss={() => this.setState({showHardEndDateModal: false})}
          label="Are you sure?"
          shouldCloseOnDocumentClick
        >
          <Modal.Header>
            <CloseButton
              placement="end"
              offset="medium"
              variant="icon"
              onClick={() => this.setState({showHardEndDateModal: false})}
            >
              Close
            </CloseButton>
            <Heading>Are you sure?</Heading>
          </Modal.Header>
          <Modal.Body>
            <View as="div" width="28rem" margin="0 0 medium">
              <Text>{this.hardEndDatesModalBodyText()}</Text>
            </View>
            <View as="div">
              <View margin="0 small 0 0">
                <IconWarningSolid color="warning" margin="0 small 0 0" />
              </View>
              <Text>Previously entered due dates may be impacted.</Text>
            </View>
          </Modal.Body>

          <Modal.Footer>
            <Button color="secondary" onClick={() => this.setState({showHardEndDateModal: false})}>
              Cancel
            </Button>
            &nbsp;
            <Button color="primary" onClick={this.toggleHardEndDates}>
              Yes, I confirm.
            </Button>
          </Modal.Footer>
        </Modal>
      </Flex>
    )
  }
}

const mapStateToProps = (state: StoreState): StoreProps => {
  const pacePlan = getPacePlan(state)

  return {
    pacePlan,
    ignoreWeeks: getDivideIntoWeeks(state),
    excludeWeekends: getExcludeWeekends(state),
    planCompleted: isPlanCompleted(state),
    enrollmentHardEndDatePlan: !!(pacePlan.hard_end_dates && pacePlan.context_type === 'Enrollment')
  }
}

export default connect(mapStateToProps, {
  toggleDivideIntoWeeks: uiActions.toggleDivideIntoWeeks,
  toggleExcludeWeekends: pacePlanActions.toggleExcludeWeekends,
  toggleHardEndDates: pacePlanActions.toggleHardEndDates,
  setAdjustingHardEndDatesAfter: uiActions.setAdjustingHardEndDatesAfter
})(PlanLengthPicker)
