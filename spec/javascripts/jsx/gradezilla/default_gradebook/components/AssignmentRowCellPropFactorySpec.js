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

import { createGradebook } from 'spec/jsx/gradezilla/default_gradebook/GradebookSpecHelper';
import SubmissionDetailsDialog from 'compiled/SubmissionDetailsDialog';
import AssignmentRowCellPropFactory from 'jsx/gradezilla/default_gradebook/components/AssignmentRowCellPropFactory';

QUnit.module('AssignmentRowCellPropFactory#getProps', {
  setup () {
    this.assignment = { id: '2301' };
    this.gradebook = createGradebook({ context_id: '1201' });
    this.factory = new AssignmentRowCellPropFactory(this.assignment, this.gradebook);
    this.student = { id: '1101', isConcluded: false };
  }
});

test('returns an object with AssignmentRowCell props', function () {
  const props = this.factory.getProps(this.student);
  equal(typeof props.canShowSubmissionDetailsModal, 'boolean', 'includes canShowSubmissionDetailsModal');
  equal(typeof props.onShowSubmissionDetailsModal, 'function', 'includes onShowSubmissionDetailsModal');
});

test('sets canShowSubmissionDetailsModal to true when student enrollment is not concluded', function () {
  const props = this.factory.getProps(this.student);
  strictEqual(props.canShowSubmissionDetailsModal, true);
});

test('sets canShowSubmissionDetailsModal to false when student enrollment is concluded', function () {
  const props = this.factory.getProps({ ...this.student, isConcluded: true });
  strictEqual(props.canShowSubmissionDetailsModal, false);
});

test('onShowSubmissionDetailsModal function opens the SubmissionDetailsDialog', function () {
  const props = this.factory.getProps(this.student);
  this.stub(SubmissionDetailsDialog, 'open');
  props.onShowSubmissionDetailsModal({});
  strictEqual(SubmissionDetailsDialog.open.callCount, 1);
});

test('SubmissionDetailsDialog.open uses the assignment and student', function () {
  const props = this.factory.getProps(this.student);
  this.stub(SubmissionDetailsDialog, 'open');
  props.onShowSubmissionDetailsModal({});
  const [assignment, student] = SubmissionDetailsDialog.open.lastCall.args;
  equal(assignment, this.assignment, 'uses the given assignment');
  equal(student, this.student, 'uses the given student');
});

test('SubmissionDetailsDialog.open merges the gradebook options with function arguments', function () {
  const props = this.factory.getProps(this.student);
  this.stub(SubmissionDetailsDialog, 'open');
  props.onShowSubmissionDetailsModal({ onClose () {} });
  const options = SubmissionDetailsDialog.open.lastCall.args[2];
  strictEqual(options.context_id, '1201', 'includes options from the Gradebook');
  equal(typeof options.onClose, 'function', 'includes function arguments');
});
