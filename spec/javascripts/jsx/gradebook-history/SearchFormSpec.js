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
import { SearchFormComponent } from 'jsx/gradebook-history/SearchForm';
import Button from '@instructure/ui-buttons/lib/components/Button';
import DateInput from '@instructure/ui-forms/lib/components/DateInput';
import FormFieldGroup from '@instructure/ui-forms/lib/components/FormFieldGroup';
import { destroyContainer } from 'jsx/shared/FlashAlert';
import Fixtures from '../gradebook-history/Fixtures';

const defaultProps = () => (
  {
    fetchHistoryStatus: 'started',
    getGradebookHistory () {},
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
  ok(input.is('Select'));
});

test('has an Autocomplete with id #students', function () {
  const input = this.wrapper.find('#students');
  equal(input.length, 1);
  ok(input.is('Select'));
});

test('has an Autocomplete with id #assignments', function () {
  const input = this.wrapper.find('#assignments');
  equal(input.length, 1);
  ok(input.is('Select'));
});

test('has DateInputs for from date and to date', function () {
  const inputs = this.wrapper.find(DateInput);
  equal(inputs.length, 2);
  ok(inputs.every(DateInput));
});

test('has a Button for submitting', function () {
  ok(this.wrapper.find(Button).exists());
});

test('disables the submit button if To date is before From date', function () {
  this.wrapper.setState({
    selected: {
      from: { value: '2017-05-02T00:00:00-05:00', conversionFailed: false },
      to: { value: '2017-05-01T00:00:00-05:00', conversionFailed: false }
    }
  }, () => {
    const button = this.wrapper.find(Button);
    ok(button.props().disabled);
  });
});

test('does not disable the submit button if To date is after From date', function () {
  this.wrapper.setState({
    selected: {
      from: { value: '2017-05-01T00:00:00-05:00', conversionFailed: false },
      to: { value: '2017-05-02T00:00:00-05:00', conversionFailed: false }
    }
  }, () => {
    const button = this.wrapper.find(Button);
    notOk(button.props().disabled);
  });
});

test('disables the submit button if the To date DateInput conversion failed', function () {
  this.wrapper.setState({
    selected: {
      from: { value: '', conversionFailed: false },
      to: { value: '2017-05-02T00:00:00-05:00', conversionFailed: true }
    }
  }, () => {
    const button = this.wrapper.find(Button);
    ok(button.props().disabled);
  });
});

test('disables the submit button if the From date DateInput conversion failed', function () {
  this.wrapper.setState({
    selected: {
      from: { value: '2017-05-02T00:00:00-05:00', conversionFailed: true },
      to: { value: '', conversionFailed: false },
    }
  }, () => {
    const button = this.wrapper.find(Button);
    ok(button.props().disabled);
  });
});

test('does not disable the submit button when there are no dates selected', function () {
  const { from, to } = this.wrapper.state().selected;
  const button = this.wrapper.find(Button);
  ok(!from.value && !to.value);
  notOk(button.props().disabled);
});

test('does not disable the submit button when only from date is entered', function () {
  this.wrapper.setState({
    selected: {
      from: { value: '1994-04-08T00:00:00-05:00', conversionFailed: false },
      to: { value: '', conversionFailed: false }
    }
  }, () => {
    const button = this.wrapper.find(Button);
    notOk(button.props().disabled);
  });
});

test('does not disable the submit button when only to date is entered', function () {
  this.wrapper.setState({
    selected: {
      from: { value: '', conversionFailed: false },
      to: { value: '2017-05-01T00:00:00-05:00', conversionFailed: false }
    }
  }, () => {
    const button = this.wrapper.find(Button);
    notOk(button.props().disabled);
  });
});

test('calls getGradebookHistory prop on mount', function () {
  const props = { getGradebookHistory: sinon.stub() };
  const wrapper = mount(<SearchFormComponent {...defaultProps()} {...props} />);
  strictEqual(props.getGradebookHistory.callCount, 1);
  wrapper.unmount();
});

