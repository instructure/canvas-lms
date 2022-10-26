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
import {Emoji, Picker} from 'emoji-mart'
import {IconButton} from '@instructure/ui-buttons'
import {Popover} from '@instructure/ui-popover'

const I18n = useI18nScope('i18n!emoji')

export default function EmojiPicker(props) {
  const [showPicker, setShowPicker] = useState(false)
  const i18n = {
    search: I18n.t('Search'),
    clear: I18n.t('Clear'),
    notfound: I18n.t('No Emoji Found'),
    skintext: I18n.t('Choose your default skin tone'),
    categories: {
      search: I18n.t('Search Results'),
      recent: I18n.t('Frequently Used'),
      smileys: I18n.t('Smileys & Emotion'),
      people: I18n.t('People & Body'),
      nature: I18n.t('Animals & Nature'),
      foods: I18n.t('Food & Drink'),
      activity: I18n.t('Activity'),
      places: I18n.t('Travel & Places'),
      objects: I18n.t('Objects'),
      symbols: I18n.t('Symbols'),
      flags: I18n.t('Flags'),
      custom: I18n.t('Custom'),
    },
    categorieslabel: I18n.t('Emoji categories'),
    skintones: {
      1: I18n.t('Default Skin Tone'),
      2: I18n.t('Light Skin Tone'),
      3: I18n.t('Medium-Light Skin Tone'),
      4: I18n.t('Medium Skin Tone'),
      5: I18n.t('Medium-Dark Skin Tone'),
      6: I18n.t('Dark Skin Tone'),
    },
  }

  const defaultExcludedEmojis = [
    'axe',
    'banana',
    'beer',
    'beers',
    'bikini',
    'bomb',
    'breast-feeding',
    'bow_and_arrow',
    'camel',
    'cancer',
    'carrot',
    'champagne',
    'cherries',
    'clinking_glasses',
    'cocktail',
    'coffin',
    'crossed_swords',
    'dagger_knife',
    'dromedary_camel',
    'drop_of_blood',
    'eggplant',
    'firecracker',
    'fortune_cookie',
    'funeral_urn',
    'gun',
    'hocho',
    'hotdog',
    'kiss',
    'lollipop',
    'middle_finger',
    'ok_hand',
    'peach',
    'peanuts',
    'point_left',
    'point_right',
    'sake',
    'smoking',
    'sushi',
    'sweat_drops',
    'syringe',
    'taco',
    'tongue',
    'tropical_drink',
    'tumbler_glass',
    'v',
    'wine_glass',
  ]

  const accountExcludedEmojis = ENV.EMOJI_DENY_LIST ? ENV.EMOJI_DENY_LIST.split(',') : []
  const excludedEmojis = [
    ...defaultExcludedEmojis,
    ...(props.excludedEmojis.length ? props.excludedEmojis : accountExcludedEmojis),
  ]

  const closeAndInsertEmoji = emoji => {
    setShowPicker(false)
    props.insertEmoji(emoji)
    const event = new CustomEvent('emojiSelected', {detail: emoji.id})
    window.dispatchEvent(event)
  }

  const emitSkinChangeEvent = skin => {
    const event = new CustomEvent('emojiSkinChange', {detail: skin})
    window.dispatchEvent(event)
  }

  const trigger = (
    <span className={`emoji-trigger${props.opaque ? ' opaque' : ''}`}>
      <IconButton
        margin="0 xx-small xx-small xx-small"
        shape="circle"
        screenReaderLabel={I18n.t('Open emoji menu')}
        size="small"
        withBackground={false}
        withBorder={false}
      >
        <Emoji emoji="grinning" size={26} />
      </IconButton>
    </span>
  )

  return (
    <Popover
      renderTrigger={trigger}
      isShowingContent={showPicker}
      on="click"
      onShowContent={() => setShowPicker(true)}
      onHideContent={() => setShowPicker(false)}
      placement={window.matchMedia('(max-width: 415px)').matches ? 'top' : 'start'}
      screenReaderLabel={I18n.t('Emoji picker')}
      shouldContainFocus={true}
      shouldReturnFocus={true}
      shouldCloseOnDocumentClick={true}
    >
      <span className="emoji-picker">
        <Picker
          autoFocus={props.autoFocus}
          emoji="point_up"
          emojisToShowFilter={emoji => !excludedEmojis.includes(emoji.short_names[0])}
          exclude={props.excludedCategories}
          i18n={i18n}
          onSelect={closeAndInsertEmoji}
          onSkinChange={emitSkinChangeEvent}
          style={{border: 'none'}}
          title={I18n.t('Pick an emoji...')}
          showSkinTones={props.showSkinTones}
          skin={props.skin || undefined}
          showPreview={true}
        />
      </span>
    </Popover>
  )
}

EmojiPicker.defaultProps = {
  autoFocus: true,
  excludedCategories: [],
  excludedEmojis: [],
  opaque: false,
  showSkinTones: true,
  skin: null,
}
