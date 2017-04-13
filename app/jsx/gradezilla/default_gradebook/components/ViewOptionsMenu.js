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

import React from 'react';
import IconMiniArrowDownSolid from 'instructure-icons/lib/Solid/IconMiniArrowDownSolid'
import Button from 'instructure-ui/lib/components/Button';
import { MenuItem, MenuItemGroup, MenuItemSeparator } from 'instructure-ui/lib/components/Menu';
import PopoverMenu from 'instructure-ui/lib/components/PopoverMenu';
import Typography from 'instructure-ui/lib/components/Typography';
import I18n from 'i18n!gradebook';

const { bool, func, shape } = React.PropTypes;

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

  render () {
    return (
      <PopoverMenu
        trigger={renderTriggerButton()}
        contentRef={this.bindMenuContent}
      >
        <MenuItemGroup label={I18n.t('Arrange By')}>
          <MenuItem defaultSelected>
            { I18n.t('Assignment Name') }
          </MenuItem>

          <MenuItem>
            { I18n.t('Due Date') }
          </MenuItem>

          <MenuItem>
            { I18n.t('Points') }
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
