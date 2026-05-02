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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconAiSolid} from '@instructure/ui-icons'
import {BRAND_GRADIENT, RADIUS_MD} from '../brand'

const I18n = createI18nScope('ai_experiences')

const headerStyle: React.CSSProperties = {
  backgroundImage: BRAND_GRADIENT,
  padding: `${RADIUS_MD} 1rem`,
}

interface ConversationHeaderProps {
  action?: React.ReactNode
}

const ConversationHeader: React.FC<ConversationHeaderProps> = ({action}) => (
  <div style={headerStyle}>
    <Flex alignItems="center" justifyItems="space-between">
      <Heading level="h3" margin="0" color="primary-inverse">
        <Flex as="span" alignItems="center" gap="x-small">
          <IconAiSolid />
          {I18n.t('Knowledge Chat')}
        </Flex>
      </Heading>
      {action}
    </Flex>
  </div>
)

export default ConversationHeader
