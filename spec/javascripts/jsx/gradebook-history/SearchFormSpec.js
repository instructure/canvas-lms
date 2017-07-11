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
import constants from 'jsx/gradebook-history/constants';
import GradebookHistoryStore from 'jsx/gradebook-history/store/GradebookHistoryStore';
import { SearchFormComponent } from 'jsx/gradebook-history/SearchForm';
import SearchFormActions from 'jsx/gradebook-history/actions/SearchFormActions';
import UserApi from 'jsx/gradebook-history/api/UserApi';
import Autocomplete from 'instructure-ui/lib/components/Autocomplete';
import Button from 'instructure-ui/lib/components/Button';
import DateInput from 'instructure-ui/lib/components/DateInput';
import FormFieldGroup from 'instructure-ui/lib/components/FormFieldGroup';
import TextInput from 'instructure-ui/lib/components/TextInput';
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
    fetchGradersStatus: 'started',
    fetchStudentsStatus: 'started',
    byAssignment: sinon.stub(),
    byDate: sinon.stub(),
    byGrader: sinon.stub(),
    byStudent: sinon.stub(),
    getNameOptions: sinon.stub(),
    getNameOptionsNextPage: sinon.stub(),
    graderOptions: [],
    studentOptions: []
  }
)

const mountComponent = (props = {}) => (
  shallow(<SearchFormComponent {...defaultProps()} {...props} />)
)

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

test('has a TextInput with id #assignment', function () {
  const input = this.wrapper.find('#assignment');
  equal(input.length, 1);
  ok(input.is(TextInput));
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
    assignment: '',
    grader: '',
    student: '',
    from: '',
    to: ''
  };
  this.wrapper.setState({ emptyState }, () => {
    this.wrapper.find(Button).simulate('click');
    equal(this.dispatchStub.callCount, 0);
  });
});

test('dispatches when assignment not empty', function () {
  this.wrapper.setState({ assignment: '1' }, () => {
    this.wrapper.find(Button).simulate('click');
    equal(this.dispatchStub.callCount, 1);
  });
});

test('dispatches when grader not empty', function () {
  this.wrapper.setState({ grader: '1' }, () => {
    this.wrapper.find(Button).simulate('click');
    equal(this.dispatchStub.callCount, 1);
  });
});

test('dispatches when student not empty', function () {
  this.wrapper.setState({ student: '1' }, () => {
    this.wrapper.find(Button).simulate('click');
    equal(this.dispatchStub.callCount, 1);
  });
});

test('dispatches getHistoryByAssignment with assignment id and timeFrame', function () {
  const assignment = '1010';
  const timeFrame = Fixtures.timeFrame();
  this.wrapper.setState({
    assignment,
    from: timeFrame.from,
    to: timeFrame.to
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
    grader,
    from: timeFrame.from,
    to: timeFrame.to
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
    student,
    from: timeFrame.from,
    to: timeFrame.to
  }, () => {
    this.wrapper.find(Button).simulate('click');
    equal(this.getHistoryByStudentStub.firstCall.args[0], student);
    deepEqual(this.getHistoryByStudentStub.firstCall.args[1], stretchTimeFrame(timeFrame));
  });
});

test('dispatches getHistoryByDate with timeFrame', function () {
  const timeFrame = Fixtures.timeFrame();
  this.wrapper.setState({
    from: timeFrame.from,
    to: timeFrame.to
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
    assignment,
    from: futureDate,
    to: earlyDate
  }, () => {
    this.wrapper.find(Button).simulate('click');
    equal(this.dispatchStub.callCount, 0);
    equal(this.getHistoryByAssignmentStub.callCount, 0);
  });
});

