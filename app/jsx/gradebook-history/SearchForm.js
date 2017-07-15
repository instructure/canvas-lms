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
import I18n from 'i18n!gradebook_history';
import moment from 'moment';
import Button from 'instructure-ui/lib/components/Button';
import DateInput from 'instructure-ui/lib/components/DateInput';
import FormFieldGroup from 'instructure-ui/lib/components/FormFieldGroup';
import TextInput from 'instructure-ui/lib/components/TextInput';
import SearchActions from 'jsx/gradebook-history/actions/SearchActions';
import { showFlashAlert } from 'jsx/shared/FlashAlert';

const { func, string } = PropTypes;

export class SearchFormComponent extends Component {
  static propTypes = {
    fetchHistoryStatus: string.isRequired,
    byAssignment: func.isRequired,
    byGrader: func.isRequired,
    byStudent: func.isRequired
  };

  constructor (props) {
    super(props);

    this.state = {
      grader: '',
      student: '',
      assignment: '',
      from: '',
      to: '',
    };
  }

  componentWillReceiveProps (nextProps) {
    if (this.props.fetchHistoryStatus === 'started' && nextProps.fetchHistoryStatus === 'failure') {
      showFlashAlert({message: I18n.t('Error loading grade history. Try again?')});
    }
  }

  get hasValidTimeFrame () {
    const from = moment(this.state.from);
    const to = moment(this.state.to);

    return to.diff(from, 'days') >= 0 || this.state.from === '' || this.state.to === '';
  }

  get timeFrame () {
    if (this.hasValidTimeFrame) {
      const from = this.state.from ? moment(this.state.from).startOf('day').format() : '';
      const to = this.state.to ? moment(this.state.to).endOf('day').format() : '';

      return { from, to };
    }

    return { from: '', to: '' };
  }

  handleTextEntry = (event) => {
    this.setState({ [event.target.id]: event.target.value });
  }

  handleFromEntry = (from) => {
    this.setState({ from });
  }

  handleToEntry = (to) => {
    this.setState({ to });
  }

  handleSubmit = () => {
    if (!this.hasValidTimeFrame) {
      return;
    }

    if (this.state.assignment !== '') {
      this.props.byAssignment(this.state.assignment, this.timeFrame);
    } else if (this.state.grader !== '') {
      this.props.byGrader(this.state.grader, this.timeFrame);
    } else if (this.state.student !== '') {
      this.props.byStudent(this.state.student, this.timeFrame);
    }
  }

  render () {
    return (
      <FormFieldGroup description={I18n.t('Search Form')} label={I18n.t('Search Form')} rowSpacing="small">
        <TextInput id="grader" label={I18n.t('Grader')} onChange={this.handleTextEntry} />
        <TextInput id="student" label={I18n.t('Student')} onChange={this.handleTextEntry} />
        <TextInput id="assignment" label={I18n.t('Assignment')} onChange={this.handleTextEntry} />
        <DateInput
          label={I18n.t('From')}
          previousLabel={I18n.t('Previous Month')}
          nextLabel={I18n.t('Next Month')}
          onDateChange={this.handleFromEntry}
        />
        <DateInput
          label={I18n.t('To')}
          previousLabel={I18n.t('Previous Month')}
          nextLabel={I18n.t('Next Month')}
          onDateChange={this.handleToEntry}
        />
        <Button type="submit" onClick={this.handleSubmit}>{I18n.t('Find')}</Button>
      </FormFieldGroup>
    );
  }
}

const mapStateToProps = state => (
  {
    fetchHistoryStatus: state.history.fetchHistoryStatus || 'success'
  }
);

const mapDispatchToProps = dispatch => (
  {
    byAssignment: (assignmentId, timeFrame) => {
      dispatch(SearchActions.getHistoryByAssignment(assignmentId, timeFrame));
    },
    byGrader: (graderId, timeFrame) => {
      dispatch(SearchActions.getHistoryByGrader(graderId, timeFrame));
    },
    byStudent: (studentId, timeFrame) => {
      dispatch(SearchActions.getHistoryByStudent(studentId, timeFrame));
    }
  }
);

export default connect(mapStateToProps, mapDispatchToProps)(SearchFormComponent);
