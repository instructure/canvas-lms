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
import Spinner from '@instructure/ui-core/lib/components/Spinner'
import I18n from 'i18n!cyoe_assignment_sidebar'
import {transformScore} from '../../shared/conditional_release/score'
import BarGraph from './breakdown-graph-bar'
  const { object, array, func, number, bool } = PropTypes

  class BreakdownGraphs extends React.Component {
    static propTypes = {
      assignment: object.isRequired,
      ranges: array.isRequired,
      enrolled: number.isRequired,
      isLoading: bool.isRequired,

      // actions
      openSidebar: func.isRequired,
      selectRange: func.isRequired,
    }

    renderContent () {
      if (this.props.isLoading) {
        return (
          <div className='crs-breakdown-graph__loading'>
            <Spinner title={I18n.t('Loading')} size='small' />
            <p>{I18n.t('Loading Data..')}</p>
          </div>
        )
      } else {
        return this.renderBars()
      }
    }

    renderBars () {
      const { ranges, assignment, enrolled, openSidebar, selectRange } = this.props
      return ranges.map(({ size, scoring_range }, i) => (
        <BarGraph
          key={i}
          rangeIndex={i}
          rangeStudents={size}
          totalStudents={enrolled}
          upperBound={transformScore(scoring_range.upper_bound, assignment, true)}
          lowerBound={transformScore(scoring_range.lower_bound, assignment, false)}
          openSidebar={openSidebar}
          selectRange={selectRange}
        />
      ))
    }

    render () {
      return (
        <div className='crs-breakdown-graph' >
          <h2>{I18n.t('Mastery Paths Breakdown')}</h2>
          {this.renderContent()}
        </div>
      )
    }
  }

export default BreakdownGraphs
