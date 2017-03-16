//
// Copyright (C) 2017 Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
//

define([
  'react',
  'instructure-icons/react/Solid/IconMiniArrowDownSolid',
  'instructure-ui/Button',
  'instructure-ui/Menu',
  'instructure-ui/PopoverMenu',
  'instructure-ui/Typography',
  'i18n!gradebook'
], (React, { default: IconMiniArrowDownSolid }, { default: Button }, { MenuItem, MenuItemSeparator },
  { default: PopoverMenu }, { default: Typography }, I18n) => {
  const { oneOf, bool, string, func } = React.PropTypes;

  class GradebookMenu extends React.Component {
    static propTypes = {
      courseUrl: string.isRequired,
      learningMasteryEnabled: bool.isRequired,
      navigate: func.isRequired,
      variant: oneOf(['DefaultGradebook', 'DefaultGradebookLearningMastery']).isRequired
    };

    static menuItemsForGradebook = {
      DefaultGradebook: ['LearningMastery', 'IndividualGradebook', 'Separator', 'GradeHistory'],
      DefaultGradebookLearningMastery: ['DefaultGradebook', 'IndividualGradebook', 'Separator', 'GradeHistory'],
    };

    constructor (props) {
      super(props);

      this.handleDefaultGradebookSelect = this.handleDefaultGradebookSelect.bind(this);
      this.handleIndividualGradebookSelect = this.handleIndividualGradebookSelect.bind(this);
      this.handleGradeHistorySelect = this.handleGradeHistorySelect.bind(this);
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

    handleGradeHistorySelect () {
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

    renderGradeHistoryMenuItem () {
      const key = 'grade-history';
      return (
        <MenuItem onSelect={this.handleGradeHistorySelect} key={key}>
          <span data-menu-item-id={key}>
            {I18n.t('Grade History…')}
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
          <Typography color="primary">
            {label} <IconMiniArrowDownSolid />
          </Typography>
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

  return GradebookMenu;
});
