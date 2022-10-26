/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Tag} from '@instructure/ui-tag'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {EmojiPicker} from '@canvas/emoji'
import {Emoji} from 'emoji-mart'
import data from 'emoji-mart/data/all.json'

const I18n = useI18nScope('i18n!custom_emoji_deny_list')

export default function CustomEmojiDenyList() {
  const [blockedEmojis, setBlockedEmojis] = useState(
    ENV.EMOJI_DENY_LIST
      ? ENV.EMOJI_DENY_LIST.split(',').map(id => ({name: data.emojis[id].name, id}))
      : []
  )

  const removeEmoji = id => setBlockedEmojis(blockedEmojis.filter(emoji => emoji.id !== id))
  return (
    <fieldset>
      <h2 className="screenreader-only">{I18n.t('Blocked Emojis')}</h2>
      <legend id="blocked-emojis">{I18n.t('Blocked Emojis')}</legend>
      <p>
        {I18n.t(
          'Selected emojis will not be available in the "Emoji Picker" for students or instructors.'
        )}
      </p>
      <View
        as="div"
        borderRadius="medium"
        borderWidth="small"
        display="inline-block"
        width="23.4rem"
        minHeight="5.2rem"
        shadow="above"
      >
        <div id="emoji-tags">
          {blockedEmojis.map(emoji => (
            <Tag
              text={
                <AccessibleContent
                  alt={`${I18n.t('Remove emoji "%{emojiName}"', {emojiName: emoji.name})}`}
                >
                  <div className="emoji-tag">
                    <Emoji emoji={emoji.id} size={20} />
                  </div>
                </AccessibleContent>
              }
              dismissible={true}
              margin="xx-small"
              onClick={() => removeEmoji(emoji.id)}
              key={`emoji-${emoji.id}`}
            />
          ))}
        </div>
      </View>
      <EmojiPicker
        autoFocus={false}
        excludedCategories={['recent']}
        excludedEmojis={blockedEmojis.map(emoji => emoji.id)}
        insertEmoji={({id, name}) => {
          setBlockedEmojis([...blockedEmojis, {id, name}])
        }}
        showSkinTones={false}
        skin={1}
        opaque={true}
      />
      <input
        data-testid="account-settings-emoji-deny-list"
        type="hidden"
        name="account[settings][emoji_deny_list]"
        value={blockedEmojis.map(emoji => emoji.id).join(',')}
      />
    </fieldset>
  )
}
