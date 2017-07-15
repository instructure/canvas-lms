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
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper';

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

const { arrayOf, bool, number, shape, string } = PropTypes;

export class SearchResultsComponent extends Component {
  static propTypes = {
    historyItems: arrayOf(shape({
      created_at: string,
      grade_before: string,
      grade_after: string,
      links: shape({
        grader: number,
        student: number,
        assignment: number,
        graded_anonymously: bool
      })
    })).isRequired,
    label: string.isRequired,
    requestingResults: bool.isRequired,
    users: shape({
      id: number,
      name: string
    }).isRequired
  };

  constructor (props) {
    super(props);

    this.state = {
      formattedHistoryItems: this.formatHistoryItems(props.historyItems)
    };
  }

  componentWillReceiveProps (nextProps) {
    const formattedHistoryItems = this.formatHistoryItems(nextProps.historyItems);
    this.setState({ formattedHistoryItems });
  }

  getNameFromId (id) {
    const user = this.props.users[id];

    return user || I18n.t('Not available');
  }

  formatHistoryItems = (historyItems) => {
    if (!historyItems) {
      return [];
    }

    return historyItems.map((item) => {
      const dateChanged = new Date(item.created_at);
      return {
        Date: $.dateString(dateChanged, { format: 'medium', timezone: ENV.TIMEZONE }),
        Time: $.timeString(dateChanged, { format: 'medium', timezone: ENV.TIMEZONE }),
        From: GradeFormatHelper.formatGrade(item.grade_before, {defaultValue: '-'}),
        To: GradeFormatHelper.formatGrade(item.grade_after, {defaultValue: '-'}),
        Grader: this.getNameFromId(item.links.grader),
        Student: this.getNameFromId(item.links.student),
        Assignment: item.links.assignment,
        Anonymous: item.graded_anonymously ? I18n.t('yes') : I18n.t('no')
      };
    });
  }

  results = () => {
    if (this.state.formattedHistoryItems.length === 0) {
      return null;
    }

    return (
      <Table
        label={this.props.label}
        caption={this.props.label}
        colHeaders={colHeaders}
        tableData={this.state.formattedHistoryItems}
      />
    );
  }

  spinnerAnimation = () => {
    if (!this.props.requestingResults) {
      return null;
    }

    return (
      <Spinner title={I18n.t('Loading Results Spinner')} />
    );
  }

  render () {
    return (
      <div>
        {this.results()}
        {this.spinnerAnimation()}
      </div>
    );
  }
}

const mapStateToProps = state => (
  {
    historyItems: state.history.items || [],
    requestingResults: state.history.loading || false,
    users: state.users.users || {}
  }
);

export default connect(mapStateToProps)(SearchResultsComponent);
