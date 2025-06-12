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

import {TroubleshootInfo} from './types'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {IconWarningSolid} from '@instructure/ui-icons'

export interface LDAPTroubleshootInfoProps {
  info: TroubleshootInfo
  error: string | null
}

const LDAPTroubleshootInfo = ({
  info: {title, description, hints},
  error,
}: LDAPTroubleshootInfoProps) => {
  return (
    <View
      as="div"
      background="secondary"
      padding="mediumSmall"
      borderRadius="medium"
      borderWidth="small"
      margin="mediumSmall 0 0 0"
    >
      <Flex direction="column" gap="small">
        <Heading level="h4">{title}</Heading>
        <Text>{description}</Text>
        <ul style={{listStyleType: 'disc', paddingLeft: '0.6rem', margin: 0}}>
          {hints.map(hint => (
            <li key={hint}>{hint}</li>
          ))}
        </ul>
        {error && (
          <div style={{display: 'flex', alignItems: 'baseline', gap: 4}}>
            <View>
              <IconWarningSolid color="error" fontSize="small" />
            </View>
            <Text
              color="danger"
              size="small"
              wrap="normal"
              data-testid="ldap-setting-test-server-error"
            >
              {error}
            </Text>
          </div>
        )}
      </Flex>
    </View>
  )
}

export default LDAPTroubleshootInfo
