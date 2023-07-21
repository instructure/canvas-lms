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
import {useScope as useI18nScope} from '@canvas/i18n'

import {Flex} from '@instructure/ui-flex'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'

import ImportantDatesPandaUrl from '../images/important-dates.svg'

const I18n = useI18nScope('important_dates_empty')

const ImportantDatesEmpty = () => (
  <Flex as="div" direction="column" alignItems="center" textAlign="center" margin="large 0">
    <Img src={ImportantDatesPandaUrl} margin="0 0 medium 0" data-testid="important-dates-panda" />
    <Text size="small">{I18n.t('Waiting for important things to happen.')}</Text>
  </Flex>
)

export default ImportantDatesEmpty
