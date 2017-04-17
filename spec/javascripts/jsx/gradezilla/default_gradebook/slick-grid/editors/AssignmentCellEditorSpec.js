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

import ReactDOM from 'react-dom';
import SubmissionCell from 'compiled/gradezilla/SubmissionCell';
import AssignmentCellEditor from 'jsx/gradezilla/default_gradebook/slick-grid/editors/AssignmentCellEditor';

QUnit.module('AssignmentCellEditor', {
  setup () {
    this.$fixtures = document.querySelector('#fixtures');
    this.options = {
      column: {
        field: 'assignment_2301',
        object: { // assignment
          grading_type: 'points',
          id: '2301',
          points_possible: 10
        }
      },
      item: { // student row object
        assignment_2301: { // submission
          user_id: '1101'
        }
      }
    };
  },

  createEditor (options = {}) {
    this.editor = new AssignmentCellEditor({ ...this.options, ...options, container: this.$fixtures });
  },

  teardown () {
    if (this.$fixtures.childNodes.length > 0) {
      this.editor.destroy();
    }
    this.$fixtures.innerHTML = '';
  }
});

test('creates an AssignmentRowCell in the given container', function () {
  this.spy(ReactDOM, 'render');
  this.createEditor();
  strictEqual(ReactDOM.render.callCount, 1, 'renders once with React');
  const [element, container] = ReactDOM.render.lastCall.args;
  equal(element.type.name, 'AssignmentRowCell');
  equal(container, this.$fixtures, 'container is the test #fixtures element');
});

test('renders an "out_of" SubmissionCell when the assignment grading type is "points"', function () {
  this.createEditor();
  equal(this.editor.submissionCell.constructor.name, 'out_of');
  ok(this.editor.submissionCell instanceof SubmissionCell.out_of);
});

test('renders the SubmissionCell within the AssignmentRowCell', function () {
  this.createEditor();
  ok(this.editor.reactContainer.querySelector('.gradebook-cell'), 'reactContainer includes a gradebook cell');
});

test('renders an "out_of" SubmissionCell when a "points" assignment has zero points possible', function () {
  this.options.column.object.points_possible = 0;
  this.createEditor();
  equal(this.editor.submissionCell.constructor.name, 'out_of');
  ok(this.editor.submissionCell instanceof SubmissionCell.out_of);
});

test('renders a "points" SubmissionCell when a "points" assignment grading type has null points possible', function () {
  this.options.column.object.points_possible = null;
  this.createEditor();
  equal(this.editor.submissionCell.constructor.name, 'points');
  ok(this.editor.submissionCell instanceof SubmissionCell.points);
});

test('renders an "pass_fail" SubmissionCell when the assignment grading type is "pass_fail"', function () {
  this.options.column.object.grading_type = 'pass_fail';
  this.createEditor();
  equal(this.editor.submissionCell.constructor.name, 'pass_fail');
  ok(this.editor.submissionCell instanceof SubmissionCell.pass_fail);
});

test('renders a SubmissionCell when the assignment grading type is "percent"', function () {
  this.options.column.object.grading_type = 'percent';
  this.createEditor();
  equal(this.editor.submissionCell.constructor.name, 'SubmissionCell');
  ok(this.editor.submissionCell instanceof SubmissionCell);
});

test('#destroy destroys the SubmissionCell', function () {
  this.createEditor();
  this.spy(this.editor.submissionCell, 'destroy');
  this.editor.destroy();
  strictEqual(this.editor.submissionCell.destroy.callCount, 1);
});

test('#destroy unmounts the AssignmentRowCell component', function () {
  this.createEditor();
  this.editor.destroy();
  const unmounted = ReactDOM.unmountComponentAtNode(this.$fixtures);
  strictEqual(unmounted, false, 'component was already unmounted');
});

test('#focus delegates to the SubmissionCell', function () {
  this.createEditor();
  this.spy(this.editor.submissionCell, 'focus');
  this.editor.focus();
  strictEqual(this.editor.submissionCell.focus.callCount, 1);
});

test('#isValueChanged delegates to the SubmissionCell', function () {
  this.createEditor();
  this.stub(this.editor.submissionCell, 'isValueChanged').returns(true);
  const changed = this.editor.isValueChanged();
  strictEqual(this.editor.submissionCell.isValueChanged.callCount, 1);
  strictEqual(changed, true);
});

test('#serializeValue delegates to the SubmissionCell', function () {
  this.createEditor();
  this.stub(this.editor.submissionCell, 'serializeValue').returns('9.7');
  const value = this.editor.serializeValue();
  strictEqual(this.editor.submissionCell.serializeValue.callCount, 1);
  strictEqual(value, '9.7');
});

test('#loadValue delegates to the SubmissionCell', function () {
  this.createEditor();
  this.spy(this.editor.submissionCell, 'loadValue');
  this.editor.loadValue('9.7');
  strictEqual(this.editor.submissionCell.loadValue.callCount, 1);
  const [value] = this.editor.submissionCell.loadValue.lastCall.args;
  strictEqual(value, '9.7');
});

test('#applyValue delegates to the SubmissionCell', function () {
  this.createEditor();
  this.stub(this.editor.submissionCell, 'applyValue');
  this.editor.applyValue({ id: '1101' }, '9.7');
  strictEqual(this.editor.submissionCell.applyValue.callCount, 1);
  const [item, value] = this.editor.submissionCell.applyValue.lastCall.args;
  deepEqual(item, { id: '1101' });
  strictEqual(value, '9.7');
});

test('#validate delegates to the SubmissionCell', function () {
  this.createEditor();
  this.stub(this.editor.submissionCell, 'validate').returns({ valid: true });
  const validation = this.editor.validate();
  strictEqual(this.editor.submissionCell.validate.callCount, 1);
  deepEqual(validation, { valid: true });
});
