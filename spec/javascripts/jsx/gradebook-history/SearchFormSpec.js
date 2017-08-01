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

import React from 'react';
import { mount, shallow } from 'enzyme';
import moment from 'moment';
import environment from 'jsx/gradebook-history/environment';
import GradebookHistoryStore from 'jsx/gradebook-history/store/GradebookHistoryStore';
import { SearchFormComponent } from 'jsx/gradebook-history/SearchForm';
import SearchFormActions from 'jsx/gradebook-history/actions/SearchFormActions';
import Autocomplete from 'instructure-ui/lib/components/Autocomplete';
import Button from 'instructure-ui/lib/components/Button';
import DateInput from 'instructure-ui/lib/components/DateInput';
import FormFieldGroup from 'instructure-ui/lib/components/FormFieldGroup';
import { destroyContainer } from 'jsx/shared/FlashAlert';
import Fixtures from 'spec/jsx/gradebook-history/Fixtures';

const functionStubHelper = (dispatchStub, functionToDispatch) => (
  (id, timeFrame) => {
    dispatchStub(functionToDispatch(id, timeFrame))
  }
);

const stretchTimeFrame = timeFrame => (
  {
    from: moment(timeFrame.from).startOf('day').format(),
    to: moment(timeFrame.to).endOf('day').format()
  }
);

const defaultProps = () => (
  {
    fetchHistoryStatus: 'started',
    byAssignment () {},
    byDate () {},
    byGrader () {},
    byStudent () {},
    clearSearchOptions () {},
    getSearchOptions () {},
    getSearchOptionsNextPage () {},
    assignments: {
      fetchStatus: 'started',
      items: [],
      nextPage: ''
    },
    graders: {
      fetchStatus: 'started',
      items: [],
      nextPage: ''
    },
    students: {
      fetchStatus: 'started',
      items: [],
      nextPage: ''
    }
  }
);

const mountComponent = (props = {}) => (
  shallow(<SearchFormComponent {...defaultProps()} {...props} />)
);

