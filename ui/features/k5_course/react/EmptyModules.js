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

import EmptyModulesUrl from '../images/empty-modules.svg'

const I18n = useI18nScope('empty_modules')

const EmptyModules = () => (
  <Flex
    as="div"
    direction="column"
    height="50vh"
    alignItems="center"
    justifyItems="center"
    textAlign="center"
    margin="medium"
  >
    <Img src={EmptyModulesUrl} margin="0 0 medium 0" data-testid="empty-modules-panda" />
    <Text size="large">{I18n.t("Your modules will appear here after they're assembled.")}</Text>
  </Flex>
)

export default EmptyModules
