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
import React, {useEffect, useState} from 'react'
import {Emoji, frequently, store} from 'emoji-mart'
import {View} from '@instructure/ui-view'

const quickbarEmojis = (lastEmoji, emojiFrequencies) => {
  if (!lastEmoji || !emojiFrequencies) return []

  let most, nextMost
  for (const emoji in emojiFrequencies) {
    const uses = emojiFrequencies[emoji]
    if (emoji === lastEmoji) {
      continue
    } else if (!most) {
      most = emoji
    } else if (uses > emojiFrequencies[most]) {
      nextMost = most
      most = emoji
    } else if (!nextMost) {
      nextMost = emoji
    } else if (uses > emojiFrequencies[nextMost]) {
      nextMost = emoji
    }
  }

  const emojis = [lastEmoji]
  if (most) emojis.push(most)
  if (nextMost) emojis.push(nextMost)
  return emojis.sort()
}

export default function EmojiQuickPicker(props) {
  const [mostFrequent, setMostFrequent] = useState(store.get('frequently'))
  const [last, setLast] = useState(store.get('last'))
  const [skinTone, setSkinTone] = useState(store.get('skin') || 1)
  const handleEmojiSelected = event => {
    const emojiName = event.detail
    setMostFrequent(prevState => {
      const uses = (prevState[emojiName] || 0) + 1
      return {...prevState, [emojiName]: uses}
    })
    setLast(emojiName)
  }

  useEffect(() => {
    const handleSkinToneChange = event => setSkinTone(event.detail)
    window.addEventListener('emojiSkinChange', handleSkinToneChange)
    window.addEventListener('emojiSelected', handleEmojiSelected)

    if (!store.get('frequently')) {
      store.set('frequently', {'+1': 1, clap: 1, grinning: 1})
      setMostFrequent(store.get('frequently'))
    }

    if (!store.get('last')) {
      store.set('last', '+1')
      setLast(store.get('last'))
    }

    return () => window.removeEventListener('emojiSkinChange', handleSkinToneChange)
  }, [])

  const incrementAndInsertEmoji = emoji => {
    frequently.add(emoji)
    props.insertEmoji(emoji)
    handleEmojiSelected({detail: emoji.id})
  }

  return (
    <span className="emoji-quick-picker">
      {quickbarEmojis(last, mostFrequent).map(emoji => (
        <View key={emoji} height="20px" cursor="pointer" margin="0 xx-small">
          <Emoji emoji={emoji} onClick={incrementAndInsertEmoji} size={20} skin={skinTone} />
        </View>
      ))}
    </span>
  )
}
