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

import React, {Fragment} from 'react'
import List, {ListItem} from '@instructure/ui-elements/lib/components/List'
import Text from '@instructure/ui-elements/lib/components/Text'
import View from '@instructure/ui-layout/lib/components/View'
import I18n from 'i18n!hide_assignment_grades_tray'

export default function Description() {
  return (
    <Fragment>
      <View as="p" margin="0 0 small">
        <Text>
          {I18n.t(`
            While the grades for this assignment are hidden, students will not
            receive new notifications about or be able to see:
          `)}
        </Text>
      </View>

      <View as="div" margin="0 0 small">
        <List>
          <ListItem>{I18n.t('Their grade for the assignment')}</ListItem>
          <ListItem>{I18n.t('Grade change notifications')}</ListItem>
          <ListItem>{I18n.t('Submission comments')}</ListItem>
          <ListItem>{I18n.t('Curving assignments')}</ListItem>
          <ListItem>{I18n.t('Score change notifications')}</ListItem>
        </List>
      </View>

      <View as="p" margin="0 0 small">
        <Text>
          {I18n.t(`
            Students will be able to see that the grades for this assignment
            are hidden.
          `)}
        </Text>
      </View>

      <View as="p">
        <Text>
          {I18n.t(`
            You can begin sending notifications again by clicking the Post
            Grades link.
          `)}
        </Text>
      </View>
    </Fragment>
  )
}
