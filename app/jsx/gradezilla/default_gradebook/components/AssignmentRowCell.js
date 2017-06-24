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
import PropTypes from 'prop-types'
import IconMoreSolid from 'instructure-icons/lib/Solid/IconMoreSolid';
import Button from 'instructure-ui/lib/components/Button';
import { MenuItem } from 'instructure-ui/lib/components/Menu';
import PopoverMenu from 'instructure-ui/lib/components/PopoverMenu';
import I18n from 'i18n!gradebook';
import SubmissionCell from 'compiled/gradezilla/SubmissionCell';

const { bool, func, shape } = PropTypes;

function renderSubmissionCell (options) {
  const assignment = options.column.object;
  if (assignment.grading_type === 'points' && assignment.points_possible != null) {
    return new SubmissionCell.out_of(options); // eslint-disable-line new-cap
  }
  return new (SubmissionCell[assignment.grading_type] || SubmissionCell)(options);
}

function renderTrigger (bindButton) {
  return (
    <Button ref={bindButton} size="small" variant="icon">
      <IconMoreSolid title={I18n.t('Submission Options')} />
    </Button>
  );
}

class AssignmentRowCell extends React.Component {
  static propTypes = {
    canShowSubmissionDetailsModal: bool.isRequired,
    editorOptions: shape({
      column: shape({}).isRequired,
      grid: shape({}).isRequired,
      item: shape({}).isRequired
    }).isRequired,
    onShowSubmissionDetailsModal: func.isRequired
  };

  constructor (props) {
    super(props);

    this.bindOptionsMenuContent = (ref) => { this.optionsMenuContent = ref };
    this.bindContainerRef = (ref) => { this.container = ref };
    this.bindOptionsButton = (ref) => { this.optionsButton = ref };

    this.handleKeyDown = this.handleKeyDown.bind(this);
    this.showSubmissionDetailsModal = this.showSubmissionDetailsModal.bind(this);
  }

  componentDidMount () {
    this.submissionCell = renderSubmissionCell({ ...this.props.editorOptions, container: this.container });
  }

  componentWillUnmount () {
    this.submissionCell.destroy();
  }

  handleKeyDown (jQueryEvent) {
    const submissionCellHasFocus = this.container.contains(document.activeElement);
    const popoverTriggerHasFocus = this.optionsButton.focused;

    /* eslint-disable no-param-reassign */
    if (jQueryEvent.keyCode === 9) { // tab
      if (!jQueryEvent.shiftKey && submissionCellHasFocus) {
        jQueryEvent.originalEvent.skipSlickGridDefaults = true;
      } else if (jQueryEvent.shiftKey && popoverTriggerHasFocus) {
        jQueryEvent.originalEvent.skipSlickGridDefaults = true;
      }
    }
    if (jQueryEvent.keyCode === 13 && popoverTriggerHasFocus) { // enter
      jQueryEvent.originalEvent.skipSlickGridDefaults = true;
    }
    /* eslint-enable no-param-reassign */
  }

  applyValue (item, state) {
    this.submissionCell.applyValue(item, state);
  }

  focus () {
    this.submissionCell.focus();
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

  showSubmissionDetailsModal () {
    this.props.onShowSubmissionDetailsModal({
      onClose: () => { this.optionsButton.focus() }
    });
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
          <PopoverMenu
            contentRef={this.bindOptionsMenuContent}
            focusTriggerOnClose={false}
            trigger={renderTrigger(this.bindOptionsButton)}
          >
            {
              this.props.canShowSubmissionDetailsModal &&
              <MenuItem onSelect={this.showSubmissionDetailsModal}>
                <span id="ShowSubmissionDetailsAction">
                  { I18n.t('Submission Details…') }
                </span>
              </MenuItem>
            }
          </PopoverMenu>
        </div>
      </div>
    );
  }
}

export default AssignmentRowCell;
