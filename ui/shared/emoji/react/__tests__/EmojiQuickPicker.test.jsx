// @vitest-environment jsdom
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
import React from 'react'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import EmojiQuickPicker from '../EmojiQuickPicker'
import {store} from 'emoji-mart'

describe('EmojiQuickPicker', () => {
  let insertEmoji

  beforeEach(() => {
    insertEmoji = jest.fn()
  })

  afterEach(() => {
    localStorage.clear()
  })

  it('renders 👍, 👏, and 😀 by default', () => {
    const {getByRole} = render(<EmojiQuickPicker insertEmoji={insertEmoji} />)
    expect(getByRole('button', {name: /👍, \+1, thumbsup/})).toBeInTheDocument()
    expect(getByRole('button', {name: /👏, clap/})).toBeInTheDocument()
    expect(getByRole('button', {name: /😀, grinning/})).toBeInTheDocument()
  })

  it('renders the last used emoji stored in localStorage', () => {
    store.set('last', 'kissing_heart')
    const {getByRole} = render(<EmojiQuickPicker insertEmoji={insertEmoji} />)
    expect(getByRole('button', {name: /😘, kissing_heart/})).toBeInTheDocument()
  })

  it('calls insertEmoji with the emoji that is clicked', async () => {
    store.set('last', 'kissing_heart')
    const {getByRole} = render(<EmojiQuickPicker insertEmoji={insertEmoji} />)
    await userEvent.click(getByRole('button', {name: /😘, kissing_heart/}))
    expect(insertEmoji).toHaveBeenCalledWith(
      expect.objectContaining({id: 'kissing_heart', native: '😘'})
    )
  })

  it('renders the two most used emojis (counts stored in localStorage)', () => {
    store.set('frequently', {wink: 44, sweat_smile: 14, blush: 29})
    const {getByRole, queryByRole} = render(<EmojiQuickPicker insertEmoji={insertEmoji} />)
    expect(getByRole('button', {name: /😉, wink/})).toBeInTheDocument()
    expect(getByRole('button', {name: /😊, blush/})).toBeInTheDocument()
    expect(queryByRole('button', {name: /😅, sweat_smile/})).not.toBeInTheDocument()
  })

  it('does not render an emoji twice if it was last used and is most used', () => {
    store.set('last', 'wink')
    store.set('frequently', {wink: 44, sweat_smile: 14, blush: 29, grinning: 21})
    const {getByRole, queryByRole} = render(<EmojiQuickPicker insertEmoji={insertEmoji} />)
    expect(getByRole('button', {name: /😉, wink/})).toBeInTheDocument()
    expect(getByRole('button', {name: /😊, blush/})).toBeInTheDocument()
    expect(getByRole('button', {name: /😀, grinning/})).toBeInTheDocument()
    expect(queryByRole('button', {name: /😅, sweat_smile/})).not.toBeInTheDocument()
  })

  it('updates emoji skin tone accordingly when an "emojiSkinChange" event is triggered', () => {
    const {getByRole} = render(<EmojiQuickPicker insertEmoji={insertEmoji} />)
    const event = new CustomEvent('emojiSkinChange', {detail: 5})
    window.dispatchEvent(event)
    expect(getByRole('button', {name: /👍🏾, \+1, thumbsup/})).toBeInTheDocument()
    expect(getByRole('button', {name: /👏🏾, clap/})).toBeInTheDocument()
  })

  it('updates the most recent emoji accordingly when an "emojiSelected" event is triggered', () => {
    store.set('last', 'wink')
    store.set('frequently', {wink: 5, sweat_smile: 1, blush: 4, grinning: 3})
    const {getByRole, queryByRole} = render(<EmojiQuickPicker insertEmoji={insertEmoji} />)
    const event = new CustomEvent('emojiSelected', {detail: 'sweat_smile'})
    window.dispatchEvent(event)
    expect(getByRole('button', {name: /😉, wink/})).toBeInTheDocument()
    expect(getByRole('button', {name: /😊, blush/})).toBeInTheDocument()
    expect(getByRole('button', {name: /😅, sweat_smile/})).toBeInTheDocument()
    expect(queryByRole('button', {name: /😀, grinning/})).not.toBeInTheDocument()
  })
})
