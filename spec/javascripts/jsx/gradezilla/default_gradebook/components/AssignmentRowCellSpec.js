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
import { mount } from 'enzyme';
import SubmissionCell from 'compiled/gradezilla/SubmissionCell';
import AssignmentRowCell from 'jsx/gradezilla/default_gradebook/components/AssignmentRowCell';

QUnit.module('AssignmentRowCell', (suiteHooks) => {
  let $container;
  let props;
  let wrapper;

  function mountComponent () {
    return mount(<AssignmentRowCell {...props} />, { attachTo: $container });
  }

  function simulateKeyDown (keyCode, shiftKey = false) {
    const event = new Event('keydown');
    event.which = keyCode
    event.shiftKey = shiftKey;
    return wrapper.node.handleKeyDown(event);
  }

  suiteHooks.beforeEach(() => {
    $container = document.createElement('div');
    document.body.appendChild($container);

    props = {
      editorOptions: {
        column: {
          assignmentId: '2301',
          field: 'assignment_2301',
          object: {
            grading_type: 'points',
            id: '2301',
            points_possible: 10
          }
        },
        grid: {},
        item: { // student row object
          id: '1101',
          assignment_2301: { // submission
            user_id: '1101'
          }
        }
      },
      isSubmissionTrayOpen: false,
      onToggleSubmissionTrayOpen () {},
    };
  });

  suiteHooks.afterEach(() => {
    wrapper.unmount();
    $container.remove();
  });

  QUnit.module('#render', () => {
    test('assigns a reference to its child SubmissionCell container', () => {
      wrapper = mountComponent();
      ok(wrapper.contains(wrapper.node.container), 'component node contains the referenced container node');
    });

    test('renders an "out_of" SubmissionCell when the assignment grading type is "points"', () => {
      wrapper = mountComponent();
      equal(wrapper.node.submissionCell.constructor.name, 'out_of');
      ok(wrapper.node.submissionCell instanceof SubmissionCell.out_of);
    });

    test('renders the SubmissionCell within the AssignmentRowCell', () => {
      wrapper = mountComponent();
      ok(wrapper.node.container.querySelector('.gradebook-cell'), 'container includes a gradebook cell');
    });

    test('includes editor options when rendering the SubmissionCell', () => {
      wrapper = mountComponent();
      equal(wrapper.node.submissionCell.opts.item, props.editorOptions.item);
    });

    test('renders an "out_of" SubmissionCell when a "points" assignment has zero points possible', () => {
      props.editorOptions.column.object.points_possible = 0;
      wrapper = mountComponent();
      equal(wrapper.node.submissionCell.constructor.name, 'out_of');
      ok(wrapper.node.submissionCell instanceof SubmissionCell.out_of);
    });

    test('renders a "points" SubmissionCell when a "points" assignment grading type has null points possible', () => {
      props.editorOptions.column.object.points_possible = null;
      wrapper = mountComponent();
      equal(wrapper.node.submissionCell.constructor.name, 'points');
      ok(wrapper.node.submissionCell instanceof SubmissionCell.points);
    });

    test('renders an "pass_fail" SubmissionCell when the assignment grading type is "pass_fail"', () => {
      props.editorOptions.column.object.grading_type = 'pass_fail';
      wrapper = mountComponent();
      equal(wrapper.node.submissionCell.constructor.name, 'pass_fail');
      ok(wrapper.node.submissionCell instanceof SubmissionCell.pass_fail);
    });

    test('renders a SubmissionCell when the assignment grading type is "percent"', () => {
      props.editorOptions.column.object.grading_type = 'percent';
      wrapper = mountComponent();
      equal(wrapper.node.submissionCell.constructor.name, 'SubmissionCell');
      ok(wrapper.node.submissionCell instanceof SubmissionCell);
    });
  });

  QUnit.module('#handleKeyDown', () => {
    test('skips SlickGrid default behavior when tabbing from grade input', () => {
      wrapper = mountComponent();
      wrapper.node.submissionCell.focus();
      const continueHandling = simulateKeyDown(9, false); // tab to tray button trigger
      strictEqual(continueHandling, false);
    });

    test('skips SlickGrid default behavior when shift-tabbing from tray button', () => {
      wrapper = mountComponent();
      wrapper.node.trayButton.focus();
      const continueHandling = simulateKeyDown(9, true); // shift+tab back to grade input
      strictEqual(continueHandling, false);
    });

    test('does not skip SlickGrid default behavior when tabbing from tray button', () => {
      wrapper = mountComponent();
      wrapper.node.trayButton.focus();
      const continueHandling = simulateKeyDown(9, false); // tab into next cell
      equal(typeof continueHandling, 'undefined');
    });

    test('does not skip SlickGrid default behavior when shift-tabbing from grade input', () => {
      wrapper = mountComponent();
      wrapper.node.submissionCell.focus();
      const continueHandling = simulateKeyDown(9, true); // shift+tab back to previous cell
      equal(typeof continueHandling, 'undefined');
    });

    test('skips SlickGrid default behavior when entering into tray button', () => {
      wrapper = mountComponent();
      wrapper.node.trayButton.focus();
      const continueHandling = simulateKeyDown(13); // enter into tray button
      strictEqual(continueHandling, false);
    });

    test('does not skip SlickGrid default behavior when pressing enter on grade input', () => {
      wrapper = mountComponent();
      wrapper.node.submissionCell.focus();
      const continueHandling = simulateKeyDown(13); // enter on grade input (commit editor)
      equal(typeof continueHandling, 'undefined');
    });
  });

  QUnit.module('#focus', () => {
    test('delegates to the SubmissionCell "focus" method', () => {
      wrapper = mountComponent();
      sinon.spy(wrapper.node.submissionCell, 'focus');
      wrapper.node.focus();
      strictEqual(wrapper.node.submissionCell.focus.callCount, 1);
    });
  });

  QUnit.module('#isValueChanged', () => {
    test('delegates to the SubmissionCell "isValueChanged" method', () => {
      wrapper = mountComponent();
      sinon.stub(wrapper.node.submissionCell, 'isValueChanged').returns(true);
      const changed = wrapper.node.isValueChanged();
      strictEqual(wrapper.node.submissionCell.isValueChanged.callCount, 1);
      strictEqual(changed, true);
    });
  });

  QUnit.module('#serializeValue', () => {
    test('delegates to the SubmissionCell "serializeValue" method', () => {
      wrapper = mountComponent();
      sinon.stub(wrapper.node.submissionCell, 'serializeValue').returns('9.7');
      const value = wrapper.node.serializeValue();
      strictEqual(wrapper.node.submissionCell.serializeValue.callCount, 1);
      strictEqual(value, '9.7');
    });
  });

  QUnit.module('#loadValue', () => {
    test('delegates to the SubmissionCell "loadValue" method', () => {
      wrapper = mountComponent();
      sinon.spy(wrapper.node.submissionCell, 'loadValue');
      wrapper.node.loadValue('9.7');
      strictEqual(wrapper.node.submissionCell.loadValue.callCount, 1);
      const [value] = wrapper.node.submissionCell.loadValue.lastCall.args;
      strictEqual(value, '9.7');
    });
  });

  QUnit.module('#applyValue', () => {
    test('delegates to the SubmissionCell "applyValue" method', () => {
      wrapper = mountComponent();
      sinon.stub(wrapper.node.submissionCell, 'applyValue');
      wrapper.node.applyValue({ id: '1101' }, '9.7');
      strictEqual(wrapper.node.submissionCell.applyValue.callCount, 1);
      const [item, value] = wrapper.node.submissionCell.applyValue.lastCall.args;
      deepEqual(item, { id: '1101' });
      strictEqual(value, '9.7');
    });
  });

  QUnit.module('#validate', () => {
    test('delegates to the SubmissionCell "validate" method', () => {
      wrapper = mountComponent();
      sinon.stub(wrapper.node.submissionCell, 'validate').returns({ valid: true });
      const validation = wrapper.node.validate();
      strictEqual(wrapper.node.submissionCell.validate.callCount, 1);
      deepEqual(validation, { valid: true });
    });
  });

  QUnit.module('#componentWillUnmount', () => {
    test('destroys the SubmissionCell', () => {
      wrapper = mountComponent();
      sinon.spy(wrapper.node.submissionCell, 'destroy');
      wrapper.unmount();
      strictEqual(wrapper.node.submissionCell.destroy.callCount, 1);
    });
  });

  QUnit.module('"Toggle Tray" Button', () => {
    test('calls onToggleSubmissionTrayOpen when clicked', () => {
      props.onToggleSubmissionTrayOpen = sinon.stub();
      wrapper = mountComponent();
      wrapper.find('.Grid__AssignmentRowCell__Options button').simulate('click');
      strictEqual(props.onToggleSubmissionTrayOpen.callCount, 1);
    });

    test('calls onToggleSubmissionTrayOpen with the student id and assignment id', () => {
      props.onToggleSubmissionTrayOpen = sinon.stub();
      wrapper = mountComponent();
      wrapper.find('.Grid__AssignmentRowCell__Options button').simulate('click');
      deepEqual(props.onToggleSubmissionTrayOpen.getCall(0).args, ['1101', '2301']);
    });
  });
});
