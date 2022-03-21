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
import {Text} from '@instructure/ui-text'
import {Img} from '@instructure/ui-img'

import EmptyDashPandaUrl from '../images/empty-dashboard.svg'

const I18n = useI18nScope('k5_empty_dashboard_state')

const EmptyDashboardState = () => (
  <Flex
    as="div"
    height="50vh"
    direction="column"
    alignItems="center"
    justifyItems="center"
    margin="x-large large"
  >
    <Img src={EmptyDashPandaUrl} margin="0 0 medium 0" data-testid="empty-dash-panda" />
    <Text>{I18n.t("You don't have any active courses yet.")}</Text>
  </Flex>
)

export default EmptyDashboardState
