/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {Text} from '@instructure/ui-text'
import TruncateWithTooltip from '@canvas/lti-apps/components/common/TruncateWithTooltip'
import {LtiLaunchDefinition} from '@canvas/select-content-dialog/jquery/select_content_dialog'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('asset_processors_selection')

type ToolContextNameProps = {
  tool?: LtiLaunchDefinition
}

export function ToolContextName({tool}: ToolContextNameProps) {
  if (!tool?.context_name) {
    return null
  }

  return (
    <TruncateWithTooltip linesAllowed={2} horizontalOffset={0} backgroundColor="primary-inverse">
      <Text size="medium">
        {I18n.t('Installed in: %{contextName}', {contextName: tool.context_name})}
      </Text>
    </TruncateWithTooltip>
  )
}
