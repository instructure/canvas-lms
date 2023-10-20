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
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('cyoe_assignment_sidebar_breakdown_graph_bar')

const {string, number, func} = PropTypes

class BreakdownGraph extends React.Component {
  static propTypes = {
    rangeStudents: number.isRequired,
    totalStudents: number.isRequired,
    lowerBound: string.isRequired,
    upperBound: string.isRequired,
    rangeIndex: number.isRequired,
    openSidebar: func.isRequired,
    selectRange: func.isRequired,
  }

  selectRange = e => {
    this.props.openSidebar(e.target)
    this.props.selectRange(this.props.rangeIndex)
  }

  renderInnerBar() {
    const width = Math.min((this.props.rangeStudents / this.props.totalStudents) * 100, 100)
    const progressBarStyle = {width: width + '%'}
    if (width > 0) {
      return <div style={progressBarStyle} className="crs-bar__horizontal-inside-fill" />
    } else {
      return null
    }
  }

  render() {
    const {rangeStudents, totalStudents} = this.props
    return (
      <div className="crs-bar__container">
        <div className="crs-bar__horizontal-outside">
          <div className="crs-bar__horizontal-inside" />
          {this.renderInnerBar()}
        </div>
        <div className="crs-bar__bottom">
          <span className="crs-bar__info">
            {I18n.t('%{lowerBound}+ to %{upperBound}', {
              upperBound: this.props.upperBound,
              lowerBound: this.props.lowerBound,
            })}
          </span>
          {/* TODO: use InstUI button */}
          <button
            type="button"
            className="crs-link-button"
            onClick={this.selectRange}
            title={I18n.t('View range student details')}
          >
            {I18n.t('%{rangeStudents} out of %{totalStudents} students', {
              rangeStudents,
              totalStudents,
            })}
          </button>
        </div>
      </div>
    )
  }
}

export default BreakdownGraph
