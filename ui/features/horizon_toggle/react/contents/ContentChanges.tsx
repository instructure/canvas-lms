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
import {IconInfoLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {Assignments} from './Assignments'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ContentPublished} from './ContentPublished'

const I18n = createI18nScope('horizon_toggle_page')

export const ContentChanges = () => {
  return (
    <View as="div">
      <Flex gap="x-small">
        <IconInfoLine size="x-small" />
        <Heading level="h3">{I18n.t('Changes to Course Content')}</Heading>
      </Flex>
      <Text as="p">
        {I18n.t(
          'In order to convert your course to Canvas Career, the following changes will be made to existing course content.',
        )}
      </Text>
      <Flex gap="small" direction="column">
        <ContentPublished />
        <Assignments />
      </Flex>
    </View>
  )
}
