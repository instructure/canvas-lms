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
import IconMiniArrowDownSolid from 'instructure-icons/lib/Solid/IconMiniArrowDownSolid'
import Button from '@instructure/ui-core/lib/components/Button'
import { MenuItem, MenuItemSeparator } from '@instructure/ui-core/lib/components/Menu'
import PopoverMenu from '@instructure/ui-core/lib/components/PopoverMenu'
import Text from '@instructure/ui-core/lib/components/Text'
import I18n from 'i18n!gradebook'

  const { oneOf, bool, string, func } = PropTypes;

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

    constructor (props) {
      super(props);

      this.handleDefaultGradebookSelect = this.handleDefaultGradebookSelect.bind(this);
      this.handleIndividualGradebookSelect = this.handleIndividualGradebookSelect.bind(this);
      this.handleGradebookHistorySelect = this.handleGradebookHistorySelect.bind(this);
      this.handleLearningMasterySelect = this.handleLearningMasterySelect.bind(this);
    }

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
        <MenuItem onSelect={this.handleDefaultGradebookSelect} key={key}>
          <span data-menu-item-id={key}>
            {I18n.t('Gradebook…')}
          </span>
        </MenuItem>
      );
    }

    renderIndividualGradebookMenuItem () {
      const key = 'individual-gradebook';
      return (
        <MenuItem onSelect={this.handleIndividualGradebookSelect} key={key}>
          <span data-menu-item-id={key}>
            {I18n.t('Individual View…')}
          </span>
        </MenuItem>
      );
    }

    renderGradebookHistoryMenuItem () {
      const key = 'gradebook-history';
      return (
        <MenuItem onSelect={this.handleGradebookHistorySelect} key={key}>
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
        <MenuItem onSelect={this.handleLearningMasterySelect} key={key}>
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
        <PopoverMenu trigger={this.renderButton()}>
          {this.renderMenuItems()}
        </PopoverMenu>
      );
    }
  }

export default GradebookMenu;
