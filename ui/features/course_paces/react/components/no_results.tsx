// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'

import {useScope as useI18nScope} from '@canvas/i18n'
import SpacePandaUrl from '@canvas/images/SpacePanda.svg'

const I18n = useI18nScope('course_paces_no_results')

const NoResults = () => (
  <Flex direction="column" alignItems="center" justifyItems="center" padding="xx-large medium">
    <Flex.Item margin="0 0 medium">
      <Img src={SpacePandaUrl} />
    </Flex.Item>
    <Flex.Item>
      <Text size="x-large">{I18n.t('No results found')}</Text>
    </Flex.Item>
    <Flex.Item>
      <Text>{I18n.t('Please try another search term')}</Text>
    </Flex.Item>
  </Flex>
)

export default NoResults
