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
import { arrayOf, func, number, shape, string } from 'prop-types';
import IconMiniArrowDownSolid from 'instructure-icons/lib/Solid/IconMiniArrowDownSolid';
import Button from 'instructure-ui/lib/components/Button';
import { MenuItem } from 'instructure-ui/lib/components/Menu';
import PopoverMenu from 'instructure-ui/lib/components/PopoverMenu';

function currentlySelectedModule (modules, selectedModuleId) {
  const selectedModule = modules.find(module => module.id === selectedModuleId);

  return selectedModule || {};
}

function sortedModules (modules) {
  return modules.sort((a, b) => (a.position - b.position));
}

class ModuleFilter extends React.Component {
  static propTypes = {
    modules: arrayOf(
      shape({
        id: string.isRequired,
        name: string.isRequired,
        position: number.isRequired
      })).isRequired,
    onSelect: func.isRequired,
    selectedModuleId: string.isRequired
  };

  onSelectModule = (_event, value) => {
    this.props.onSelect(value);
  }

  bindMenuContent = (menuContent) => {
    this.menuContent = menuContent;
  }

  render () {
    const { name } = currentlySelectedModule(this.props.modules, this.props.selectedModuleId);

    return (
      <PopoverMenu
        trigger={
          <Button>
            {name}<IconMiniArrowDownSolid />
          </Button>
        }
        contentRef={this.bindMenuContent}
        onSelect={this.onSelectModule}
      >
        {
          sortedModules(this.props.modules).map(module => (
            <MenuItem
              key={module.id}
              value={module.id}
            >
              {module.name}
            </MenuItem>
          ))
        }
      </PopoverMenu>
    )
  }
}

export default ModuleFilter;
