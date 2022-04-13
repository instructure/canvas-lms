/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {List} from '@instructure/ui-list'
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('hide_assignment_grades_tray')

export default function Description() {
  return (
    <>
      <View as="p" margin="0 0 small">
        <Text>
          {I18n.t(
            'While the grades for this assignment are hidden, students will not receive new notifications about or be able to see:'
          )}
        </Text>
      </View>

      <View as="div" margin="0 0 small">
        <List>
          <List.Item>{I18n.t('Their grade for the assignment')}</List.Item>
          <List.Item>{I18n.t('Grade change notifications')}</List.Item>
          <List.Item>{I18n.t('Submission comments')}</List.Item>
          <List.Item>{I18n.t('Curving assignments')}</List.Item>
          <List.Item>{I18n.t('Score change notifications')}</List.Item>
        </List>
      </View>

      <View as="p" margin="0 0 small">
        <Text>
          {I18n.t('Students will be able to see that the grades for this assignment are hidden.')}
        </Text>
      </View>

      <View as="p">
        <Text>
          {I18n.t('You can begin sending notifications again by clicking the Post Grades link.')}
        </Text>
      </View>
    </>
  )
}
