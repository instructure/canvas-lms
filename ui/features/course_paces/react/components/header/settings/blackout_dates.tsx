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

import {StoreState} from '../../../types'
import {BlackoutDate} from '../../../shared/types'
import {getBlackoutDates} from '../../../shared/reducers/blackout_dates'
import {actions} from '../../../shared/actions/blackout_dates'
import {getCourse} from '../../../reducers/course'
import {BlackoutDatesTable} from '../../../shared/components/blackout_dates_table'
import NewBlackoutDatesForm from '../../../shared/components/new_blackout_dates_form'

interface PassedProps {
  readonly onChange?: () => any
}

interface StoreProps {
  readonly blackoutDates: BlackoutDate[]
  readonly courseId: number | string
}

interface DispatchProps {
  readonly addBlackoutDate: typeof actions.addBlackoutDate
  readonly deleteBlackoutDate: typeof actions.deleteBlackoutDate
}

type ComponentProps = PassedProps & StoreProps & DispatchProps

export class BlackoutDates extends React.Component<ComponentProps> {
  /* Callbacks */

  addBlackoutDate = (blackoutDate: BlackoutDate) => {
    this.props.addBlackoutDate({
      ...blackoutDate,
      course_id: this.props.courseId
    })
    this.bubbleChangeUp()
  }

  deleteBlackoutDate = (blackoutDate: BlackoutDate) => {
    if (blackoutDate.id) {
      this.bubbleChangeUp()
      this.props.deleteBlackoutDate(blackoutDate.id)
    }
  }

  bubbleChangeUp = () => {
    if (this.props.onChange) {
      this.props.onChange()
    }
  }

  /* Renderers */

  render() {
    return (
      <div>
        <NewBlackoutDatesForm addBlackoutDate={this.addBlackoutDate} />
        <BlackoutDatesTable
          displayType="course"
          blackoutDates={this.props.blackoutDates}
          deleteBlackoutDate={this.deleteBlackoutDate}
        />
      </div>
    )
  }
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    blackoutDates: getBlackoutDates(state),
    courseId: getCourse(state).id
  }
}

export default connect(mapStateToProps, {
  addBlackoutDate: actions.addBlackoutDate,
  deleteBlackoutDate: actions.deleteBlackoutDate
})(BlackoutDates)
