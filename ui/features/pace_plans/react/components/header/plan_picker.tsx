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
import {Flex} from '@instructure/ui-flex'
import {SimpleSelect} from '@instructure/ui-simple-select'

import {
  StoreState,
  Enrollment,
  Sections,
  Section,
  PacePlan,
  PlanContextTypes,
  PlanTypes
} from '../../types'
import {Course} from '../../shared/types'
import {getSortedEnrollments} from '../../reducers/enrollments'
import {getSections} from '../../reducers/sections'
import {getCourse} from '../../reducers/course'
import {getPacePlan, getActivePlanContext} from '../../reducers/pace_plans'
import {pacePlanActions} from '../../actions/pace_plans'
import {getSelectedPlanType} from '../../reducers/ui'

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Option} = SimpleSelect as any

interface StoreProps {
  readonly enrollments: Enrollment[]
  readonly sections: Sections
  readonly pacePlan: PacePlan
  readonly course: Course
  readonly selectedPlanType: PlanTypes
  readonly activePlanContext: Course | Section | Enrollment
}

interface DispatchProps {
  readonly loadLatestPlanByContext: typeof pacePlanActions.loadLatestPlanByContext
}

interface PassedProps {
  readonly inline?: boolean
}

type ComponentProps = StoreProps & DispatchProps & PassedProps

interface OptionValue {
  readonly id: string
}

export class PlanPicker extends React.Component<ComponentProps> {
  /* Helpers */

  formatOptionValue = (contextType: PlanContextTypes, contextId: string | number): string => {
    return [contextType, contextId].join(':')
  }

  getSelectedOption = (planType: PlanTypes): string | null => {
    const option = this.formatOptionValue(
      this.props.pacePlan.context_type,
      this.props.pacePlan.context_id
    )
    return planType === this.props.selectedPlanType ? option : null
  }

  sortedSectionIds = (): string[] => {
    return Object.keys(this.props.sections).sort((a, b) => {
      const sectionA: Section = this.props.sections[a]
      const sectionB: Section = this.props.sections[b]
      if (sectionA.name > sectionB.name) {
        return 1
      } else if (sectionA.name < sectionB.name) {
        return -1
      } else {
        return 0
      }
    })
  }

  /* Callbacks */

  onChangePlan = (e: any, value: OptionValue) => {
    const valueSplit = value.id.split(':')
    const contextType = valueSplit[0] as PlanContextTypes
    const contextId = valueSplit[1]

    if (
      String(this.props.pacePlan.context_id) === contextId &&
      this.props.pacePlan.context_type === contextType
    ) {
      return
    }

    this.props.loadLatestPlanByContext(contextType, contextId)
  }

  /* Renderers */

  renderSectionOptions = () => {
    const options = this.sortedSectionIds().map(sectionId => {
      const section: Section = this.props.sections[sectionId]
      const value = this.formatOptionValue('Section', section.id)
      return (
        <Option id={`plan-section-${sectionId}`} key={`plan-section-${sectionId}`} value={value}>
          {section.name}
        </Option>
      )
    })

    options.unshift(
      <Option
        id="plan-primary"
        key="plan-primary"
        value={this.formatOptionValue('Course', this.props.course.id)}
      >
        Master Plan
      </Option>
    )

    return options
  }

  renderEnrollmentOptions = () => {
    return this.props.enrollments.map((enrollment: Enrollment) => {
      const value = this.formatOptionValue('Enrollment', enrollment.id)

      return (
        <Option
          id={`plan-enrollment-${enrollment.id}`}
          key={`plan-enrollment-${enrollment.id}`}
          value={value}
        >
          {enrollment.full_name}
        </Option>
      )
    })
  }

  renderPlanSelector = () => {
    const options =
      this.props.selectedPlanType === 'student'
        ? this.renderEnrollmentOptions()
        : this.renderSectionOptions()

    return (
      <SimpleSelect
        isInline={this.props.inline}
        renderLabel="Plan"
        width="300px"
        value={this.getSelectedOption(this.props.selectedPlanType)}
        onChange={this.onChangePlan}
      >
        {options}
      </SimpleSelect>
    )
  }

  render() {
    return <Flex margin="0 0 small 0">{this.renderPlanSelector()}</Flex>
  }
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    enrollments: getSortedEnrollments(state),
    sections: getSections(state),
    pacePlan: getPacePlan(state),
    course: getCourse(state),
    selectedPlanType: getSelectedPlanType(state),
    activePlanContext: getActivePlanContext(state)
  }
}

export default connect(mapStateToProps, {
  loadLatestPlanByContext: pacePlanActions.loadLatestPlanByContext
})(PlanPicker)
