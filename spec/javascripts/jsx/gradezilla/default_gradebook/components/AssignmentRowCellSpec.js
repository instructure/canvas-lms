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
import $ from 'jquery';
import { mount, ReactWrapper } from 'enzyme';
import SubmissionCell from 'compiled/gradezilla/SubmissionCell';
import AssignmentRowCell from 'jsx/gradezilla/default_gradebook/components/AssignmentRowCell';

const $fixtures = document.getElementById('fixtures');

function createExampleProps () {
  return {
    canShowSubmissionDetailsModal: true,
    editorOptions: {
      column: {
        field: 'assignment_2301',
        object: {
          grading_type: 'points',
          id: '2301',
          points_possible: 10
        }
      },
      grid: {},
      item: { // student row object
        assignment_2301: { // submission
          user_id: '1101'
        }
      }
    },
    onShowSubmissionDetailsModal () {}
  };
}

QUnit.module('AssignmentRowCell', {
  setup () {
    this.props = createExampleProps();
  },

  mountComponent (props = {}) {
    const allProps = { ...this.props, ...props };
    this.wrapper = mount(<AssignmentRowCell {...allProps} />, { attachTo: $fixtures });
  },

  simulateKeyDown (keyCode, shiftKey = false) {
    $($fixtures).on('keydown', (event) => {
      this.event = event;
      this.wrapper.node.handleKeyDown(event);
      $($fixtures).off('keydown');
    });

    const event = new Event('keydown');
    event.keyCode = keyCode
    event.shiftKey = shiftKey;
    $fixtures.dispatchEvent(event);
  },

  teardown () {
    this.wrapper.unmount();
    $fixtures.innerHTML = '';
  }
});

test('assigns a reference to its child SubmissionCell container', function () {
  this.mountComponent();
  ok(this.wrapper.contains(this.wrapper.node.container), 'component node contains the referenced container node');
});

test('renders an "out_of" SubmissionCell when the assignment grading type is "points"', function () {
  this.mountComponent();
  equal(this.wrapper.node.submissionCell.constructor.name, 'out_of');
  ok(this.wrapper.node.submissionCell instanceof SubmissionCell.out_of);
});

test('renders the SubmissionCell within the AssignmentRowCell', function () {
  this.mountComponent();
  ok(this.wrapper.node.container.querySelector('.gradebook-cell'), 'container includes a gradebook cell');
});

test('includes editor options when rendering the SubmissionCell', function () {
  this.mountComponent();
  equal(this.wrapper.node.submissionCell.opts.item, this.props.editorOptions.item);
});

test('renders an "out_of" SubmissionCell when a "points" assignment has zero points possible', function () {
  this.props.editorOptions.column.object.points_possible = 0;
  this.mountComponent();
  equal(this.wrapper.node.submissionCell.constructor.name, 'out_of');
  ok(this.wrapper.node.submissionCell instanceof SubmissionCell.out_of);
});

test('renders a "points" SubmissionCell when a "points" assignment grading type has null points possible', function () {
  this.props.editorOptions.column.object.points_possible = null;
  this.mountComponent();
  equal(this.wrapper.node.submissionCell.constructor.name, 'points');
  ok(this.wrapper.node.submissionCell instanceof SubmissionCell.points);
});

test('renders an "pass_fail" SubmissionCell when the assignment grading type is "pass_fail"', function () {
  this.props.editorOptions.column.object.grading_type = 'pass_fail';
  this.mountComponent();
  equal(this.wrapper.node.submissionCell.constructor.name, 'pass_fail');
  ok(this.wrapper.node.submissionCell instanceof SubmissionCell.pass_fail);
});

test('renders a SubmissionCell when the assignment grading type is "percent"', function () {
  this.props.editorOptions.column.object.grading_type = 'percent';
  this.mountComponent();
  equal(this.wrapper.node.submissionCell.constructor.name, 'SubmissionCell');
  ok(this.wrapper.node.submissionCell instanceof SubmissionCell);
});

test('#handleKeyDown skips SlickGrid default behavior when tabbing from grade input', function () {
  this.mountComponent();
  this.wrapper.node.submissionCell.focus();
  this.simulateKeyDown(9, false); // tab to options menu trigger
  strictEqual(this.event.originalEvent.skipSlickGridDefaults, true);
});

test('#handleKeyDown skips SlickGrid default behavior when shift-tabbing from options menu', function () {
  this.mountComponent();
  this.wrapper.node.optionsButton.focus();
  this.simulateKeyDown(9, true); // shift+tab back to grade input
  strictEqual(this.event.originalEvent.skipSlickGridDefaults, true);
});

test('#handleKeyDown does not skip SlickGrid default behavior when tabbing from options menu', function () {
  this.mountComponent();
  this.wrapper.node.optionsButton.focus();
  this.simulateKeyDown(9, false); // tab into next cell
  equal(typeof this.event.originalEvent.skipSlickGridDefaults, 'undefined');
});

test('#handleKeyDown does not skip SlickGrid default behavior when tabbing from options menu', function () {
  this.mountComponent();
  this.wrapper.node.submissionCell.focus();
  this.simulateKeyDown(9, true); // shift+tab back to previous cell
  equal(typeof this.event.originalEvent.skipSlickGridDefaults, 'undefined');
});

