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

import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconWarningLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {Discussions} from './Discussions'
import {Groups} from './Groups'
import {View} from '@instructure/ui-view'
import {Collaborations} from './Collaborations'
import {Outcomes} from './Outcomes'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Quizzes} from './Quizzes'

const I18n = createI18nScope('horizon_toggle_page')

export const ContentUnsupported = () => {
  return (
    <View as="div">
      <Flex gap="x-small">
        <IconWarningLine color="warning" size="x-small" />
        <Heading level="h3">{I18n.t('Unsupported Content')}</Heading>
      </Flex>
      <Text as="p">
        {I18n.t(
          'These content types will not be available in Canvas Career. You may modify these items to a supported format or proceed without including them. Discussions will be removed from your course. Collaborations and Outcomes will be hidden. Classic Quizzes must be converted to New Quizzes.',
        )}
      </Text>
      <Collaborations />
      <Discussions />
      <Outcomes />
      <Groups />
      <Quizzes />
    </View>
  )
}
