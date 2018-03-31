/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import Button from '@instructure/ui-core/lib/components/Button'
import Spinner from '@instructure/ui-core/lib/components/Spinner'
import I18n from 'i18n!react_developer_keys'
import React from 'react'
import PropTypes from 'prop-types'
import DeveloperKeysTable from './DeveloperKeysTable'
import DeveloperKey from './DeveloperKey'

class DeveloperKeysApp extends React.Component {
  constructor (props) {
    super(props);
    this.showMoreButtonHandler = this.showMoreButtonHandler.bind(this)
  }

  getSpinner () {
    return this.isLoading() ? (<Spinner title={I18n.t('Loading')} />) : null
  }

  showKeys (list) {
    if (list.length === 0) { return null }
    return (
      <DeveloperKeysTable
        ref={(table) => { this.DeveloperKeysTable = table; }}
        store={this.props.store}
        actions={this.props.actions}
        developerKeysList={this.props.applicationState.listDeveloperKeys.list} /> )
  }

  nextPage () {
    return this.props.applicationState.listDeveloperKeys.nextPage
  }

  showMoreButtonHandler (_event) {
    this.DeveloperKeysTable.focusLastDeveloperKey()
    this.props.store.dispatch(this.props.actions.getRemainingDeveloperKeys(this.nextPage(), []))
  }

  showMoreButton () {
    if (this.nextPage() && !this.isLoading()) {
      const showAll = I18n.t("Show All %{developerKeysCount} Keys", {developerKeysCount: this.props.env.developer_keys_count})

      return (
        <Button type="button" onClick={this.showMoreButtonHandler}>
          {showAll}
        </Button>)
    }

    return null
  }

  isLoading () {
    return this.props.applicationState.listDeveloperKeys.listDeveloperKeysPending
  }

  render () {
    const { list } = this.props.applicationState.listDeveloperKeys;
    return (
      <div>
        {this.showKeys(list)}
        <div id="loading">
          {this.getSpinner()}
          {this.showMoreButton()}
        </div>
      </div>
    );
  }
};

DeveloperKeysApp.propTypes = {
  env: PropTypes.shape({
    developer_keys_count: PropTypes.number
  }).isRequired,
  store: PropTypes.shape({
    dispatch: PropTypes.func.isRequired,
  }).isRequired,
  actions: PropTypes.shape({
    getRemainingDeveloperKeys: PropTypes.func.isRequired,
  }).isRequired,
  applicationState: PropTypes.shape({
    listDeveloperKeys: PropTypes.shape({
      nextPage: PropTypes.string,
      listDeveloperKeysPending: PropTypes.bool.isRequired,
      listDeveloperKeysSuccessful: PropTypes.bool.isRequired,
      list: PropTypes.arrayOf(DeveloperKey.propTypes.developerKey).isRequired,
    }).isRequired
  }).isRequired
};

export default DeveloperKeysApp
