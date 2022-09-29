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

import React from 'react'
import PropTypes from 'prop-types'
import GradingStandardCollection from '@canvas/grading-standard-collection'
import GradingPeriodCollection from './gradingPeriodCollection'
import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import 'jqueryui/tabs'

const I18n = useI18nScope('gradingCourseTabContainer')

class CourseTabContainer extends React.Component {
  static propTypes = {
    hasGradingPeriods: PropTypes.bool.isRequired,
  }

  componentDidMount() {
    if (!this.props.hasGradingPeriods) return
    $(this.tabContainer).children('.ui-tabs-minimal').tabs()
  }

  renderSetsAndStandards() {
    return (
      <div
        ref={el => {
          this.tabContainer = el
        }}
      >
        <h1>{I18n.t('Grading')}</h1>
        <div className="ui-tabs-minimal">
          <ul>
            <li>
              <a href="#grading-periods-tab" className="grading_periods_tab">
                {' '}
                {I18n.t('Grading Periods')}
              </a>
            </li>
            <li>
              <a href="#grading-standards-tab" className="grading_standards_tab">
                {' '}
                {I18n.t('Grading Schemes')}
              </a>
            </li>
          </ul>
          <div
            ref={el => {
              this.gradingPeriods = el
            }}
            id="grading-periods-tab"
          >
            <GradingPeriodCollection />
          </div>
          <div
            ref={el => {
              this.gradingStandards = el
            }}
            id="grading-standards-tab"
          >
            <GradingStandardCollection />
          </div>
        </div>
      </div>
    )
  }

  renderStandards() {
    return (
      <div
        ref={el => {
          this.gradingStandards = el
        }}
      >
        <h1>{I18n.t('Grading Schemes')}</h1>
        <GradingStandardCollection />
      </div>
    )
  }

  render() {
    if (this.props.hasGradingPeriods) {
      return this.renderSetsAndStandards()
    }
    return this.renderStandards()
  }
}

export default CourseTabContainer
