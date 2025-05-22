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
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconRefreshLine} from '@instructure/ui-icons'
import {Alert} from '@instructure/ui-alerts'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('context_modulespublic')

type FetchErrorProps = {
  retryCallback: () => void
}

export const FetchError = ({retryCallback}: FetchErrorProps) => {
  return (
    <Alert variant="error" data-testid="items-failed-to-load">
      <Flex justifyItems="space-between">
        {I18n.t('Items failed to load')}
        <IconButton
          data-testid="retry-items-failed-to-load"
          screenReaderLabel={I18n.t('Retry')}
          withBackground={false}
          withBorder={false}
          onClick={retryCallback}
        >
          <IconRefreshLine />
        </IconButton>
      </Flex>
    </Alert>
  )
}
