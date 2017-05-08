import React, { Component } from 'react'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import I18n from 'i18n!blueprint_settings'
import select from 'jsx/shared/select'

import Typography from 'instructure-ui/lib/components/Typography'
import Spinner from 'instructure-ui/lib/components/Spinner'
import SyncHistoryItem from './SyncHistoryItem'

import actions from '../actions'
import propTypes from '../propTypes'

const { func, bool } = React.PropTypes

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
          <Typography as="p">{title}</Typography>
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

const connectState = state =>
  select(state, [
    'hasLoadedHistory',
    'isLoadingHistory',
    'hasLoadedAssociations',
    'isLoadingAssociations',
    'migrations',
    ['existingAssociations', 'associations'],
  ])
const connectActions = dispatch => bindActionCreators(actions, dispatch)
export const ConnectedSyncHistory = connect(connectState, connectActions)(SyncHistory)