QUnit.module('SearchForm', {
  setup () {
    this.wrapper = mountComponent();
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('has a form field group', function () {
  ok(this.wrapper.find(FormFieldGroup).exists());
});

test('has an Autocomplete with id #graders', function () {
  const input = this.wrapper.find('#graders');
  equal(input.length, 1);
  ok(input.is(Autocomplete));
});

test('has an Autocomplete with id #students', function () {
  const input = this.wrapper.find('#students');
  equal(input.length, 1);
  ok(input.is(Autocomplete));
});

test('has an Autocomplete with id #assignments', function () {
  const input = this.wrapper.find('#assignments');
  equal(input.length, 1);
  ok(input.is(Autocomplete));
});

test('has DateInputs for from date and to date', function () {
  const inputs = this.wrapper.find(DateInput);
  equal(inputs.length, 2);
  ok(inputs.every(DateInput));
});

test('has a Button for submitting', function () {
  ok(this.wrapper.find(Button).exists());
});

QUnit.module('SearchForm when button is clicked', {
  setup () {
    this.getHistoryByAssignmentStub = this.stub(SearchFormActions, 'getHistoryByAssignment');
    this.getHistoryByDateStub = this.stub(SearchFormActions, 'getHistoryByDate');
    this.getHistoryByGraderStub = this.stub(SearchFormActions, 'getHistoryByGrader');
    this.getHistoryByStudentStub = this.stub(SearchFormActions, 'getHistoryByStudent');
    this.dispatchStub = this.stub(GradebookHistoryStore, 'dispatch');

    const props = {
      fetchHistoryStatus: 'success',
      byAssignment: functionStubHelper(this.dispatchStub, this.getHistoryByAssignmentStub),
      byDate: functionStubHelper(this.dispatchStub, this.getHistoryByDateStub),
      byGrader: functionStubHelper(this.dispatchStub, this.getHistoryByGraderStub),
      byStudent: functionStubHelper(this.dispatchStub, this.getHistoryByStudentStub)
    };

    this.wrapper = mountComponent(props);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('does nothing when all fields are blank', function () {
  const emptyState = {
    selected: {
      assignment: '',
      grader: '',
      student: '',
      from: '',
      to: ''
    }
  };
  this.wrapper.setState({ emptyState }, () => {
    this.wrapper.find(Button).simulate('click');
    equal(this.dispatchStub.callCount, 0);
  });
});

test('dispatches when assignment not empty', function () {
  this.wrapper.setState({ selected: { assignment: '1' } }, () => {
    this.wrapper.find(Button).simulate('click');
    equal(this.dispatchStub.callCount, 1);
  });
});

test('dispatches when grader not empty', function () {
  this.wrapper.setState({ selected: { grader: '1' } }, () => {
    this.wrapper.find(Button).simulate('click');
    equal(this.dispatchStub.callCount, 1);
  });
});

test('dispatches when student not empty', function () {
  this.wrapper.setState({ selected: { student: '1' } }, () => {
    this.wrapper.find(Button).simulate('click');
    equal(this.dispatchStub.callCount, 1);
  });
});

test('dispatches getHistoryByAssignment with assignment id and timeFrame', function () {
  const assignment = '1010';
  const timeFrame = Fixtures.timeFrame();
  this.wrapper.setState({
    selected: {
      assignment,
      from: timeFrame.from,
      to: timeFrame.to
    }
  }, () => {
    this.wrapper.find(Button).simulate('click');
    equal(this.getHistoryByAssignmentStub.firstCall.args[0], assignment);
    deepEqual(this.getHistoryByAssignmentStub.firstCall.args[1], stretchTimeFrame(timeFrame));
  });
});

test('dispatches getHistoryByGrader with grader id and timeFrame', function () {
  const grader = '1011';
  const timeFrame = Fixtures.timeFrame();
  this.wrapper.setState({
    selected: {
      grader,
      from: timeFrame.from,
      to: timeFrame.to
    }
  }, () => {
    this.wrapper.find(Button).simulate('click');
    equal(this.getHistoryByGraderStub.firstCall.args[0], grader);
    deepEqual(this.getHistoryByGraderStub.firstCall.args[1], stretchTimeFrame(timeFrame));
  });
});

test('dispatches getHistoryByStudent with student id and timeFrame', function () {
  const student = '1100';
  const timeFrame = Fixtures.timeFrame();
  this.wrapper.setState({
    selected: {
      student,
      from: timeFrame.from,
      to: timeFrame.to
    }
  }, () => {
    this.wrapper.find(Button).simulate('click');
    equal(this.getHistoryByStudentStub.firstCall.args[0], student);
    deepEqual(this.getHistoryByStudentStub.firstCall.args[1], stretchTimeFrame(timeFrame));
  });
});

test('dispatches getHistoryByDate with timeFrame', function () {
  const timeFrame = Fixtures.timeFrame();
  this.wrapper.setState({
    selected: {
      from: timeFrame.from,
      to: timeFrame.to
    }
  }, () => {
    this.wrapper.find(Button).simulate('click');
    deepEqual(this.getHistoryByDateStub.firstCall.args[0], stretchTimeFrame(timeFrame));
  });
});

test('does not dispatch when to date is earlier than from date', function () {
  const assignment = '1101';
  const earlyDate = '2017-01-01T00:00:00-00:00';
  const futureDate = '2017-01-02T00:00:00-00:00';
  this.wrapper.setState({
    selected: {
      assignment,
      from: futureDate,
      to: earlyDate
    }
  }, () => {
    this.wrapper.find(Button).simulate('click');
    equal(this.dispatchStub.callCount, 0);
    equal(this.getHistoryByAssignmentStub.callCount, 0);
  });
});

test('dispatches with empty strings if no dates selected', function () {
  const assignment = '1110';
  this.wrapper.setState({ selected: { assignment } }, () => {
    const timeFrame = {
      from: '',
      to: ''
    };
    this.wrapper.find(Button).simulate('click');
    deepEqual(this.getHistoryByAssignmentStub.firstCall.args[1], timeFrame);
  });
});

test('dispatches with empty string and from date if only from date available', function () {
  const assignment = '1101';
  const earlyDate = '2017-01-01T00:00:00-00:00';
  this.wrapper.setState({
    selected: {
      assignment,
      from: earlyDate,
    }
  }, () => {
    const timeFrame = {
      from: moment(earlyDate).startOf('day').format(),
      to: ''
    };
    this.wrapper.find(Button).simulate('click');
    deepEqual(this.getHistoryByAssignmentStub.firstCall.args[1], timeFrame);
  });
});

test('dispatches with empty string and to date if only to date available', function () {
  const assignment = '1101';
  const futureDate = '2017-01-02T00:00:00-00:00';
  this.wrapper.setState({
    selected: {
      assignment,
      to: futureDate,
    }
  }, () => {
    const timeFrame = {
      from: '',
      to: moment(futureDate).endOf('day').format()
    };
    this.wrapper.find(Button).simulate('click');
    deepEqual(this.getHistoryByAssignmentStub.firstCall.args[1], timeFrame);
  });
});

QUnit.module('SearchForm fetchHistoryStatus prop', {
  setup () {
    this.wrapper = mountComponent({ fetchHistoryStatus: 'started' });
  },

  teardown () {
    this.wrapper.unmount();
    destroyContainer();
  }
});

test('turning from started to failure displays an AjaxFlashAlert', function () {
  // the container the alerts get rendered into doesn't exist until ajaxFlashAlert needs it
  // and then it'll create it itself, appending the error message into this new container
  equal(document.getElementById('flash_message_holder'), null);
  this.wrapper.setProps({ fetchHistoryStatus: 'failure' });
  const flashMessageContainer = document.getElementById('flash_message_holder');
  ok(flashMessageContainer.childElementCount > 0);
});

QUnit.module('SearchForm Autocomplete', {
  setup () {
    this.courseId = '341';
    this.stub(environment, 'courseId').returns(this.courseId);
    this.props = {
      ...defaultProps(),
      fetchHistoryStatus: 'started',
      clearSearchOptions: this.stub(),
      getSearchOptions: this.stub(),
      getSearchOptionsNextPage: this.stub(),
    };

    this.wrapper = mount(<SearchFormComponent {...this.props} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('typing more than two letters for assignments hits getSearchOptions prop', function () {
  const input = this.wrapper.find('#assignments');
  input.simulate('change', { target: { id: 'assignments', value: 'Chapter 11 Questions' } });
  strictEqual(this.props.getSearchOptions.callCount, 1);
});

test('typing more than two letters for graders hits getSearchOptions prop', function () {
  const input = this.wrapper.find('#graders');
  input.simulate('change', { target: { id: 'graders', value: 'Norval' } });
  strictEqual(this.props.getSearchOptions.callCount, 1);
});

test('typing more than two letters for students hits getSearchOptions prop if not empty', function () {
  const input = this.wrapper.find('#students');
  input.simulate('change', { target: {id: 'students', value: 'Norval' } });
  strictEqual(this.props.getSearchOptions.callCount, 1);
});

test('typing two or fewer letters for assignments hits clearSearchOptions prop if not empty', function () {
  this.wrapper.setProps({
    assignments: {
      fetchStatus: 'success',
      items: [{ id: '1', name: 'Gary' }],
      nextPage: ''
    }
  });
  const input = this.wrapper.find('#assignments');
  input.simulate('change', { target: { id: 'assignments', value: 'ab' } });
  strictEqual(this.props.clearSearchOptions.callCount, 1);
});

test('typing two or fewer letters for graders hits clearSearchOptions prop', function () {
  this.wrapper.setProps({
    graders: {
      fetchStatus: 'success',
      items: [{ id: '1', name: 'Gary' }],
      nextPage: ''
    }
  });
  const input = this.wrapper.find('#graders');
  input.simulate('change', { target: { id: 'graders', value: 'ab' } });
  strictEqual(this.props.clearSearchOptions.callCount, 1);
});

test('typing two or fewer letters for students hits clearSearchOptions prop if not empty', function () {
  this.wrapper.setProps({
    students: {
      fetchStatus: 'success',
      items: [{ id: '1', name: 'Gary' }],
      nextPage: ''
    }
  });
  const input = this.wrapper.find('#students');
  input.simulate('change', { target: { id: 'students', value: 'ab' } });
  strictEqual(this.props.clearSearchOptions.callCount, 1);
});

test('getSearchOptions is called with search term and input id', function () {
  const input = this.wrapper.find('#graders');
  const inputId = 'graders';
  const searchTerm = 'Norval Abbott';
  input.simulate('change', { target: { id: inputId, value: searchTerm } });
  strictEqual(this.props.getSearchOptions.firstCall.args[0], inputId);
  strictEqual(this.props.getSearchOptions.firstCall.args[1], searchTerm);
});

test('getSearchOptionsNextPage is called if there are more options to load', function () {
  this.wrapper.setProps({
    students: {
      fetchStatus: 'success',
      items: [],
      nextPage: 'https://example.com'
    }
  });
  strictEqual(this.props.getSearchOptionsNextPage.firstCall.args[0], 'students');
  strictEqual(this.props.getSearchOptionsNextPage.firstCall.args[1], 'https://example.com');
});

QUnit.module('SearchForm Autocomplete options', {
  setup () {
    this.props = { ...defaultProps(), clearSearchOptions: this.stub() };
    this.assignments = Fixtures.assignmentArray();
    this.graders = Fixtures.userArray();
    this.students = Fixtures.userArray();
    this.wrapper = mount(<SearchFormComponent {...this.props} />);
  }
});

test('selecting a grader from options sets state to its id', function () {
  this.wrapper.setProps({
    graders: {
      fetchStatus: 'success',
      items: this.graders,
      nextPage: ''
    }
  });

  const input = this.wrapper.find('#graders').node;
  input.click();

  const graderNames = this.graders.map(grader => (grader.name));
  [...document.getElementsByTagName('span')].find(span => graderNames.includes(span.innerHTML)).click();

  strictEqual(this.wrapper.state().selected.grader, this.graders[0].id);
});

test('selecting a student from options sets state to its id', function () {
  this.wrapper.setProps({
    students: {
      fetchStatus: 'success',
      items: this.students,
      nextPage: ''
    }
  });

  const input = this.wrapper.find('#students').node;
  input.click();

  const studentNames = this.students.map(student => (student.name));
  [...document.getElementsByTagName('span')].find(span => studentNames.includes(span.innerHTML)).click();

  strictEqual(this.wrapper.state().selected.student, this.students[0].id);
});

test('selecting an assignment from options sets state to its id', function () {
  this.wrapper.setProps({
    assignments: {
      fetchStatus: 'success',
      items: this.assignments,
      nextPage: ''
    }
  });

  const input = this.wrapper.find('#assignments').node;
  input.click();

  const assignmentNames = this.assignments.map(assignment => (assignment.name));
  [...document.getElementsByTagName('span')].find(span => assignmentNames.includes(span.innerHTML)).click();

  strictEqual(this.wrapper.state().selected.assignment, this.assignments[0].id);
});

test('selecting an assignment from options clears options for assignments', function () {
  this.wrapper.setProps({
    assignments: {
      fetchStatus: 'success',
      items: this.assignments,
      nextPage: ''
    }
  });

  const input = this.wrapper.find('#assignments').node;
  input.click();

  const assignmentNames = this.assignments.map(assignment => (assignment.name));
  [...document.getElementsByTagName('span')].find(span => assignmentNames.includes(span.innerHTML)).click();

  ok(this.props.clearSearchOptions.called);
  strictEqual(this.props.clearSearchOptions.firstCall.args[0], 'assignments');
});

test('selecting a grader from options clears options for graders', function () {
  this.wrapper.setProps({
    graders: {
      fetchStatus: 'success',
      items: this.graders,
      nextPage: ''
    }
  });

  const input = this.wrapper.find('#graders').node;
  input.click();

  const graderNames = this.graders.map(grader => (grader.name));
  [...document.getElementsByTagName('span')].find(span => graderNames.includes(span.innerHTML)).click();

  ok(this.props.clearSearchOptions.called);
  strictEqual(this.props.clearSearchOptions.firstCall.args[0], 'graders');
});

test('selecting a student from options clears options for students', function () {
  this.wrapper.setProps({
    students: {
      fetchStatus: 'success',
      items: this.students,
      nextPage: ''
    }
  });

  const input = this.wrapper.find('#students').node;
  input.click();

  const studentNames = this.students.map(student => (student.name));
  [...document.getElementsByTagName('span')].find(span => studentNames.includes(span.innerHTML)).click();

  ok(this.props.clearSearchOptions.called);
  strictEqual(this.props.clearSearchOptions.firstCall.args[0], 'students');
});
