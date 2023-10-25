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
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Pill} from '@instructure/ui-pill'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('NewTabIndicator')

type Props = {
  tabName: string
}

const NewTabIndicator = ({tabName}: Props) => {
  const currentUserId = window.ENV.current_user_id
  const visitedTabs = window.ENV.current_user_visited_tabs || []
  return currentUserId != null && !visitedTabs.includes(tabName) ? (
    <AccessibleContent alt={I18n.t('New Tab')}>
      <Pill color="info" margin="0 0 0 xx-small">
        {I18n.t('New')}
      </Pill>
    </AccessibleContent>
  ) : null
}

export default NewTabIndicator
