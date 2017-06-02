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
import { shallow } from 'enzyme';
import moment from 'moment';
import GradebookHistoryStore from 'jsx/gradebook-history/store/GradebookHistoryStore';
import { SearchFormComponent } from 'jsx/gradebook-history/SearchForm';
import SearchActions from 'jsx/gradebook-history/actions/SearchActions';
import Button from 'instructure-ui/lib/components/Button';
import DateInput from 'instructure-ui/lib/components/DateInput';
import FormFieldGroup from 'instructure-ui/lib/components/FormFieldGroup';
import TextInput from 'instructure-ui/lib/components/TextInput';
import { destroyContainer } from 'jsx/shared/FlashAlert';

const functionStubHelper = (dispatchStub, functionToDispatch) => (
  (id, timeFrame) => {
    dispatchStub(functionToDispatch(id, timeFrame))
  }
)

QUnit.module('SearchForm', {
  setup () {
    this.func = this.stub();
    const props = {
      fetchHistoryStatus: 'success',
      byAssignment: this.func,
      byGrader: this.func,
      byStudent: this.func
    };
    this.wrapper = shallow(<SearchFormComponent {...props} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('has a form field group', function () {
  ok(this.wrapper.find(FormFieldGroup).exists());
});

test('has a TextInput with id #grader', function () {
  const input = this.wrapper.find('#grader');
  equal(input.length, 1);
  ok(input.is(TextInput));
});

test('has a TextInput with id #student', function () {
  const input = this.wrapper.find('#student');
  equal(input.length, 1);
  ok(input.is(TextInput));
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
  setup (customProps = {}) {
    this.getHistoryByAssignmentStub = this.stub(SearchActions, 'getHistoryByAssignment');
    this.getHistoryByGraderStub = this.stub(SearchActions, 'getHistoryByGrader');
    this.getHistoryByStudentStub = this.stub(SearchActions, 'getHistoryByStudent');
    this.dispatchStub = this.stub(GradebookHistoryStore, 'dispatch');

    this.props = {
      fetchHistoryStatus: 'success',
      byAssignment: functionStubHelper(this.dispatchStub, this.getHistoryByAssignmentStub),
      byGrader: functionStubHelper(this.dispatchStub, this.getHistoryByGraderStub),
      byStudent: functionStubHelper(this.dispatchStub, this.getHistoryByStudentStub)
    };

    this.wrapper = shallow(<SearchFormComponent {...this.props} {...customProps} />);
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
})

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
  const earlyDate = '2017-01-01T00:00:00-00:00';
  const futureDate = '2017-01-02T00:00:00-00:00';
  this.wrapper.setState({
    assignment,
    from: earlyDate,
    to: futureDate
  }, () => {
    const timeFrame = {
      from: moment(earlyDate).startOf('day').format(),
      to: moment(futureDate).endOf('day').format()
    };
    this.wrapper.find(Button).simulate('click');
    equal(this.getHistoryByAssignmentStub.getCall(0).args[0], assignment);
    deepEqual(this.getHistoryByAssignmentStub.getCall(0).args[1], timeFrame);
  });
});

test('dispatches getHistoryByGrader with grader id and timeFrame', function () {
  const grader = '1011';
  const earlyDate = '2017-01-01T00:00:00-00:00';
  const futureDate = '2017-01-02T00:00:00-00:00';
  this.wrapper.setState({
    grader,
    from: earlyDate,
    to: futureDate
  }, () => {
    const timeFrame = {
      from: moment(earlyDate).startOf('day').format(),
      to: moment(futureDate).endOf('day').format()
    };
    this.wrapper.find(Button).simulate('click');
    equal(this.getHistoryByGraderStub.getCall(0).args[0], grader);
    deepEqual(this.getHistoryByGraderStub.getCall(0).args[1], timeFrame);
  });
});

test('dispatches getHistoryByStudent with student id and timeFrame', function () {
  const student = '1100';
  const earlyDate = '2017-01-01T00:00:00-00:00';
  const futureDate = '2017-01-02T00:00:00-00:00';
  this.wrapper.setState({
    student,
    from: earlyDate,
    to: futureDate
  }, () => {
    const timeFrame = {
      from: moment(earlyDate).startOf('day').format(),
      to: moment(futureDate).endOf('day').format()
    };
    this.wrapper.find(Button).simulate('click');
    equal(this.getHistoryByStudentStub.getCall(0).args[0], student);
    deepEqual(this.getHistoryByStudentStub.getCall(0).args[1], timeFrame);
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
    deepEqual(this.getHistoryByAssignmentStub.getCall(0).args[1], timeFrame);
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
    deepEqual(this.getHistoryByAssignmentStub.getCall(0).args[1], timeFrame);
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
    deepEqual(this.getHistoryByAssignmentStub.getCall(0).args[1], timeFrame);
  });
});

QUnit.module('SearchForm fetchHistoryStatus prop', {
  setup () {
    this.func = this.stub();
    const props = {
      fetchHistoryStatus: 'started',
      byAssignment: this.func,
      byGrader: this.func,
      byStudent: this.func
    };
    this.wrapper = shallow(<SearchFormComponent {...props} />);
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
