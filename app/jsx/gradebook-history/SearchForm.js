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
import { arrayOf, func, shape, string } from 'prop-types';
import I18n from 'i18n!gradebook_history';
import moment from 'moment';
import Autocomplete from 'instructure-ui/lib/components/Autocomplete';
import Button from 'instructure-ui/lib/components/Button';
import DateInput from 'instructure-ui/lib/components/DateInput';
import FormFieldGroup from 'instructure-ui/lib/components/FormFieldGroup';
import Spinner from 'instructure-ui/lib/components/Spinner';
import TextInput from 'instructure-ui/lib/components/TextInput';
import SearchFormActions from 'jsx/gradebook-history/actions/SearchFormActions';
import { showFlashAlert } from 'jsx/shared/FlashAlert';

class SearchFormComponent extends Component {
  static propTypes = {
    fetchHistoryStatus: string.isRequired,
    byAssignment: func.isRequired,
    byGrader: func.isRequired,
    byStudent: func.isRequired,
    fetchGradersStatus: string.isRequired,
    fetchStudentsStatus: string.isRequired,
    getNameOptions: func.isRequired,
    getNameOptionsNextPage: func.isRequired,
    graderOptions: arrayOf(shape({
      name: string.isRequired
    })).isRequired,
    studentOptions: arrayOf(shape({
      name: string.isRequired
    })).isRequired
  };

  constructor (props) {
    super(props);

    this.state = {
      grader: '',
      student: '',
      assignment: '',
      from: '',
      to: '',
      graderOptions: props.graderOptions,
      studentOptions: props.studentOptions,
      emptyOptions: {
        graders: I18n.t('Type a few letters to start searching'),
        students: I18n.t('Type a few letters to start searching')
      }
    }
  }

  componentWillReceiveProps ({
    fetchGradersStatus,
    fetchHistoryStatus,
    fetchStudentsStatus,
    graderOptions,
    studentOptions,
    graderOptionsNextPage,
    studentOptionsNextPage
  }) {
    if (this.props.fetchHistoryStatus === 'started' && fetchHistoryStatus === 'failure') {
      showFlashAlert({ message: I18n.t('Error loading grade history. Try again?') });
    }

    if (fetchGradersStatus === 'success' && graderOptions.length === 0) {
      this.setState(prevState => ({
        emptyOptions: {
          ...prevState.emptyOptions,
          graders: I18n.t('No graders with that name found')
        }
      }));
    }

    if (fetchStudentsStatus === 'success' && studentOptions.length === 0) {
      this.setState(prevState => ({
        emptyOptions: {
          ...prevState.emptyOptions,
          students: I18n.t('No students with that name found')
        }
      }));
    }

    this.setState({
      graderOptions,
      studentOptions
    });

    if (studentOptionsNextPage) {
      this.props.getNameOptionsNextPage('students', studentOptionsNextPage);
    }

    if (graderOptionsNextPage) {
      this.props.getNameOptionsNextPage('graders', graderOptionsNextPage);
    }
  }

  get hasValidTimeFrame () {
    const from = moment(this.state.from);
    const to = moment(this.state.to);

    return to.diff(from, 'days') >= 0 || !this.state.from || !this.state.to;
  }

  get timeFrame () {
    if (this.hasValidTimeFrame) {
      const from = this.state.from ? moment(this.state.from).startOf('day').format() : '';
      const to = this.state.to ? moment(this.state.to).endOf('day').format() : '';

      return { from, to };
    }

    return { from: '', to: '' };
  }

  handleUserEntry = (event) => {
    const target = event.target.id;
    const searchTerm = event.target.value;

    if (searchTerm.length === 0) {
      this.setState({
        graderOptions: [],
        studentOptions: []
      });
      return;
    }
    if (searchTerm.length <= 2) {
      this.setState(prevState => ({
        emptyOptions: {
          ...prevState.emptyOptions,
          [target]: I18n.t('Type a few letters to start searching')
        }
      }));
      return;
    }
    this.props.getNameOptions(target, searchTerm);
  }