QUnit.module('SearchForm when button is clicked', {
  setup () {
    this.props = { getGradebookHistory: sinon.stub() };
    this.wrapper = mountComponent(this.props);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('dispatches with the state of input', function () {
  const selected = {
    assignment: '1',
    grader: '2',
    student: '3',
    from: { value: '2017-05-20T00:00:00-05:00', conversionFailed: false },
    to: { value: '2017-05-21T00:00:00-05:00', conversionFailed: false }
  };

  this.wrapper.setState({
    selected
  }, () => {
    this.wrapper.find(Button).simulate('click');
    deepEqual(this.props.getGradebookHistory.lastCall.args[0], selected);
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
  const flashMessageContainer = document.getElementById('flashalert_message_holder');
  ok(flashMessageContainer.childElementCount > 0);
});

QUnit.module('SearchForm Autocomplete', {
  setup () {
    this.props = {
      ...defaultProps(),
      fetchHistoryStatus: 'started',
      clearSearchOptions: sinon.stub(),
      getSearchOptions: sinon.stub(),
      getSearchOptionsNextPage: sinon.stub(),
    };

    this.wrapper = mount(<SearchFormComponent {...this.props} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('typing more than two letters for assignments hits getSearchOptions prop', function () {
  const input = this.wrapper.find('#assignments').last();
  input.simulate('change', { target: { id: 'assignments', value: 'Chapter 11 Questions' } });
  strictEqual(this.props.getSearchOptions.callCount, 1);
});

test('typing more than two letters for graders hits getSearchOptions prop', function () {
  const input = this.wrapper.find('#graders').last();
  input.simulate('change', { target: { id: 'graders', value: 'Norval' } });
  strictEqual(this.props.getSearchOptions.callCount, 1);
});

test('typing more than two letters for students hits getSearchOptions prop if not empty', function () {
  const input = this.wrapper.find('#students').last();
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
  const input = this.wrapper.find('#assignments').last();
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
  const input = this.wrapper.find('#graders').last();
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
  const input = this.wrapper.find('#students').last();
  input.simulate('change', { target: { id: 'students', value: 'ab' } });
  strictEqual(this.props.clearSearchOptions.callCount, 1);
});

test('getSearchOptions is called with search term and input id', function () {
  const input = this.wrapper.find('#graders').last();
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
    this.props = { ...defaultProps(), clearSearchOptions: sinon.stub() };
    this.assignments = Fixtures.assignmentArray();
    this.graders = Fixtures.userArray();
    this.students = Fixtures.userArray();
    this.wrapper = mount(<SearchFormComponent {...this.props} />, {attachTo: document.getElementById('fixtures')});
  },

  teardown () {
    this.wrapper.unmount();
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

  const input = this.wrapper.find('#graders').last().instance();
  input.click();

  const graderNames = this.graders.map(grader => (grader.name));
  [...document.getElementsByTagName('span')].find(span => graderNames.includes(span.textContent)).click();

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

  const input = this.wrapper.find('#students').last().instance();
  input.click();
  const studentNames = this.students.map(student => student.name);

  [...document.getElementsByTagName('span')].find(span => studentNames.includes(span.textContent)).click();
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

  const input = this.wrapper.find('#assignments').last().instance();
  input.click();

  const assignmentNames = this.assignments.map(assignment => (assignment.name));
  [...document.getElementsByTagName('span')].find(span => assignmentNames.includes(span.textContent)).click();

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

  const input = this.wrapper.find('#assignments').last().instance();
  input.click();

  const assignmentNames = this.assignments.map(assignment => (assignment.name));
  [...document.getElementsByTagName('span')].find(span => assignmentNames.includes(span.textContent)).click();

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

  const input = this.wrapper.find('#graders').last().instance();
  input.click();

  const graderNames = this.graders.map(grader => (grader.name));
  [...document.getElementsByTagName('span')].find(span => graderNames.includes(span.textContent)).click();

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

  const input = this.wrapper.find('#students').last().instance();
  input.click();

  const studentNames = this.students.map(student => (student.name));

  [...document.getElementsByTagName('span')].find(span => studentNames.includes(span.textContent)).click();
  ok(this.props.clearSearchOptions.called);
  strictEqual(this.props.clearSearchOptions.firstCall.args[0], 'students');
});

test('no search records found for students results in a message instead', function () {
  this.wrapper.setProps({
    students: {
      fetchStatus: 'success',
      items: [],
      nextPage: ''
    }
  });

  this.wrapper.find('#students').last().instance().click();

  const noRecords = [...document.getElementsByTagName('span')].find(
                      span => span.textContent === 'No students with that name found'
                    );

  ok(noRecords);
});

test('no search records found for graders results in a message instead', function () {
  this.wrapper.setProps({
    graders: {
      fetchStatus: 'success',
      items: [],
      nextPage: ''
    }
  });

  this.wrapper.find('#graders').last().instance().click();

  const noRecords = [...document.getElementsByTagName('span')].find(
                      span => span.textContent === 'No graders with that name found'
                    );

  ok(noRecords);
});

test('no search records found for assignments results in a message instead', function () {
  this.wrapper.setProps({
    assignments: {
      fetchStatus: 'success',
      items: [],
      nextPage: ''
    }
  });

  this.wrapper.find('#assignments').last().instance().click();

  const noRecords = [...document.getElementsByTagName('span')].find(
                      span => span.textContent === 'No assignments with that name found'
                    );

  ok(noRecords);
});
