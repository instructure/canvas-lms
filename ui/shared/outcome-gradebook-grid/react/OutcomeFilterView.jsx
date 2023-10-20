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
import {func, bool} from 'prop-types'
import {IconMoreSolid} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('gradebook')

export default class StudentColumnHeader extends React.Component {
  static propTypes = {
    showInactiveEnrollments: bool.isRequired,
    showConcludedEnrollments: bool.isRequired,
    showUnassessedStudents: bool.isRequired,
    toggleInactiveEnrollments: func.isRequired,
    toggleConcludedEnrollments: func.isRequired,
    toggleUnassessedStudents: func.isRequired,
  }

  toggleInactiveEnrollments = (_e, _menuItem, newValue) => {
    this.props.toggleInactiveEnrollments(newValue)
  }

  toggleConcludedEnrollments = (_e, _menuItem, newValue) => {
    this.props.toggleConcludedEnrollments(newValue)
  }

  toggleUnassessedStudents = (_e, _menuItem, newValue) => {
    this.props.toggleUnassessedStudents(newValue)
  }

  render() {
    return (
      <View textAlign="end">
        <Flex id="learning-mastery-gradebook-filter">
          <Flex.Item shouldGrow={true}>
            <Text weight="bold" id="lmgb-student-filter-title">
              {I18n.t('Students')}
            </Text>
          </Flex.Item>
          <Flex.Item shouldShrink={true} id="lmgb-student-filter-trigger">
            <Menu
              placement="bottom end"
              withArrow={true}
              shouldHideOnSelect={true}
              trigger={
                <IconButton
                  data-component="lmgb-student-filter-trigger"
                  renderIcon={IconMoreSolid}
                  withBackground={false}
                  withBorder={false}
                  size="medium"
                  screenReaderLabel={I18n.t('Display Student Filter Options')}
                />
              }
            >
              <Menu.Group
                allowMultiple={true}
                label={I18n.t('Show')}
                id="learning-mastery-gradebook-dropdown"
              >
                <Menu.Item
                  value="display_inactive_enrollments"
                  data-component="lmgb-student-filter-inactive-enrollments"
                  selected={this.props.showInactiveEnrollments}
                  onSelect={this.toggleInactiveEnrollments}
                >
                  {I18n.t('Inactive enrollments')}
                </Menu.Item>
                <Menu.Item
                  value="display_concluded_enrollments"
                  data-component="lmgb-student-filter-concluded-enrollments"
                  selected={this.props.showConcludedEnrollments}
                  onSelect={this.toggleConcludedEnrollments}
                >
                  {I18n.t('Concluded enrollments')}
                </Menu.Item>
                <Menu.Item
                  value="no_results_students"
                  data-component="lmgb-student-filter-unassessed-students"
                  selected={this.props.showUnassessedStudents}
                  onSelect={this.toggleUnassessedStudents}
                >
                  {I18n.t('Unassessed students')}
                </Menu.Item>
              </Menu.Group>
            </Menu>
          </Flex.Item>
        </Flex>
      </View>
    )
  }
}
