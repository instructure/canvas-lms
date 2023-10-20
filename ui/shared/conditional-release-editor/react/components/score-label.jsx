/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {transformScore} from '../score-helpers'

const {string, object, bool} = PropTypes

// eslint-disable-next-line react/prefer-stateless-function
export default class ScoreLabel extends React.Component {
  static get propTypes() {
    return {
      score: string,
      label: string,
      isUpperBound: bool,
      triggerAssignment: object,
    }
  }

  render() {
    return (
      <div className="cr-score-label">
        <ScreenReaderContent>{this.props.label}</ScreenReaderContent>
        <span title={this.props.label}>
          {transformScore(this.props.score, this.props.triggerAssignment, this.props.isUpperBound)}
        </span>
      </div>
    )
  }
}
