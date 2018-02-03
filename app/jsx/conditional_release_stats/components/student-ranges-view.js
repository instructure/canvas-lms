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
import TabList, { TabPanel, Tab } from '@instructure/ui-core/lib/components/TabList'
import ApplyTheme from '@instructure/ui-core/lib/components/ApplyTheme'
import classNames from 'classnames'
import I18n from 'i18n!cyoe_assignment_sidebar'
import {transformScore} from '../../shared/conditional_release/score'
import { assignmentShape, studentShape } from '../shapes/index'
import StudentRange from './student-range'

  const { array, func, object } = PropTypes

  const tabsTheme = {
    [Tab.theme]: {
      accordionBackgroundColor: '#f7f7f7',
      accordionBackgroundColorSelected: '#f7f7f7',
      accordionBackgroundColorHover: '#e7e7e7',
      accordionTextColor: '#000000',
      accordionTextColorSelected: '#000000',

      spacingSmall: '10px',
      spacingExtraSmall: '12px',
    },

    [TabPanel.theme]: {
      borderColor: 'transparent',
    },
  }

export default class StudentRangesView extends React.Component {
    static propTypes = {
      assignment: assignmentShape.isRequired,
      ranges: array.isRequired,
      selectedPath: object.isRequired,
      student: studentShape,

      // actions
      selectStudent: func.isRequired,
      selectRange: func.isRequired,
    }

    renderTabs () {
      return this.props.ranges.map((range, i) => {
        const lower = transformScore(range.scoring_range.lower_bound, this.props.assignment, false)
        const upper = transformScore(range.scoring_range.upper_bound, this.props.assignment, true)
        const rangeTitle = `> ${lower} - ${upper}`
        return (
          <TabPanel key={i} title={rangeTitle}>
            <StudentRange
              range={range}
              onStudentSelect={this.props.selectStudent}
             />
          </TabPanel>
        )
      })
    }

    render () {
      const isHidden = !!this.props.student

      const classes = classNames({
        'crs-ranges-view': true,
        'crs-ranges-view__hidden': isHidden,
      })
      return (
        <div className={classes}>
          <header className='crs-ranges-view__header'>
            <h4>{I18n.t('Mastery Paths Breakdown')}</h4>
          </header>
          <ApplyTheme theme={tabsTheme}>
            <TabList variant='accordion' selectedIndex={this.props.selectedPath.range} onChange={this.props.selectRange}>
              {this.renderTabs()}
            </TabList>
          </ApplyTheme>
        </div>
      )
    }
  }
