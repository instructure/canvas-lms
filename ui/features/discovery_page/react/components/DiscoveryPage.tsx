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

import {type ChangeEvent, useState} from 'react'
import {Button} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Checkbox} from '@instructure/ui-checkbox'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'
import {useHashState} from '../hooks/useHashState'
import {ConfigureModal} from './ConfigureModal'
import type {DiscoveryPageProps} from '../types'

const I18n = createI18nScope('discovery_page')
const MODAL_HASH = '#discovery_config'

export function DiscoveryPage({initialEnabled, onChange}: DiscoveryPageProps) {
  const [isEnabled, setIsEnabled] = useState(initialEnabled)
  const [modalOpen, setModalOpen] = useHashState(MODAL_HASH)

  const handleToggle = (event: ChangeEvent<HTMLInputElement>) => {
    const newValue = event.target.checked
    setIsEnabled(newValue)
    onChange(newValue)
  }

  return (
    <View as="div" data-testid="discovery-page">
      <Flex as="div" direction="row" alignItems="center" gap="small">
        <Flex.Item>
          <Button onClick={() => setModalOpen(true)} margin="0" data-testid="configure-button">
            {I18n.t('Configure')}
          </Button>
        </Flex.Item>

        <Flex.Item>
          <FormFieldGroup
            description={<ScreenReaderContent>{I18n.t('Use discovery page')}</ScreenReaderContent>}
          >
            <Checkbox
              checked={isEnabled}
              data-testid="discovery-page-toggle"
              label={I18n.t('Use discovery page')}
              labelPlacement="end"
              onChange={handleToggle}
              variant="toggle"
            />
          </FormFieldGroup>
        </Flex.Item>
      </Flex>

      <ConfigureModal open={modalOpen} onClose={() => setModalOpen(false)} />
    </View>
  )
}
