/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import { object, func, number } from 'prop-types'
import classNames from 'classnames'
import I18n from 'i18n!cyoe_assignment_sidebar'


export default class StudentRangeItem extends React.Component {
    static propTypes = {
      student: object.isRequired,
      studentIndex: number.isRequired,
      selectStudent: func.isRequired,
    }

    selectStudent = () => {
      this.props.selectStudent(this.props.studentIndex)
    }

    render () {
      const avatar = this.props.student.user.avatar_image_url || '/images/messages/avatar-50.png' // default
      const { trend } = this.props.student

      const trendClasses = classNames({
        'crs-student__trend-icon': true,
        'crs-student__trend-icon__positive': trend === 1,
        'crs-student__trend-icon__neutral': trend === 0,
        'crs-student__trend-icon__negative': trend === -1,
      })

      const showTrend = trend !== null && trend !== undefined

      return (
        <div className='crs-student-range__item'>
          <img src={avatar} className='crs-student__avatar' onClick={this.selectStudent}/>
          <button
            className='crs-student__name crs-link-button'
            onClick={this.selectStudent}
            aria-label={I18n.t('Select student %{name}', { name: this.props.student.user.name })}
          >
          {this.props.student.user.name}
          </button>
          {showTrend && (<span className={trendClasses}></span>)}
        </div>
      )
    }
  }
