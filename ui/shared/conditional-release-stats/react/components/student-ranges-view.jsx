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
import PropTypes from 'prop-types'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'
import {IconMiniArrowDownSolid, IconMiniArrowEndSolid} from '@instructure/ui-icons'
import classNames from 'classnames'
import {useScope as useI18nScope} from '@canvas/i18n'
import {transformScore} from '@canvas/conditional-release-score'
import {assignmentShape, studentShape} from '../shapes/index'
import StudentRange from './student-range'

const I18n = useI18nScope('cyoe_assignment_sidebar_student_ranges_view')

const {array, func, object} = PropTypes

export default class StudentRangesView extends React.Component {
  static propTypes = {
    assignment: assignmentShape.isRequired,
    ranges: array.isRequired,
    selectedPath: object.isRequired,
    student: studentShape,

    // actions
    selectStudent: func.isRequired,
  }

  constructor(props) {
    super()
    this.state = {selectedRange: props.selectedPath.range}
  }

  handleToggle = i => {
    this.setState({selectedRange: i})
  }

  renderTabs() {
    return this.props.ranges.map((range, i) => {
      const expanded = this.state.selectedRange === i
      const lower = transformScore(range.scoring_range.lower_bound, this.props.assignment, false)
      const upper = transformScore(range.scoring_range.upper_bound, this.props.assignment, true)
      const rangeTitle = `> ${lower} - ${upper}`
      return (
        <View as="div" padding="xxx-small">
          <ToggleDetails
            variant="filled"
            // eslint-disable-next-line react/no-array-index-key
            key={i}
            expanded={expanded}
            summary={rangeTitle}
            onToggle={() => this.handleToggle(i)}
            size="large"
            iconExpanded={IconMiniArrowDownSolid}
            icon={IconMiniArrowEndSolid}
          >
            <StudentRange range={range} onStudentSelect={this.props.selectStudent} />
          </ToggleDetails>
        </View>
      )
    })
  }

  render() {
    const isHidden = !!this.props.student

    const classes = classNames({
      'crs-ranges-view': true,
      'crs-ranges-view__hidden': isHidden,
    })
    return (
      <div className={classes}>
        <header className="crs-ranges-view__header">
          <h4>{I18n.t('Mastery Paths Breakdown')}</h4>
        </header>
        {this.renderTabs()}
      </div>
    )
  }
}
