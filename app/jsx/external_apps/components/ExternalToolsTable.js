/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import _ from 'underscore'
import I18n from 'i18n!external_tools'
import React from 'react'
import PropTypes from 'prop-types'
import store from 'jsx/external_apps/lib/ExternalAppsStore'
import ExternalToolsTableRow from 'jsx/external_apps/components/ExternalToolsTableRow'
import InfiniteScroll from 'jsx/external_apps/components/InfiniteScroll'

export default React.createClass({
    displayName: 'ExternalToolsTable',

    propTypes: {
      canAddEdit: PropTypes.bool.isRequired
    },

    getInitialState() {
      return store.getState();
    },

    onChange() {
      this.setState(store.getState());
    },

    componentDidMount() {
      store.addChangeListener(this.onChange);
      store.fetch();
    },

    componentWillUnmount() {
      store.removeChangeListener(this.onChange);
    },

    loadMore(page) {
      if (store.getState().hasMore && !store.getState().isLoading) {
        store.fetch();
      }
    },

    loader() {
      return <div className="loadingIndicator"></div>;
    },

    trs() {
      if (store.getState().externalTools.length == 0) {
        return null;
      }
      return store.getState().externalTools.map(function (tool, idx) {
        return <ExternalToolsTableRow key={idx} tool={tool} canAddEdit={this.props.canAddEdit}/>
      }.bind(this));
    },

    render() {
      return (
        <div className="ExternalToolsTable">
          <InfiniteScroll pageStart={0} loadMore={this.loadMore} hasMore={store.getState().hasMore} loader={this.loader()}>
            <table className="table table-striped" role="presentation" id="external-tools-table">
              <caption className="screenreader-only">{I18n.t('External Apps')}</caption>
              <thead>
                <tr>
                  <th scope="col" width="5%">&nbsp;</th>
                  <th scope="col" width="65%">{I18n.t('Name')}</th>
                  <th scope="col" width="30%">&nbsp;</th>
                </tr>
              </thead>
              <tbody className="collectionViewItems">
                {this.trs()}
              </tbody>
            </table>
          </InfiniteScroll>
        </div>
      );
    }
  });
