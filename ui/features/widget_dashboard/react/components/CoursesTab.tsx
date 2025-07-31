/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('widget_dashboard')

const CoursesTab: React.FC = () => {
  return (
    <View as="div" padding="medium" data-testid="courses-tab-content">
      <Heading level="h2" margin="0 0 medium" data-testid="courses-tab-heading">
        {I18n.t('Courses')}
      </Heading>
      <Text>
        {I18n.t(
          'Here you can view and navigate to your enrolled courses. Quick access to course materials, assignments, and announcements.',
        )}
      </Text>
      <View as="div" margin="medium 0 0">
        <Text size="small" color="secondary">
          {I18n.t('Course navigation and quick access features coming soon.')}
        </Text>
      </View>
    </View>
  )
}

export default CoursesTab
