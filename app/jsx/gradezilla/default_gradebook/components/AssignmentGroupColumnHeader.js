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

import React from 'react'
import PropTypes from 'prop-types'
import IconMoreSolid from 'instructure-icons/lib/Solid/IconMoreSolid'
import { MenuItem, MenuItemGroup } from 'instructure-ui/lib/components/Menu'
import PopoverMenu from 'instructure-ui/lib/components/PopoverMenu'
import Typography from 'instructure-ui/lib/components/Typography'
import I18n from 'i18n!gradebook'

const { bool, func, number, shape, string } = PropTypes;

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
    sortBySetting: shape({
      direction: string.isRequired,
      disabled: bool.isRequired,
      isSortColumn: bool.isRequired,
      onSortByGradeAscending: func.isRequired,
      onSortByGradeDescending: func.isRequired,
      settingKey: string.isRequired
    }).isRequired,
    weightedGroups: bool.isRequired
  };

  constructor (props) {
    super(props);

    this.bindOptionsMenuContent = (ref) => { this.optionsMenuContent = ref };
  }

  render () {
    const { assignmentGroup, sortBySetting, weightedGroups } = this.props;
    const selectedSortSetting = sortBySetting.isSortColumn && sortBySetting.settingKey;

    return (
      <div className="Gradebook__ColumnHeaderContent">
        <span className="Gradebook__ColumnHeaderDetail">
          <span>{ this.props.assignmentGroup.name }</span>
          { renderAssignmentGroupWeight(assignmentGroup, weightedGroups) }
        </span>

        <PopoverMenu
          contentRef={this.bindOptionsMenuContent}
          focusTriggerOnClose={false}
          trigger={renderTrigger(this.props.assignmentGroup)}
        >
          <MenuItemGroup label={I18n.t('Sort by')}>
            <MenuItem
              selected={selectedSortSetting === 'grade' && sortBySetting.direction === 'ascending'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByGradeAscending}
            >
              <span>{I18n.t('Grade - Low to High')}</span>
            </MenuItem>

            <MenuItem
              selected={selectedSortSetting === 'grade' && sortBySetting.direction === 'descending'}
              disabled={sortBySetting.disabled}
              onSelect={sortBySetting.onSortByGradeDescending}
            >
              <span>{I18n.t('Grade - High to Low')}</span>
            </MenuItem>
          </MenuItemGroup>
        </PopoverMenu>
      </div>
    );
  }
}

export default AssignmentGroupColumnHeader
