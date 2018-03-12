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

import CellEditorFactory from 'jsx/gradezilla/default_gradebook/GradebookGrid/editors/CellEditorFactory'
import AssignmentCellEditor from 'jsx/gradezilla/default_gradebook/GradebookGrid/editors/AssignmentCellEditor'

QUnit.module('CellEditorFactory');

test('#getEditor returns AssignmentCellEditor for columns of type "assignment"', function () {
  const factory = new CellEditorFactory();
  equal(factory.getEditor({ type: 'assignment' }), AssignmentCellEditor);
});

test('#getEditor returns undefined for unhandled column types', function () {
  const factory = new CellEditorFactory();
  equal(typeof factory.getEditor({ type: 'unknown' }), 'undefined');
});
