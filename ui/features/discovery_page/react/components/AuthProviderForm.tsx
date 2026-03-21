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

import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {IconButton} from '@instructure/ui-buttons'
import {Img} from '@instructure/ui-img'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconUnpublishedLine} from '@instructure/ui-icons'
import {DISCOVERY_PAGE_ICONS} from '../constants'
import {SelectedBadge} from './SelectedBadge'
import type {AuthProviderFormProps} from '../types'

const I18n = createI18nScope('discovery_page')

export function AuthProviderForm({
  authProviders,
  loginLabel,
  selectedProviderId,
  onLoginChange,
  onProviderChange,
  selectedIconId,
  onIconSelect,
  errors,
  onLabelRef,
  onProviderRef,
}: AuthProviderFormProps) {
  const labelMessages = errors?.label ? [{type: 'error' as const, text: errors.label}] : []
  const providerMessages = errors?.providerId
    ? [{type: 'error' as const, text: errors.providerId}]
    : [
        {
          type: 'hint' as const,
          text: I18n.t('Users will be redirected to this provider to complete sign-in.'),
        },
      ]

  return (
    <View display="block">
      <Flex as="div" gap="small" direction="column">
        <TextInput
          onChange={(_, value) => {
            onLoginChange(value)
          }}
          placeholder={I18n.t('User login')}
          renderLabel={I18n.t('Login Button Text')}
          value={loginLabel}
          maxLength={255}
          messages={labelMessages}
          inputRef={onLabelRef}
        />

        <SimpleSelect
          onChange={(_, {value}) => {
            if (typeof value === 'string') {
              onProviderChange(value)
            }
          }}
          renderLabel={I18n.t('Select Authentication Provider')}
          value={selectedProviderId}
          messages={providerMessages}
          inputRef={onProviderRef as (el: Element | null) => void}
        >
          <SimpleSelect.Option id="provider-none" value="">
            {I18n.t('Select a provider...')}
          </SimpleSelect.Option>

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
          <Text weight="bold">{I18n.t('Button Icon')}</Text>

          <Flex as="div" gap="xx-small" wrap="wrap" role="radiogroup" aria-label={I18n.t('Icon')}>
            <span style={{position: 'relative', display: 'inline-flex'}}>
              <Tooltip renderTip={I18n.t('No icon')}>
                <IconButton
                  renderIcon={<IconUnpublishedLine />}
                  screenReaderLabel={`${I18n.t('No icon')}${selectedIconId === '' ? I18n.t(' (selected)') : ''}`}
                  color="secondary"
                  onClick={() => onIconSelect('')}
                  size="medium"
                  aria-pressed={selectedIconId === ''}
                />
              </Tooltip>

              {selectedIconId === '' && <SelectedBadge />}
            </span>

            {DISCOVERY_PAGE_ICONS.map(icon => {
              const isSelected = selectedIconId === icon.id

              return (
                <span key={icon.id} style={{position: 'relative', display: 'inline-flex'}}>
                  <Tooltip renderTip={icon.name}>
                    <IconButton
                      renderIcon={<Img src={icon.url} alt="" width="24px" height="24px" />}
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
}
