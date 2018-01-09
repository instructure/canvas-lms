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

import React, { Component } from 'react'
import PropTypes from 'prop-types'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import I18n from 'i18n!blueprint_settings'
import select from '../../shared/select'

import Text from '@instructure/ui-core/lib/components/Text'
import Spinner from '@instructure/ui-core/lib/components/Spinner'
import SyncHistoryItem from './SyncHistoryItem'

import actions from '../actions'
import propTypes from '../propTypes'
import LoadStates from '../loadStates'

const { func, bool } = PropTypes

export default class SyncHistory extends Component {
  static propTypes = {
    migrations: propTypes.migrationList,
    loadHistory: func.isRequired,
    isLoadingHistory: bool.isRequired,
    hasLoadedHistory: bool.isRequired,
    associations: propTypes.courseList,
    loadAssociations: func.isRequired,
    isLoadingAssociations: bool.isRequired,
    hasLoadedAssociations: bool.isRequired,
  }

  static defaultProps = {
    migrations: [],
    associations: [],
  }

  constructor (props) {
    super(props)
    this.state = {
      associations: this.mapAssociations(props.associations),
    }
  }

  componentDidMount () {
    if (!this.props.hasLoadedHistory) {
      this.props.loadHistory()
    }
    if (!this.props.hasLoadedAssociations) {
      this.props.loadAssociations()
    }
  }

  componentWillReceiveProps (nextProps) {
    this.setState({
      associations: this.mapAssociations(nextProps.associations),
    })
  }

  mapAssociations (assocs = []) {
    return assocs.reduce((map, asc) => Object.assign(map, { [asc.id]: asc }), {})
  }

  renderLoading () {
    if (this.props.isLoadingHistory || this.props.isLoadingAssociations) {
      const title = I18n.t('Loading Sync History')
      return (
        <div style={{textAlign: 'center'}}>
          <Spinner title={title} />
          <Text as="p">{title}</Text>
        </div>
      )
    }

    return null
  }

  render () {
    // inject course data into exceptions
    const migrations = this.props.migrations.map((mig) => {
      mig.changes.map((change) => {
        change.exceptions.map(ex => Object.assign(ex, this.state.associations[ex.course_id] || {}))
        return change
      })
      return mig
    })

    return (
      <div className="bcs__history">
        {this.renderLoading() || migrations.map(migration =>
          (<SyncHistoryItem key={migration.id} migration={migration} />)
        )}
      </div>
    )
  }
}

const connectState = (state) => {
  const selectedChange = state.selectedChangeLog && state.changeLogs[state.selectedChangeLog]
  const historyState = selectedChange
  ? {
    hasLoadedHistory: LoadStates.hasLoaded(selectedChange.status),
    isLoadingHistory: LoadStates.isLoading(selectedChange.status),
    migrations: selectedChange.data ? [selectedChange.data] : [],
  } : select(state, [
    'hasLoadedHistory',
    'isLoadingHistory',
    'migrations',
  ])

  return Object.assign(select(state, [
    'hasLoadedAssociations',
    'isLoadingAssociations',
    ['existingAssociations', 'associations'],
  ]), historyState)
}
const connectActions = dispatch => bindActionCreators(actions, dispatch)
export const ConnectedSyncHistory = connect(connectState, connectActions)(SyncHistory)
