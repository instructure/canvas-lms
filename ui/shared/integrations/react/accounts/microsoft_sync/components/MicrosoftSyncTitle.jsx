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

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'

const I18n = useI18nScope('account_settings_jsx_bundle')

export default function MicrosoftSyncTitle(props) {
  return (
    <Flex margin="auto small" justifyItems="space-between">
      <Flex.Item shouldShrink={true}>
        <Heading value="h2">{I18n.t('Microsoft Teams Sync')}</Heading>
      </Flex.Item>
      <Flex.Item>
        <Checkbox
          size="medium"
          variant="toggle"
          id="microsoft_teams_sync_toggle_button"
          checked={props.syncEnabled}
          label={
            <ScreenReaderContent>
              {I18n.t('Allows syncing of Canvas course members to a Microsoft Team')}
            </ScreenReaderContent>
          }
          labelPlacement="start"
          onChange={props.handleClick}
          disabled={props.interactionDisabled}
        />
      </Flex.Item>
    </Flex>
  )
}

MicrosoftSyncTitle.propTypes = {
  syncEnabled: PropTypes.bool,
  interactionDisabled: PropTypes.bool,
  handleClick: PropTypes.func,
}
