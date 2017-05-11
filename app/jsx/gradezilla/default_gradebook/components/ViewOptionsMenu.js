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
import IconMiniArrowDownSolid from 'instructure-icons/lib/Solid/IconMiniArrowDownSolid'
import Button from 'instructure-ui/lib/components/Button';
import { MenuItem, MenuItemGroup, MenuItemSeparator } from 'instructure-ui/lib/components/Menu';
import PopoverMenu from 'instructure-ui/lib/components/PopoverMenu';
import Typography from 'instructure-ui/lib/components/Typography';
import I18n from 'i18n!gradebook';

const { bool, func, shape, string } = React.PropTypes;

function renderTriggerButton () {
  return (
    <Button variant="link">
      <Typography color="primary">
        {I18n.t('View')} <IconMiniArrowDownSolid />
      </Typography>
    </Button>
  );
}

class ViewOptionsMenu extends React.Component {
  static propTypes = {
    columnSortSettings: shape({
      criterion: string.isRequired,
      direction: string.isRequired,
      disabled: bool.isRequired,
      onSortByDefault: func.isRequired,
      onSortByNameAscending: func.isRequired,
      onSortByNameDescending: func.isRequired,
      onSortByDueDateAscending: func.isRequired,
      onSortByDueDateDescending: func.isRequired,
      onSortByPointsAscending: func.isRequired,
      onSortByPointsDescending: func.isRequired
    }).isRequired,
    teacherNotes: shape({
      disabled: bool.isRequired,
      onSelect: func.isRequired,
      selected: bool.isRequired
    }).isRequired,
    showUnpublishedAssignments: React.PropTypes.bool.isRequired,
    onSelectShowUnpublishedAssignments: React.PropTypes.func.isRequired
  };

  constructor (props) {
    super(props);
    this.bindMenuContent = (ref) => { this.menuContent = ref };
  }

  areColumnsOrderedBy (criterion, direction) {
    const sortSettings = this.props.columnSortSettings;
    const result = sortSettings.criterion === criterion;

    if (direction === undefined) {
      return result;
    } else {
      return result && sortSettings.direction === direction;
    }
  }

  render () {
    return (
      <PopoverMenu
        trigger={renderTriggerButton()}
        contentRef={this.bindMenuContent}
      >
        <MenuItemGroup label={I18n.t('Arrange By')}>
          <MenuItem
            disabled={this.props.columnSortSettings.disabled}
            selected={this.areColumnsOrderedBy('default')}
            onSelect={this.props.columnSortSettings.onSortByDefault}
          >
            { I18n.t('Default Order') }
          </MenuItem>

          <MenuItem
            disabled={this.props.columnSortSettings.disabled}
            selected={this.areColumnsOrderedBy('name', 'ascending')}
            onSelect={this.props.columnSortSettings.onSortByNameAscending}
          >
            { I18n.t('Assignment Name - A-Z') }
          </MenuItem>

          <MenuItem
            disabled={this.props.columnSortSettings.disabled}
            selected={this.areColumnsOrderedBy('name', 'descending')}
            onSelect={this.props.columnSortSettings.onSortByNameDescending}
          >
            { I18n.t('Assignment Name - Z-A') }
          </MenuItem>

          <MenuItem
            disabled={this.props.columnSortSettings.disabled}
            selected={this.areColumnsOrderedBy('due_date', 'ascending')}
            onSelect={this.props.columnSortSettings.onSortByDueDateAscending}
          >
            { I18n.t('Due Date - Oldest to Newest') }
          </MenuItem>

          <MenuItem
            disabled={this.props.columnSortSettings.disabled}
            selected={this.areColumnsOrderedBy('due_date', 'descending')}
            onSelect={this.props.columnSortSettings.onSortByDueDateDescending}
          >
            { I18n.t('Due Date - Newest to Oldest') }
          </MenuItem>

          <MenuItem
            disabled={this.props.columnSortSettings.disabled}
            selected={this.areColumnsOrderedBy('points', 'ascending')}
            onSelect={this.props.columnSortSettings.onSortByPointsAscending}
          >
            { I18n.t('Points - Lowest to Highest') }
          </MenuItem>

          <MenuItem
            disabled={this.props.columnSortSettings.disabled}
            selected={this.areColumnsOrderedBy('points', 'descending')}
            onSelect={this.props.columnSortSettings.onSortByPointsDescending}
          >
            { I18n.t('Points - Highest to Lowest') }
          </MenuItem>
        </MenuItemGroup>

        <MenuItemSeparator />

        <MenuItemGroup allowMultiple label={I18n.t('Columns')}>
          <MenuItem
            disabled={this.props.teacherNotes.disabled}
            onSelect={this.props.teacherNotes.onSelect}
            selected={this.props.teacherNotes.selected}
          >
            <span data-menu-item-id="show-notes-column">{I18n.t('Notes')}</span>
          </MenuItem>

          <MenuItem
            selected={this.props.showUnpublishedAssignments}
            onSelect={this.props.onSelectShowUnpublishedAssignments}
          >
            {I18n.t('Unpublished Assignments')}
          </MenuItem>
        </MenuItemGroup>
      </PopoverMenu>
    );
  }
}

export default ViewOptionsMenu;
