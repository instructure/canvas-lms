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
import { oneOf, bool, string, func } from 'prop-types'
import IconMiniArrowDownSolid from '@instructure/ui-icons/lib/Solid/IconMiniArrowDown'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Menu, { MenuItem, MenuItemSeparator } from '@instructure/ui-menu/lib/components/Menu'
import Text from '@instructure/ui-elements/lib/components/Text'
import I18n from 'i18n!gradebook'


  class GradebookMenu extends React.Component {
    static propTypes = {
      courseUrl: string.isRequired,
      learningMasteryEnabled: bool.isRequired,
      navigate: func.isRequired,
      variant: oneOf(['DefaultGradebook', 'DefaultGradebookLearningMastery']).isRequired
    };

    static menuItemsForGradebook = {
      DefaultGradebook: ['LearningMastery', 'IndividualGradebook', 'Separator', 'GradebookHistory'],
      DefaultGradebookLearningMastery: ['DefaultGradebook', 'IndividualGradebook', 'Separator', 'GradebookHistory'],
    };

    setLocation (url) {
      window.location = url;
    }

    handleDefaultGradebookSelect () {
      this.props.navigate('tab-assignment', { trigger: true });
    }

    handleLearningMasterySelect () {
      this.props.navigate('tab-outcome', { trigger: true });
    }

    handleIndividualGradebookSelect () {
      this.setLocation(`${this.props.courseUrl}/gradebook/change_gradebook_version?version=individual`);
    }

    handleGradebookHistorySelect () {
      this.setLocation(`${this.props.courseUrl}/gradebook/history`);
    }

    renderDefaultGradebookMenuItem () {
      const key = 'default-gradebook';
      return (
        <MenuItem onSelect={() => this.handleDefaultGradebookSelect()} key={key}>
          <span data-menu-item-id={key}>
            {I18n.t('Gradebook…')}
          </span>
        </MenuItem>
      );
    }

    renderIndividualGradebookMenuItem () {
      const key = 'individual-gradebook';
      return (
        <MenuItem onSelect={() => this.handleIndividualGradebookSelect()} key={key}>
          <span data-menu-item-id={key}>
            {I18n.t('Individual View…')}
          </span>
        </MenuItem>
      );
    }

    renderGradebookHistoryMenuItem () {
      const key = 'gradebook-history';
      return (
        <MenuItem onSelect={() => this.handleGradebookHistorySelect()} key={key}>
          <span data-menu-item-id={key}>
            {I18n.t('Gradebook History…')}
          </span>
        </MenuItem>
      );
    }

    renderLearningMasteryMenuItem () {
      if (!this.props.learningMasteryEnabled) return null;
      const key = 'learning-mastery';
      return (
        <MenuItem onSelect={() => this.handleLearningMasterySelect()} key={key}>
          <span data-menu-item-id={key}>
            {I18n.t('Learning Mastery…')}
          </span>
        </MenuItem>
      );
    }

    renderSeparatorMenuItem () {
      return <MenuItemSeparator key="separator" />;
    }

    renderMenuItems () {
      const menuItems = GradebookMenu.menuItemsForGradebook[this.props.variant];
      return menuItems.map(menuItem => this[`render${menuItem}MenuItem`]());
    }

    renderButton () {
      let label = I18n.t('Gradebook');
      if (this.props.variant === 'DefaultGradebookLearningMastery') label = I18n.t('Learning Mastery');
      return (
        <Button variant="link">
          <Text color="primary">
            {label} <IconMiniArrowDownSolid />
          </Text>
        </Button>
      );
    }

    render () {
      return (
        <Menu trigger={this.renderButton()}>
          {this.renderMenuItems()}
        </Menu>
      );
    }
  }

export default GradebookMenu;