  handleTextEntry = (event) => {
    this.setState({ [event.target.id]: event.target.value });
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

  setSelectedFrom = (from) => {
    this.setState({ from });
  }

  setSelectedTo = (to) => {
    this.setState({ to });
  }

  setSelectedGrader = (event, selected) => {
    const grader = selected ? selected.id : '';
    this.setState({ grader });
  }

  setSelectedStudent = (event, selected) => {
    const student = selected ? selected.id : '';
    this.setState({ student });
  }

  renderAsOptions = data => (
    data.map(item => (
      <option key={item.id} value={item.id}>{item.name}</option>
    ))
  )

  filterNone = options => (
    // empty function here as the default filter function for Autocomplete
    // does a startsWith call, and won't match `nora` -> `Elenora` for example
    options
  )

  render () {
    return (
      <FormFieldGroup description={I18n.t('Search Form')} label={I18n.t('Search Form')} rowSpacing="small">
        <Autocomplete
          id="graders"
          allowEmpty
          emptyOption={this.state.emptyOptions.graders}
          filter={this.filterNone}
          label={I18n.t('Grader')}
          loading={this.props.fetchGradersStatus === 'started'}
          loadingOption={<Spinner size="small" title={I18n.t('Loading Graders')} />}
          onChange={this.setSelectedGrader}
          onInputChange={this.handleUserEntry}
        >
          {this.renderAsOptions(this.state.graderOptions)}
        </Autocomplete>
        <Autocomplete
          id="students"
          allowEmpty
          emptyOption={this.state.emptyOptions.students}
          filter={this.filterNone}
          label={I18n.t('Student')}
          loading={this.props.fetchStudentsStatus === 'started'}
          loadingOption={<Spinner size="small" title={I18n.t('Loading Students')} />}
          onChange={this.setSelectedStudent}
          onInputChange={this.handleUserEntry}
        >
          {this.renderAsOptions(this.state.studentOptions)}
        </Autocomplete>
        <TextInput id="assignment" label={I18n.t('Assignment')} onChange={this.handleTextEntry} />
        <DateInput
          label={I18n.t('From')}
          previousLabel={I18n.t('Previous Month')}
          nextLabel={I18n.t('Next Month')}
          onDateChange={this.setSelectedFrom}
        />
        <DateInput
          label={I18n.t('To')}
          previousLabel={I18n.t('Previous Month')}
          nextLabel={I18n.t('Next Month')}
          onDateChange={this.setSelectedTo}
        />
        <Button
          onClick={this.handleSubmit}
          type="submit"
        >
          {I18n.t('Find')}
        </Button>
      </FormFieldGroup>
    );
  }
}

const mapStateToProps = state => (
  {
    fetchHistoryStatus: state.history.fetchHistoryStatus || '',
    fetchGradersStatus: state.searchForm.options.graders.fetchStatus || '',
    fetchStudentsStatus: state.searchForm.options.students.fetchStatus || '',
    graderOptions: state.searchForm.options.graders.items || [],
    studentOptions: state.searchForm.options.students.items || [],
    graderOptionsNextPage: state.searchForm.options.graders.nextPage || '',
    studentOptionsNextPage: state.searchForm.options.students.nextPage || ''
  }
);

const mapDispatchToProps = dispatch => (
  {
    byAssignment: (assignmentId, timeFrame) => {
      dispatch(SearchFormActions.getHistoryByAssignment(assignmentId, timeFrame));
    },
    byGrader: (graderId, timeFrame) => {
      dispatch(SearchFormActions.getHistoryByGrader(graderId, timeFrame));
    },
    byStudent: (studentId, timeFrame) => {
      dispatch(SearchFormActions.getHistoryByStudent(studentId, timeFrame));
    },
    getNameOptions: (userType, searchTerm) => {
      dispatch(SearchFormActions.getNameOptions(userType, searchTerm));
    },
    getNameOptionsNextPage: (userType, url) => {
      dispatch(SearchFormActions.getNameOptionsNextPage(userType, url));
    }
  }
);

export default connect(mapStateToProps, mapDispatchToProps)(SearchFormComponent);

export { SearchFormComponent };
