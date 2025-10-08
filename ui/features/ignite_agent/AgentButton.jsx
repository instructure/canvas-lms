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

import {useScope as createI18nScope} from '@canvas/i18n'
const I18n = createI18nScope('QRMobileLogin')

import {View} from '@instructure/ui-view'
import {IconButton} from '@instructure/ui-buttons'
import {IconAiSolid} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'

import React from 'react'

/**
 * A button component for the Ignite Agent that shows a loading state.
 * @param {object} props - The component props.
 * @param {Function} props.onClick - The function to execute when the button is clicked.
 * @param {boolean} [props.isLoading=false] - If true, shows a spinner and disables the button.
 */
export function AgentButton({onClick, isLoading = false}) {
  return (
    <View display="inline-block" shadow="above" borderRadius="circle">
      <IconButton
        onClick={onClick}
        screenReaderLabel={isLoading ? I18n.t('Loading IgniteAI') : 'IgniteAI'}
        renderIcon={() =>
          isLoading ? <Spinner renderTitle={'Agent is loading'} /> : <IconAiSolid />
        }
        color="ai-primary"
        shape="circle"
        size="large"
        withBackground
        disabled={isLoading} // Disable the button while in the loading state
      />
    </View>
  )
}
