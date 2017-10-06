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

import { createGradebook, setFixtureHtml } from 'spec/jsx/gradezilla/default_gradebook/GradebookSpecHelper';
import AssignmentRowCellPropFactory from 'jsx/gradezilla/default_gradebook/components/AssignmentRowCellPropFactory';

let fixture;

QUnit.module('AssignmentRowCellPropFactory#getProps', {
  setup () {
    fixture = document.createElement('div');
    document.body.appendChild(fixture);
    setFixtureHtml(fixture);
    this.assignment = { id: '2301' };
    this.gradebook = createGradebook({ context_id: '1201' });
    this.gradebook.gridSupport = {
      helper: {
        commitCurrentEdit: this.stub(),
        focus: this.stub()
      }
    };
    this.factory = new AssignmentRowCellPropFactory(this.assignment, this.gradebook);
    this.student = { id: '1101', isConcluded: false };
  },

  teardown () {
    fixture.remove();
  }
});

test('returns an object with AssignmentRowCell props', function () {
  const props = this.factory.getProps(this.student);
  equal(typeof props.isSubmissionTrayOpen, 'boolean', 'includes isSubmissionTrayOpen');
  equal(typeof props.onToggleSubmissionTrayOpen, 'function', 'includes onToggleSubmissionTrayOpen');
});

test('onToggleSubmissionTrayOpen triggers a render of the submission tray', function () {
  const props = this.factory.getProps(this.student);
  this.stub(this.gradebook, 'renderSubmissionTray');
  props.onToggleSubmissionTrayOpen(this.student.id, this.assignment.id);
  strictEqual(this.gradebook.renderSubmissionTray.callCount, 1)
});

test('onToggleSubmissionTrayOpen sets the tray state', function () {
  const props = this.factory.getProps(this.student);
  this.stub(this.gradebook, 'renderSubmissionTray');
  props.onToggleSubmissionTrayOpen(this.student.id, this.assignment.id);
  deepEqual(
    this.gradebook.getSubmissionTrayState(),
    { open: true, studentId: this.student.id, assignmentId: this.assignment.id }
  );
});

test('onToggleSubmissionTrayOpen cancels current cell edit', function () {
  const props = this.factory.getProps(this.student);
  this.stub(this.gradebook, 'renderSubmissionTray');
  props.onToggleSubmissionTrayOpen(this.student.id, this.assignment.id);
  strictEqual(this.gradebook.gridSupport.helper.commitCurrentEdit.callCount, 1);
});

test('isSubmissionTrayOpen is true if the tray is open for the cell', function () {
  this.gradebook.setSubmissionTrayState(true, this.student.id, this.assignment.id);
  const { isSubmissionTrayOpen } = this.factory.getProps(this.student);
  strictEqual(isSubmissionTrayOpen, true);
});

test('isSubmissionTrayOpen is false if the tray is closed for the cell', function () {
  this.gradebook.setSubmissionTrayState(false, this.student.id, this.assignment.id);
  const { isSubmissionTrayOpen } = this.factory.getProps(this.student);
  strictEqual(isSubmissionTrayOpen, false);
});

test('isSubmissionTrayOpen is false if the tray is open for another cell', function () {
  this.gradebook.setSubmissionTrayState(true, this.student.id, '2302');
  const { isSubmissionTrayOpen } = this.factory.getProps(this.student);
  strictEqual(isSubmissionTrayOpen, false);
});
