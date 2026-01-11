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

import React, {useState} from 'react'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Checkbox} from '@instructure/ui-checkbox'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'

interface NativeDiscoveryPageProps {
  initialEnabled: boolean
  onChange: (enabled: boolean) => void
}

export function NativeDiscoveryPage({initialEnabled, onChange}: NativeDiscoveryPageProps) {
  const [enabled, setEnabled] = useState(initialEnabled)

  const handleToggle = (event: React.ChangeEvent<HTMLInputElement>) => {
    const checked = event.target.checked
    setEnabled(checked)
    onChange(checked)
  }

  const handleConfigure = () => {
    // TODO: Open full-page modal for configuration
    alert('Configuration modal will be implemented in future work')
  }

  return (
    <View as="div" data-testid="native-discovery-page">
      <Flex as="div" direction="row" alignItems="center" gap="small">
        <Flex.Item>
          <Button onClick={handleConfigure} margin="0" data-testid="configure-button">
            Configure
          </Button>
        </Flex.Item>
        <Flex.Item>
          <FormFieldGroup
            description={
              <ScreenReaderContent>Enable Identity Service Discovery Page</ScreenReaderContent>
            }
          >
            <Checkbox
              label="Enable Identity Service Discovery Page"
              variant="toggle"
              checked={enabled}
              onChange={handleToggle}
              labelPlacement="end"
              data-testid="discovery-page-toggle"
            />
          </FormFieldGroup>
        </Flex.Item>
      </Flex>
    </View>
  )
}