test('#handleKeyDown skips SlickGrid default behavior when entering into options menu', function () {
  this.mountComponent();
  this.wrapper.node.optionsButton.focus();
  this.simulateKeyDown(13); // enter into options menu
  strictEqual(this.event.originalEvent.skipSlickGridDefaults, true);
});

test('#handleKeyDown does not skip SlickGrid default behavior when pressing enter on grade input', function () {
  this.mountComponent();
  this.wrapper.node.submissionCell.focus();
  this.simulateKeyDown(13); // enter on grade input (commit editor)
  equal(typeof this.event.originalEvent.skipSlickGridDefaults, 'undefined');
});

test('#focus delegates to the SubmissionCell', function () {
  this.mountComponent();
  this.spy(this.wrapper.node.submissionCell, 'focus');
  this.wrapper.node.focus();
  strictEqual(this.wrapper.node.submissionCell.focus.callCount, 1);
});

test('#isValueChanged delegates to the SubmissionCell', function () {
  this.mountComponent();
  this.stub(this.wrapper.node.submissionCell, 'isValueChanged').returns(true);
  const changed = this.wrapper.node.isValueChanged();
  strictEqual(this.wrapper.node.submissionCell.isValueChanged.callCount, 1);
  strictEqual(changed, true);
});

test('#serializeValue delegates to the SubmissionCell', function () {
  this.mountComponent();
  this.stub(this.wrapper.node.submissionCell, 'serializeValue').returns('9.7');
  const value = this.wrapper.node.serializeValue();
  strictEqual(this.wrapper.node.submissionCell.serializeValue.callCount, 1);
  strictEqual(value, '9.7');
});

test('#loadValue delegates to the SubmissionCell', function () {
  this.mountComponent();
  this.spy(this.wrapper.node.submissionCell, 'loadValue');
  this.wrapper.node.loadValue('9.7');
  strictEqual(this.wrapper.node.submissionCell.loadValue.callCount, 1);
  const [value] = this.wrapper.node.submissionCell.loadValue.lastCall.args;
  strictEqual(value, '9.7');
});

test('#applyValue delegates to the SubmissionCell', function () {
  this.mountComponent();
  this.stub(this.wrapper.node.submissionCell, 'applyValue');
  this.wrapper.node.applyValue({ id: '1101' }, '9.7');
  strictEqual(this.wrapper.node.submissionCell.applyValue.callCount, 1);
  const [item, value] = this.wrapper.node.submissionCell.applyValue.lastCall.args;
  deepEqual(item, { id: '1101' });
  strictEqual(value, '9.7');
});

test('#validate delegates to the SubmissionCell', function () {
  this.mountComponent();
  this.stub(this.wrapper.node.submissionCell, 'validate').returns({ valid: true });
  const validation = this.wrapper.node.validate();
  strictEqual(this.wrapper.node.submissionCell.validate.callCount, 1);
  deepEqual(validation, { valid: true });
});

test('destroys the SubmissionCell when unmounting', function () {
  this.mountComponent();
  this.spy(this.wrapper.node.submissionCell, 'destroy');
  this.wrapper.unmount();
  strictEqual(this.wrapper.node.submissionCell.destroy.callCount, 1);
});

QUnit.module('AssignmentRowCell Options Menu', {
  setup () {
    this.props = createExampleProps();
  },

  mountAndOpenOptions (props = {}) {
    const allProps = { ...this.props, ...props };
    this.wrapper = mount(<AssignmentRowCell {...allProps} />, { attachTo: $fixtures });
    this.wrapper.node.optionsButton.handleClick(new MouseEvent('click'));
  },

  findMenuItem (text) {
    const optionsMenu = new ReactWrapper(this.wrapper.node.optionsMenuContent, this.wrapper.node);
    return optionsMenu.findWhere(component => component.name() === 'MenuItem' && component.text().includes(text));
  },

  teardown () {
    this.wrapper.unmount();
    $fixtures.innerHTML = '';
  }
});

test('includes "Submission Details" in the options menu when canShowSubmissionDetailsModal is true', function () {
  this.mountAndOpenOptions();
  strictEqual(this.findMenuItem('Submission Details').length, 1);
});

test('excludes "Submission Details" in the options menu when canShowSubmissionDetailsModal is false', function () {
  this.mountAndOpenOptions({ canShowSubmissionDetailsModal: false });
  strictEqual(this.findMenuItem('Submission Details').length, 0);
});

test('calls onShowSubmissionDetailsModal when "Submission Details" is selected', function () {
  const onShowSubmissionDetailsModal = this.spy();
  this.mountAndOpenOptions({ onShowSubmissionDetailsModal });
  this.findMenuItem('Submission Details').simulate('click');
  strictEqual(onShowSubmissionDetailsModal.callCount, 1);
});

test('restores focus to options menu trigger when Submission Details Modal is closed', function () {
  let onClose;
  const onShowSubmissionDetailsModal = (options) => { onClose = options.onClose };
  this.mountAndOpenOptions({ onShowSubmissionDetailsModal });
  this.findMenuItem('Submission Details').simulate('click');
  strictEqual(this.wrapper.node.optionsButton.focused, false);
  onClose();
  strictEqual(this.wrapper.node.optionsButton.focused, true);
});
