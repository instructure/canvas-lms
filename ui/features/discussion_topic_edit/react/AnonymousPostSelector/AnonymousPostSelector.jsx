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

import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useState} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Avatar} from '@instructure/ui-avatar'
import {AnonymousAvatar} from '@canvas/discussions/react/components/AnonymousAvatar/AnonymousAvatar'
import {Text} from '@instructure/ui-text'
import {Select} from '@instructure/ui-select'

const I18n = useI18nScope('discussions_posts')

const CURRENT_USER = 'current_user'

export const AnonymousPostSelector = () => {
  const [inputValue, setInputValue] = useState('Show to everyone')
  const [selectedOptionId, setSelectedOptionId] = useState('show')
  const [showOptions, setShowOptions] = useState(false)
  const [highlightedOption, setHighlightedOption] = useState(null)

  return (
    <div style={{marginBottom: '36px', marginTop: '3px'}}>
      <input name="is_anonymous_author" type="hidden" value={selectedOptionId === 'hide'} />
      <Flex>
        <Flex.Item align="start">
          {selectedOptionId === 'show' && (
            <Avatar
              name={ENV.current_user.display_name}
              src={ENV.current_user.avatar_image_url}
              margin="0"
              data-testid="current_user_avatar"
            />
          )}
          {selectedOptionId === 'hide' && <AnonymousAvatar seedString={CURRENT_USER} />}
        </Flex.Item>
        <Flex.Item
          direction="column"
          margin="0 0 0 small"
          padding="0 small 0 0"
          shouldShrink={true}
        >
          <Text weight="bold" size="medium" lineHeight="condensed">
            {selectedOptionId === 'hide' ? I18n.t('Anonymous') : ENV.current_user.display_name}
          </Text>
        </Flex.Item>
      </Flex>
      <Flex margin="small 0 0 0">
        <Select
          inputValue={inputValue}
          isShowingOptions={showOptions}
          onRequestShowOptions={() => {
            setShowOptions(true)
          }}
          onRequestHideOptions={() => {
            setShowOptions(false)
          }}
          onRequestSelectOption={(event, {id}) => {
            setShowOptions(false)
            setSelectedOptionId(id)

            if (id === 'hide') {
              setInputValue(I18n.t('Hide from everyone'))
            } else if (id === 'show') {
              setInputValue(I18n.t('Show to everyone'))
            }
          }}
          onBlur={() => {
            setHighlightedOption(null)
          }}
          onRequestHighlightOption={(event, {id}) => {
            setHighlightedOption(id)
          }}
          data-testid="anonymous_post_selector"
          data-component="anonymous_post_selector"
          renderLabel={I18n.t('Visibility selector')}
        >
          <Select.Option
            id="show"
            key="show"
            isHighlighted={highlightedOption === 'show'}
            isSelected={selectedOptionId === 'show'}
          >
            <Text>{I18n.t('Show to everyone')}</Text>
          </Select.Option>
          <Select.Option
            id="hide"
            key="hide"
            isHighlighted={highlightedOption === 'hide'}
            isSelected={selectedOptionId === 'hide'}
          >
            <Text>{I18n.t('Hide from everyone')}</Text>
          </Select.Option>
        </Select>
      </Flex>
      <Flex margin="x-small 0 0 0">
        <Text weight="normal" size="small">
          {selectedOptionId === 'show'
            ? I18n.t('Show name and profile picture')
            : I18n.t('Hide name and profile picture')}
        </Text>
      </Flex>
    </div>
  )
}
