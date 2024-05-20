/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconArrowOpenDownLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import {CELL_HEIGHT, STUDENT_COLUMN_WIDTH} from './constants'
import PropTypes from 'prop-types'

const I18n = useI18nScope('learning_mastery_gradebook')

const StudentHeader = ({gradebookFilters, gradebookFilterHandler}) => {
  const toggleStudentsWithoutAssessments = () => gradebookFilterHandler('missing_user_rollups')
  const toggleInactiveEnrollments = () => gradebookFilterHandler('inactive_enrollments')
  const toggleConcludedEnrollments = () => gradebookFilterHandler('concluded_enrollments')

  return (
    <View background="secondary" as="div" width={STUDENT_COLUMN_WIDTH}>
      <Flex alignItems="center" justifyItems="space-between" height={CELL_HEIGHT}>
        <Flex.Item padding="0 0 0 small">
          <Text weight="bold">{I18n.t('Students')}</Text>
        </Flex.Item>
        <Flex.Item padding="0 small 0 0">
          <Menu
            placement="bottom"
            trigger={
              <IconButton
                withBorder={false}
                withBackground={false}
                size="small"
                screenReaderLabel={I18n.t('Sort Students')}
              >
                <IconArrowOpenDownLine />
              </IconButton>
            }
          >
            <Menu.Item>{I18n.t('Sort By')}</Menu.Item>
            <Menu.Item>{I18n.t('Display as')}</Menu.Item>
            <Menu.Item>{I18n.t('Secondary info')}</Menu.Item>
            <Menu.Group label={I18n.t('Show')} allowMultiple={true}>
              <Menu.Item
                selected={!gradebookFilters.includes('missing_user_rollups')}
                onSelect={toggleStudentsWithoutAssessments}
              >
                {I18n.t('Students without assessments')}
              </Menu.Item>
              <Menu.Item
                selected={!gradebookFilters.includes('inactive_enrollments')}
                onSelect={toggleInactiveEnrollments}
              >
                {I18n.t('Inactive Enrollments')}
              </Menu.Item>
              <Menu.Item
                selected={!gradebookFilters.includes('concluded_enrollments')}
                onSelect={toggleConcludedEnrollments}
              >
                {I18n.t('Concluded Enrollments')}
              </Menu.Item>
            </Menu.Group>
          </Menu>
        </Flex.Item>
      </Flex>
    </View>
  )
}

StudentHeader.propTypes = {
  gradebookFilters: PropTypes.arrayOf(PropTypes.string).isRequired,
  gradebookFilterHandler: PropTypes.func.isRequired,
}

export default StudentHeader
