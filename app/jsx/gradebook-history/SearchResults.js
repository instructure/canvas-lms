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
import { arrayOf, bool, func, shape, string } from 'prop-types';
import $ from 'jquery';
import 'jquery.instructure_date_and_time'
import I18n from 'i18n!gradebook_history';
import Spinner from 'instructure-ui/lib/components/Spinner';
import Table from 'instructure-ui/lib/components/Table';
import Typography from 'instructure-ui/lib/components/Typography';
import { getHistoryNextPage } from 'jsx/gradebook-history/actions/SearchResultsActions';
import SearchResultsRow from 'jsx/gradebook-history/SearchResultsRow';

const colHeaders = [
  I18n.t('Date'),
  I18n.t('Time'),
  I18n.t('From'),
  I18n.t('To'),
  I18n.t('Grader'),
  I18n.t('Student'),
  I18n.t('Assignment'),
  I18n.t('Anonymous')
];

const nearPageBottom = () => (
  document.body.clientHeight - (window.innerHeight + window.scrollY) < 100
);

class SearchResultsComponent extends Component {
  static propTypes = {
    getNextPage: func.isRequired,
    fetchHistoryStatus: string.isRequired,
    caption: string.isRequired,
    historyItems: arrayOf(shape({
      anonymous: string.isRequired,
      assignment: string.isRequired,
      date: string.isRequired,
      from: string.isRequired,
      grader: string.isRequired,
      student: string.isRequired,
      time: string.isRequired,
      to: string.isRequired
    })).isRequired,
    nextPage: string.isRequired,
    requestingResults: bool.isRequired
  };

  componentDidMount () {
    document.addEventListener('scroll', this.handleScroll);
  }

  componentDidUpdate (prevProps) {
    // if the page doesn't have a scrollbar, scroll event listener can't be triggered
    if (document.body.clientHeight <= window.innerHeight) {
      this.getNextPage();
    }

    if (prevProps.historyItems.length < this.props.historyItems.length) {
      $.screenReaderFlashMessage(I18n.t('More results were added at the bottom of the page.'));
    }
  }

  getNextPage = () => {
    if (!this.props.requestingResults && this.props.nextPage) {
      this.props.getNextPage(this.props.nextPage);
    }
  }

  handleScroll = () => {
    if (nearPageBottom()) {
      this.getNextPage();
    }
  }

  hasHistory () {
    return this.props.historyItems.length > 0;
  }

  noResultsFound () {
    return this.props.fetchHistoryStatus === 'success' && !this.hasHistory();
  }

  showAtEnd () {
    if (this.props.requestingResults || this.props.nextPage || !this.hasHistory()) {
      return null;
    }

    return (<Typography fontStyle="italic">{I18n.t('No more results to load.')}</Typography>);
  }

  showResults = () => {
    if (this.noResultsFound()) {
      return (<Typography fontStyle="italic">{I18n.t('No results found.')}</Typography>);
    }

    if (!this.hasHistory()) {
      return null;
    }

    return (
      <div>
        <Table
          caption={this.props.caption}
          striped="rows"
        >
          <thead>
            <tr>
              {colHeaders.map(header => (
                <th scope="col" key={`${header}-column`}>{ header }</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {this.props.historyItems.map(item => (
              <SearchResultsRow
                key={`history-items-${item.id}`}
                item={item}
              />
            ))}
          </tbody>
        </Table>
        {this.showAtEnd()}
      </div>
    );
  }

  showSpinner = () => {
    if (!this.props.requestingResults) {
      return null;
    }

    $.screenReaderFlashMessage(I18n.t('Loading more grade history results.'));

    return (
      <Spinner title={I18n.t('Loading Results')} />
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
    nextPage: state.history.nextPage || '',
    requestingResults: state.history.loading || false,
  }
);

const mapDispatchToProps = dispatch => (
  {
    getNextPage: (url) => {
      dispatch(getHistoryNextPage(url));
    }
  }
);

export default connect(mapStateToProps, mapDispatchToProps)(SearchResultsComponent);

export { SearchResultsComponent };
