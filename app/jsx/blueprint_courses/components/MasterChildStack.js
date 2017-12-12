/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import I18n from 'i18n!blueprint_courses'
import React, { Component } from 'react'
import cx from 'classnames'

import Text from '@instructure/ui-core/lib/components/Text'

import propTypes from '../propTypes'

export default class MasterChildStack extends Component {
  static propTypes = {
    terms: propTypes.termList.isRequired,
    child: propTypes.courseInfo.isRequired,
    master: propTypes.courseInfo.isRequired,
  }

  renderBox (course, isMaster) {
    const term = this.props.terms.find(t => t.id === course.enrollment_term_id)
    const termName = term ? term.name : ''
    const classes = cx('bcc__master-child-stack__box',
      { 'bcc__master-child-stack__box__master': isMaster })

    return (
      <div className={classes}>
        <header>
          <Text as="p" size="small">{isMaster ? I18n.t('Blueprint') : I18n.t('Your Course')}</Text>
        </header>
        <Text as="p">{termName} - {course.name}</Text>
        <div className="bcc__master-child-stack__box__footer">
          <Text size="small" color={isMaster ? 'secondary-inverse' : 'secondary'}>{course.sis_course_id}</Text>
          <Text size="small" color={isMaster ? 'secondary-inverse' : 'secondary'}>courses/{course.id}</Text>
        </div>
      </div>
    )
  }

  render () {
    return (
      <div className="bcc__master-child-stack">
        {this.renderBox(this.props.master, true)}
        {this.renderBox(this.props.child, false)}
      </div>
    )
  }
}
