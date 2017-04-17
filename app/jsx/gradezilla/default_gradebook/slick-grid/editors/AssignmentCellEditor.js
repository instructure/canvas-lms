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
import ReactDOM from 'react-dom';
import SubmissionCell from 'compiled/gradezilla/SubmissionCell';
import AssignmentRowCell from 'jsx/gradezilla/default_gradebook/components/AssignmentRowCell';

function renderSubmissionCell (options) {
  const assignment = options.column.object;
  if (assignment.grading_type === 'points' && assignment.points_possible != null) {
    return new SubmissionCell.out_of(options); // eslint-disable-line new-cap
  }
  return new (SubmissionCell[assignment.grading_type] || SubmissionCell)(options);
}

class AssignmentCellEditor {
  constructor (options) {
    this.container = options.container;

    const bindContainer = (ref) => { this.reactContainer = ref };
    const element = React.createElement(AssignmentRowCell, { containerRef: bindContainer }, null);
    ReactDOM.render(element, this.container);

    this.submissionCell = renderSubmissionCell({ ...options, container: this.reactContainer });
  }

  destroy () {
    this.submissionCell.destroy();
    ReactDOM.unmountComponentAtNode(this.container);
  }

  focus () {
    this.submissionCell.focus();
  }

  isValueChanged () {
    return this.submissionCell.isValueChanged();
  }

  serializeValue () {
    return this.submissionCell.serializeValue();
  }

  loadValue (item) {
    this.submissionCell.loadValue(item);
  }

  applyValue (item, state) {
    this.submissionCell.applyValue(item, state);
  }

  validate () {
    return this.submissionCell.validate();
  }
}

export default AssignmentCellEditor;