test('dispatches with empty strings if no dates selected', function () {
  const assignment = '1110';
  this.wrapper.setState({ assignment }, () => {
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
    assignment,
    from: earlyDate,
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
    assignment,
    to: futureDate,
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
    this.stub(constants, 'courseId').returns(this.courseId);
    this.props = {
      ...defaultProps(),
      fetchHistoryStatus: 'started',
    };
    this.getUsersByNameStub = this.stub(UserApi, 'getUsersByName')
      .returns(Promise.resolve({
        response: {}
      }));
    this.wrapper = mount(<SearchFormComponent {...this.props} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('typing more than two letters in Autocomplete for graders hits getNameOptions prop', function () {
  const input = this.wrapper.find('#graders');
  input.simulate('change', {target: {id: 'graders', value: 'Norval'}});
  strictEqual(this.props.getNameOptions.callCount, 1);
});

test('typing more than two letters in Autocomplete for students hits getNameOptions prop', function () {
  const input = this.wrapper.find('#students');
  input.simulate('change', {target: {id: 'students', value: 'Norval'}});
  strictEqual(this.props.getNameOptions.callCount, 1);
});

test('getNameOptions is called with search term and input id', function () {
  const input = this.wrapper.find('#graders');
  const inputId = 'graders';
  const searchTerm = 'Norval Abbott';
  input.simulate('change', {target: {id: inputId, value: searchTerm}});
  strictEqual(this.props.getNameOptions.firstCall.args[0], inputId);
  strictEqual(this.props.getNameOptions.firstCall.args[1], searchTerm);
});

test('getNameOptionsNextPage is called if there are more users to load', function () {
  this.wrapper.setProps({ studentOptionsNextPage: 'https://fake.url' });
  strictEqual(this.props.getNameOptionsNextPage.firstCall.args[0], 'students');
  strictEqual(this.props.getNameOptionsNextPage.firstCall.args[1], 'https://fake.url');
});

QUnit.module('SearchForm Autocomplete options', {
  setup () {
    this.graders = Fixtures.userArray();
    this.students = Fixtures.userArray();
    this.props = {
      ...defaultProps(),
      graderOptions: this.graders,
      studentOptions: this.students,
      fetchGradersStatus: 'success',
      fetchStudentsStatus: 'success',
    }
    this.wrapper = mount(<SearchFormComponent {...this.props} />);
  }
});

test('for graders reflect graderOptions prop', function () {
  const input = this.wrapper.find('#graders').node;
  input.click();

  const graderNames = this.graders.map(grader => grader.name);
  const options = [...document.getElementsByTagName('span')].reduce((acc, span) => {
    if (graderNames.includes(span.innerHTML)) {
      acc.push(span.innerHTML);
    }
    return acc;
  }, []);

  this.graders.forEach((grader) => {
    ok(options.includes(grader.name));
  });

  strictEqual(options.length, this.graders.length);
});

test('for students reflect studentOptions prop', function () {
  const input = this.wrapper.find('#students').node;
  input.click();

  const studentNames = this.students.map(student => student.name);
  const options = [...document.getElementsByTagName('span')].reduce((acc, span) => {
    if (studentNames.includes(span.innerHTML)) {
      acc.push(span.innerHTML);
    }
    return acc;
  }, []);

  this.students.forEach((student) => {
    ok(options.includes(student.name));
  });

  strictEqual(options.length, this.students.length);
});

test('selecting a grader from options sets state to its id', function () {
  const input = this.wrapper.find('#graders').node;
  input.click();

  const graderNames = this.graders.map(grader => (grader.name));
  [...document.getElementsByTagName('span')].find(span => graderNames.includes(span.innerHTML)).click();

  strictEqual(this.wrapper.state().grader, this.graders[0].id);
});

test('selecting a student from options sets state to its id', function () {
  const input = this.wrapper.find('#students').node;
  input.click();

  const studentNames = this.students.map(student => (student.name));
  [...document.getElementsByTagName('span')].find(span => studentNames.includes(span.innerHTML)).click();

  strictEqual(this.wrapper.state().student, this.students[0].id);
});
