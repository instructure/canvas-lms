/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import _ from 'underscore'
import ProgressStore from './stores/ProgressStore'
import ProgressBar from './ProgressBar'

class ApiProgressBar extends React.Component {
  static displayName = 'ProgressBar'

  static propTypes = {
    progress_id: PropTypes.string,
    onComplete: PropTypes.func,
    delay: PropTypes.number
  }

  //
  // Preparation
  //

  static defaultProps = {
    delay: 1000
  }

  state = {
    completion: 0,
    workflow_state: null
  }

  intervalID = null

  //
  // Lifecycle
  //

  componentDidMount() {
    ProgressStore.addChangeListener(this.handleStoreChange)
    this.intervalID = setInterval(this.poll, this.props.delay)
  }

  componentWillUnmount() {
    ProgressStore.removeChangeListener(this.handleStoreChange)
    if (!_.isNull(this.intervalID)) {
      clearInterval(this.intervalID)
      this.intervalID = null
    }
  }

  shouldComponentUpdate(nextProps, nextState) {
    return (
      this.state.workflow_state != nextState.workflow_state ||
      this.state.completion != nextState.completion ||
      this.props.progress_id != nextProps.progress_id
    )
  }

  componentDidUpdate() {
    if (this.isComplete()) {
      if (!_.isNull(this.intervalID)) {
        clearInterval(this.intervalID)
        this.intervalID = null
      }

      if (!_.isUndefined(this.props.onComplete)) {
        this.props.onComplete()
      }
    }
  }

  //
  // Custom Helpers
  //

  handleStoreChange = () => {
    const progress = ProgressStore.getState()[this.props.progress_id]

    if (_.isObject(progress)) {
      this.setState({
        completion: progress.completion,
        workflow_state: progress.workflow_state
      })
    }
  }

  isComplete = () => _.contains(['completed', 'failed'], this.state.workflow_state)

  isInProgress = () => _.contains(['queued', 'running'], this.state.workflow_state)

  poll = () => {
    if (!_.isUndefined(this.props.progress_id)) {
      ProgressStore.get(this.props.progress_id)
    }
  }

  //
  // Render
  //

  render() {
    if (!this.isInProgress()) {
      return null
    }

    return (
      <div style={{width: '300px'}}>
        <ProgressBar progress={this.state.completion} />
      </div>
    )
  }
}

export default ApiProgressBar
