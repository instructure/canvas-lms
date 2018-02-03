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
import { bool, func, shape, string } from 'prop-types';
import Button from '@instructure/ui-core/lib/components/Button';
import SubmissionCell from 'compiled/gradezilla/SubmissionCell';
import IconExpandLeftLine from 'instructure-icons/lib/Line/IconExpandLeftLine';
import I18n from 'i18n!gradebook';

function renderSubmissionCell (options) {
  const assignment = options.column.object;
  if (assignment.grading_type === 'points' && assignment.points_possible != null) {
    return new SubmissionCell.out_of(options); // eslint-disable-line new-cap
  }
  return new (SubmissionCell[assignment.grading_type] || SubmissionCell)(options);
}

class AssignmentRowCell extends React.Component {
  static propTypes = {
    isSubmissionTrayOpen: bool.isRequired,
    editorOptions: shape({
      column: shape({
        assignmentId: string.isRequired
      }).isRequired,
      grid: shape({}).isRequired,
      item: shape({
        id: string.isRequired
      }).isRequired,
    }).isRequired,
    onToggleSubmissionTrayOpen: func.isRequired
  };

  constructor (props) {
    super(props);

    this.bindContainerRef = (ref) => { this.container = ref };
    this.bindToggleTrayButtonRef = (ref) => { this.trayButton = ref };
  }

  componentDidMount () {
    this.submissionCell = renderSubmissionCell({ ...this.props.editorOptions, container: this.container });
  }

  componentDidUpdate (prevProps) {
    if (prevProps.isSubmissionTrayOpen && !this.props.isSubmissionTrayOpen) {
      this.focusToggleTrayButton();
    }
  }

  componentWillUnmount () {
    this.submissionCell.destroy();
  }

  handleKeyDown = (event) => {
    const submissionCellHasFocus = this.container.contains(document.activeElement);
    const popoverTriggerHasFocus = this.trayButton.focused;

    if (event.which === 9) { // Tab
      if (!event.shiftKey && submissionCellHasFocus) {
        // browser will set focus on the tray button
        return false; // prevent Grid behavior
      } else if (event.shiftKey && popoverTriggerHasFocus) {
        // browser will set focus on the submission cell
        return false; // prevent Grid behavior
      }
    }

    if (event.which === 13 && popoverTriggerHasFocus) { // Enter
      // browser will activate the tray button
      return false; // prevent Grid behavior
    }

    return undefined;
  }

  handleToggleTrayButtonClick = () => {
    const options = this.props.editorOptions;
    this.props.onToggleSubmissionTrayOpen(options.item.id, options.column.assignmentId);
  }

  applyValue (item, state) {
    this.submissionCell.applyValue(item, state);
  }

  focus () {
    this.submissionCell.focus();
  }

  focusToggleTrayButton = () => {
    if (this.trayButton) {
      this.trayButton.focus();
    }
  }

  isValueChanged () {
    return this.submissionCell.isValueChanged();
  }

  loadValue (item) {
    this.submissionCell.loadValue(item);
  }

  serializeValue () {
    return this.submissionCell.serializeValue();
  }

  validate () {
    return this.submissionCell.validate();
  }

  render () {
    return (
      <div className="Grid__AssignmentRowCell">
        <div className="Grid__AssignmentRowCell__Notifications" />

        <div className="Grid__AssignmentRowCell__Content" ref={this.bindContainerRef} />

        <div className="Grid__AssignmentRowCell__Options">
          <Button
            ref={this.bindToggleTrayButtonRef}
            onClick={this.handleToggleTrayButtonClick}
            size="small"
            variant="icon"
          >
            <IconExpandLeftLine title={I18n.t('Open submission tray')} />
          </Button>
        </div>
      </div>
    );
  }
}

export default AssignmentRowCell;
