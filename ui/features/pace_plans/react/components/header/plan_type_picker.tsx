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

import {actions as uiActions} from '../../actions/ui'
import {StoreState, PlanTypes, Enrollment} from '../../types'
import {getSelectedPlanType} from '../../reducers/ui'
import {getSortedEnrollments} from '../../reducers/enrollments'

interface StoreProps {
  readonly selectedPlanType: PlanTypes
  readonly enrollments: Enrollment[]
}

interface DispatchProps {
  readonly setSelectedPlanType: typeof uiActions.setSelectedPlanType
}

type ComponentProps = StoreProps & DispatchProps

interface ButtonProps {
  readonly selected: boolean
  readonly disabled?: boolean
}

const buttonStyles = ({selected, disabled}: ButtonProps) => {
  return {
    width: '107px',
    height: '36px',
    border: '1px solid #c7cdd1',
    fontSize: '14px',
    fontWeight: 600,
    padding: '0',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: selected ? '#73818C' : '#F5F5F5',
    color: selected ? '#FFFFFF' : '#394B58',
    cursor: disabled ? 'not-allowed' : selected ? 'normal' : 'pointer',
    opacity: disabled ? '0.4' : undefined
  }
}

export class PlanTypePicker extends React.PureComponent<ComponentProps> {
  render() {
    return (
      <Flex>
        <div
          role="button"
          style={{
            ...buttonStyles({selected: this.props.selectedPlanType === 'template'}),
            borderRadius: '4px 0px 0px 4px'
          }}
          onClick={() => this.props.setSelectedPlanType('template')}
        >
          Template Plans
        </div>
        <div
          style={{
            ...buttonStyles({
              selected: this.props.selectedPlanType === 'student',
              disabled: this.props.enrollments.length === 0
            }),
            borderLeft: '0',
            borderRadius: '0px 4px 4px 0px'
          }}
          onClick={() =>
            this.props.enrollments.length > 0 &&
            this.props.setSelectedPlanType('student', this.props.enrollments[0].id)
          }
        >
          Student Plans
        </div>
      </Flex>
    )
  }
}

const mapDispatchToProps = (state: StoreState): StoreProps => {
  return {
    selectedPlanType: getSelectedPlanType(state),
    enrollments: getSortedEnrollments(state)
  }
}

export default connect(mapDispatchToProps, {setSelectedPlanType: uiActions.setSelectedPlanType})(
  PlanTypePicker
)
