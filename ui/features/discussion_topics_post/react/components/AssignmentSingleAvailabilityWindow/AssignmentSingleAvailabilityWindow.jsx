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

import {AssignmentAvailabilityWindow} from '../AssignmentAvailabilityWindow/AssignmentAvailabilityWindow'
import {AssignmentContext} from '../AssignmentContext/AssignmentContext'
import {AssignmentDueDate} from '../AssignmentDueDate/AssignmentDueDate'

import PropTypes from 'prop-types'
import React from 'react'
import {responsiveQuerySizes} from '../../utils/index'

import {Responsive} from '@instructure/ui-responsive'
import {Flex} from '@instructure/ui-flex'

export function AssignmentSingleAvailabilityWindow({...props}) {
  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({tablet: true, desktop: true})}
      props={{
        tablet: {
          dueDateMargin: 'none',
        },
        desktop: {
          dueDateMargin: '0 0 0 x-small',
        },
      }}
      render={(_responsiveProps, matches) => {
        const group = props.singleOverrideWithNoDefault ? props.assignmentOverrides[0]?.title : ''
        const availabilityInformation = props.singleOverrideWithNoDefault
          ? props.assignmentOverrides[0]
          : props.assignment

        return (
          <Flex
            direction={
              availabilityInformation?.set?.__typename === 'AdhocStudents' ? 'column' : 'row'
            }
          >
            {props.isAdmin && matches.includes('desktop') ? (
              <Flex.Item padding="x-small small x-small 0">
                <AssignmentContext
                  group={group}
                  assignmentOverride={
                    availabilityInformation?.set?.__typename === 'AdhocStudents'
                      ? availabilityInformation
                      : null
                  }
                />
              </Flex.Item>
            ) : null}
            <Flex.Item>
              <Flex>
                <Flex.Item>
                  <AssignmentDueDate
                    dueDate={availabilityInformation?.dueAt}
                    onSetDueDateTrayOpen={props.onSetDueDateTrayOpen}
                  />
                </Flex.Item>
                {(availabilityInformation.unlockAt || availabilityInformation.lockAt) &&
                matches.includes('desktop') ? (
                  <Flex.Item margin="0 0 0 small">
                    <AssignmentAvailabilityWindow
                      availableDate={availabilityInformation.unlockAt}
                      untilDate={availabilityInformation.lockAt}
                    />
                  </Flex.Item>
                ) : null}
              </Flex>
            </Flex.Item>
          </Flex>
        )
      }}
    />
  )
}

AssignmentSingleAvailabilityWindow.propTypes = {
  singleOverrideWithNoDefault: PropTypes.bool,
  isAdmin: PropTypes.bool,
  onSetDueDateTrayOpen: PropTypes.func,
  assignment: PropTypes.object,
  assignmentOverrides: PropTypes.array,
}
