/*
 * Copyright (C) 2017 Instructure, Inc.
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

import React from 'react'
import IconMoreSolid from 'instructure-icons/react/Solid/IconMoreSolid'
import { MenuItem } from 'instructure-ui/Menu'
import PopoverMenu from 'instructure-ui/PopoverMenu'
import Typography from 'instructure-ui/Typography'
import I18n from 'i18n!gradebook'

const { bool, number, shape, string } = React.PropTypes;

// TODO: remove this rule when this component begins using internal state
/* eslint-disable react/prefer-stateless-function */

function renderTrigger (assignmentGroup) {
  return (
    <span className="Gradebook__ColumnHeaderAction">
      <Typography weight="bold" fontStyle="normal" size="large" color="brand">
        <IconMoreSolid title={I18n.t('%{name} Options', { name: assignmentGroup.name })} />
      </Typography>
    </span>
  );
}

function renderAssignmentGroupWeight (assignmentGroup, weightedGroups) {
  if (!weightedGroups) {
    return '';
  }

  const weightValue = assignmentGroup.groupWeight || 0;
  const weightStr = I18n.n(weightValue, { precision: 2, percentage: true });

  return (
    <Typography weight="normal" fontStyle="normal" size="x-small">
      { I18n.t('%{weight} of grade', { weight: weightStr }) }
    </Typography>
  );
}

class AssignmentGroupColumnHeader extends React.Component {
  static propTypes = {
    assignmentGroup: shape({
      name: string.isRequired,
      groupWeight: number
    }).isRequired,
    weightedGroups: bool.isRequired
  };

  render () {
    const { assignmentGroup, weightedGroups } = this.props;

    return (
      <div className="Gradebook__ColumnHeaderContent">
        <span className="Gradebook__ColumnHeaderDetail">
          <span>{ this.props.assignmentGroup.name }</span>
          { renderAssignmentGroupWeight(assignmentGroup, weightedGroups) }
        </span>

        <PopoverMenu
          zIndex="9999"
          trigger={renderTrigger(this.props.assignmentGroup)}
        >
          <MenuItem>Placeholder Item 1</MenuItem>
          <MenuItem>Placeholder Item 2</MenuItem>
          <MenuItem>Placeholder Item 3</MenuItem>
        </PopoverMenu>
      </div>
    );
  }
}

export default AssignmentGroupColumnHeader
