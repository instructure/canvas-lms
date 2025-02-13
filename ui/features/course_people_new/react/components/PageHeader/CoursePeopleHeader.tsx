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

import React, {FC} from 'react'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import CoursePeopleOptionsMenu from './CoursePeopleOptionsMenu'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('course_people')

const CoursePeopleHeader: FC = () => (
  <Flex justifyItems="space-between" width="100%">
    <Flex.Item as="div">
      <Heading data-testid="course-people-header" level="h1">
        {I18n.t('People')}
      </Heading>
    </Flex.Item>
    <Flex.Item as="div">
      <CoursePeopleOptionsMenu />
    </Flex.Item>
  </Flex>
)

export default CoursePeopleHeader
