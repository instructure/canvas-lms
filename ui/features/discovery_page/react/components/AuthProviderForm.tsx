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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {IconButton} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as createI18nScope} from '@canvas/i18n'
import {getDiscoveryPageIcons} from '../constants'
import {useDiscovery} from '../hooks/useDiscovery'
import {SelectedBadge} from './SelectedBadge'

const I18n = createI18nScope('discovery_page')

interface AuthProviderFormProps {
  loginLabel: string
  selectedProviderId: string
  onLoginChange: (value: string) => void
  onProviderChange: (value: string) => void
  selectedIconId: string
  onIconSelect: (iconId: string) => void
}

function assignForwardedRef<T>(ref: React.ForwardedRef<T>, value: T | null) {
  if (typeof ref === 'function') {
    ref(value)
    return
  }

  if (ref) {
    ref.current = value
  }
}

export const AuthProviderForm = React.forwardRef<HTMLDivElement, AuthProviderFormProps>(
  function AuthProviderForm(
    {loginLabel, selectedProviderId, onLoginChange, onProviderChange, selectedIconId, onIconSelect},
    ref,
  ) {
    const {authProviders} = useDiscovery()

    const elementRef = React.useCallback(
      (el: HTMLElement | null) => {
        assignForwardedRef(ref, el as HTMLDivElement | null)
      },
      [ref],
    )

    return (
      <View display="block" padding="small" elementRef={elementRef}>
        <Flex as="div" gap="small" direction="column">
          <TextInput
            onChange={(_, value) => {
              onLoginChange(value)
            }}
            placeholder={I18n.t('User login')}
            renderLabel={I18n.t('Label')}
            value={loginLabel}
          />

          <SimpleSelect
            onChange={(_, {value}) => {
              if (typeof value === 'string') {
                onProviderChange(value)
              }
            }}
            renderLabel={I18n.t('Select Authentication Provider')}
            value={selectedProviderId}
          >
            {authProviders?.map(provider => (
              <SimpleSelect.Option
                key={provider.id}
                id={`provider-${provider.id}`}
                value={provider.id}
              >
                {provider.url}
              </SimpleSelect.Option>
            ))}
          </SimpleSelect>
          <Flex as="div" gap="small" direction="column">
            <Text weight="bold">{I18n.t('Icon')}</Text>

            <Flex as="div" gap="xx-small" wrap="wrap" role="radiogroup" aria-label={I18n.t('Icon')}>
              {getDiscoveryPageIcons().map(icon => {
                const isSelected = selectedIconId === icon.id

                return (
                  <span key={icon.id} style={{position: 'relative', display: 'inline-flex'}}>
                    <Tooltip renderTip={icon.name}>
                      <IconButton
                        renderIcon={
                          <img src={icon.url} alt="" style={{width: '24px', height: '24px'}} />
                        }
                        screenReaderLabel={`${icon.name}${isSelected ? I18n.t(' (selected)') : ''}`}
                        color="secondary"
                        onClick={() => onIconSelect(icon.id)}
                        size="medium"
                        aria-pressed={isSelected}
                      />
                    </Tooltip>

                    {isSelected && <SelectedBadge />}
                  </span>
                )
              })}
            </Flex>
          </Flex>
        </Flex>
      </View>
    )
  },
)

// ensures a readable component name in React DevTools and
// error stacks because forwardRef wraps the component
AuthProviderForm.displayName = 'AuthProviderForm'
