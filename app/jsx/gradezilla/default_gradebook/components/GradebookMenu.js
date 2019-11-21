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
import {oneOf, bool, string, func} from 'prop-types'
import {IconMiniArrowDownSolid} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-elements'
import I18n from 'i18n!gradezilla'

class GradebookMenu extends React.Component {
  static propTypes = {
    courseUrl: string.isRequired,
    learningMasteryEnabled: bool.isRequired,
    navigate: func.isRequired,
    variant: oneOf(['DefaultGradebook', 'DefaultGradebookLearningMastery']).isRequired
  }

  static menuItemsForGradebook = {
    DefaultGradebook: ['LearningMastery', 'IndividualGradebook', 'Separator', 'GradebookHistory'],
    DefaultGradebookLearningMastery: [
      'DefaultGradebook',
      'IndividualGradebook',
      'Separator',
      'GradebookHistory'
    ]
  }

  setLocation(url) {
    window.location = url
  }

  handleDefaultGradebookSelect() {
    this.props.navigate('tab-assignment', {trigger: true})
  }

  handleLearningMasterySelect() {
    this.props.navigate('tab-outcome', {trigger: true})
  }

  handleIndividualGradebookSelect() {
    this.setLocation(
      `${this.props.courseUrl}/gradebook/change_gradebook_version?version=individual`
    )
  }

  handleGradebookHistorySelect() {
    this.setLocation(`${this.props.courseUrl}/gradebook/history`)
  }

  renderDefaultGradebookMenuItem() {
    const key = 'default-gradebook'
    return (
      <Menu.Item onSelect={() => this.handleDefaultGradebookSelect()} key={key}>
        <span data-menu-item-id={key}>{I18n.t('Gradebook…')}</span>
      </Menu.Item>
    )
  }

  renderIndividualGradebookMenuItem() {
    const key = 'individual-gradebook'
    return (
      <Menu.Item onSelect={() => this.handleIndividualGradebookSelect()} key={key}>
        <span data-menu-item-id={key}>{I18n.t('Individual View…')}</span>
      </Menu.Item>
    )
  }

  renderGradebookHistoryMenuItem() {
    const key = 'gradebook-history'
    return (
      <Menu.Item onSelect={() => this.handleGradebookHistorySelect()} key={key}>
        <span data-menu-item-id={key}>{I18n.t('Gradebook History…')}</span>
      </Menu.Item>
    )
  }

  renderLearningMasteryMenuItem() {
    if (!this.props.learningMasteryEnabled) return null
    const key = 'learning-mastery'
    return (
      <Menu.Item onSelect={() => this.handleLearningMasterySelect()} key={key}>
        <span data-menu-item-id={key}>{I18n.t('Learning Mastery…')}</span>
      </Menu.Item>
    )
  }

  renderSeparatorMenuItem() {
    return <Menu.Separator key="separator" />
  }

  renderMenuItems() {
    const menuItems = GradebookMenu.menuItemsForGradebook[this.props.variant]
    return menuItems.map(menuItem => this[`render${menuItem}MenuItem`]())
  }

  renderButton() {
    let label = I18n.t('Gradebook')
    if (this.props.variant === 'DefaultGradebookLearningMastery') label = I18n.t('Learning Mastery')
    return (
      <Button variant="link">
        <Text color="primary">
          {label} <IconMiniArrowDownSolid />
        </Text>
      </Button>
    )
  }

  render() {
    return <Menu trigger={this.renderButton()}>{this.renderMenuItems()}</Menu>
  }
}

export default GradebookMenu
