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

import React, { Component } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import $ from 'jquery';
import 'jquery.instructure_date_and_time'
import I18n from 'i18n!gradebook_history';
import Spinner from 'instructure-ui/lib/components/Spinner';
import Table from 'instructure-ui/lib/components/Table';
import Typography from 'instructure-ui/lib/components/Typography';
import constants from 'jsx/gradebook-history/constants';
import SearchResultsRow from 'jsx/gradebook-history/SearchResultsRow';

const { arrayOf, bool, number, shape, string } = PropTypes;

class SearchResultsComponent extends Component {
  static propTypes = {
    fetchHistoryStatus: string.isRequired,
    caption: string.isRequired,
    historyItems: arrayOf(shape({
      anonymous: string.isRequired,
      assignment: number.isRequired,
      date: string.isRequired,
      from: string.isRequired,
      grader: string.isRequired,
      student: string.isRequired,
      time: string.isRequired,
      to: string.isRequired
    })).isRequired,
    requestingResults: bool.isRequired
  };

  hasHistory () {
    return this.props.historyItems.length > 0;
  }

  noResultsFound () {
    return this.props.fetchHistoryStatus === 'success' && !this.hasHistory();
  }

  showResults = () => {
    if (this.noResultsFound()) {
      return (<Typography fontStyle="italic">{I18n.t('No results found')}</Typography>);
    }

    if (!this.hasHistory()) {
      return null;
    }

    return (
      <Table
        caption={this.props.caption}
        colHeaders={constants.colHeaders}
        striped="rows"
      >
        <tbody>
          {this.props.historyItems.map(item => (
            <SearchResultsRow
              key={`history-items-${item.id}`}
              item={item}
            />
          ))}
        </tbody>
      </Table>
    );
  }

  showSpinner = () => {
    if (!this.props.requestingResults) {
      return null;
    }

    return (
      <Spinner title="Loading Results Spinner" />
    );
  }

  render () {
    return (
      <div>
        {this.showResults()}
        {this.showSpinner()}
      </div>
    );
  }
}

const mapStateToProps = state => (
  {
    fetchHistoryStatus: state.history.fetchHistoryStatus || '',
    historyItems: state.history.items || [],
    requestingResults: state.history.loading || false,
  }
);

export default connect(mapStateToProps)(SearchResultsComponent);

export { SearchResultsComponent };
