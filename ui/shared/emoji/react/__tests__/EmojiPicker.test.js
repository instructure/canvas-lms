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
import {within} from '@testing-library/dom'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import EmojiPicker from '../EmojiPicker'

describe.skip('EmojiPicker', () => {
  let insertEmoji
  let originalENV

  beforeEach(() => {
    originalENV = window.ENV
    window.ENV = {}
    insertEmoji = jest.fn()
  })

  afterEach(() => {
    localStorage.clear()
    window.ENV = originalENV
  })

  it('renders a button to trigger opening the menu', () => {
    const {getByRole} = render(<EmojiPicker insertEmoji={insertEmoji} />)
    expect(getByRole('button', {name: /Open emoji menu/})).toBeInTheDocument()
  })

  it('opens the menu when the trigger is clicked', () => {
    const {getByRole} = render(<EmojiPicker insertEmoji={insertEmoji} />)
    userEvent.click(getByRole('button', {name: /Open emoji menu/}))
    expect(getByRole('navigation', {name: /Emoji categories/})).toBeInTheDocument()
  })

  it('closes the menu when the trigger is clicked a second time', () => {
    const {getByRole, queryByRole} = render(<EmojiPicker insertEmoji={insertEmoji} />)
    const button = getByRole('button', {name: /Open emoji menu/})
    userEvent.click(button)
    userEvent.click(button)
    expect(queryByRole('navigation', {name: /Emoji categories/})).not.toBeInTheDocument()
  })

  it('calls insertEmoji with the emoji that is clicked in the menu', () => {
    const {getByRole} = render(<EmojiPicker insertEmoji={insertEmoji} />)
    const button = getByRole('button', {name: /Open emoji menu/})
    userEvent.click(button)

    const region = getByRole('region', {name: /People & Body/})
    const emoji = within(region).getByRole('button', {name: /😘, kissing_heart/})
    userEvent.click(emoji)
    expect(insertEmoji).toHaveBeenCalledWith(
      expect.objectContaining({id: 'kissing_heart', native: '😘'})
    )
  })

  it('keeps track of emoji use counts in localStorage', () => {
    const {getByRole} = render(<EmojiPicker insertEmoji={insertEmoji} />)
    const button = getByRole('button', {name: /Open emoji menu/})
    userEvent.click(button)

    const region = getByRole('region', {name: /People & Body/})
    const emoji = within(region).getByRole('button', {name: /😱, scream/})
    userEvent.click(emoji)
    const counts = JSON.parse(localStorage.getItem('emoji-mart.frequently'))
    expect(Object.keys(counts)).toEqual(expect.arrayContaining(['scream']))
  })

  it('emits an event when skin tone is changed', () => {
    const handleSkinToneChange = jest.fn()
    window.addEventListener('emojiSkinChange', handleSkinToneChange)
    const {getByRole} = render(<EmojiPicker insertEmoji={insertEmoji} />)
    const triggerButton = getByRole('button', {name: /Open emoji menu/})
    userEvent.click(triggerButton)
    const skinToneButton = getByRole('button', {name: /Default Skin Tone/})
    userEvent.click(skinToneButton)
    const mediumSkinToneButton = getByRole('button', {name: /Medium Skin Tone/})
    userEvent.click(mediumSkinToneButton)
    const mediumSkinToneNumber = 4
    expect(handleSkinToneChange).toHaveBeenCalledWith(
      expect.objectContaining({detail: mediumSkinToneNumber})
    )
    window.removeEventListener('emojiSkinChange', handleSkinToneChange)
  })

  it('emits an event when an emoji is selected', () => {
    const handleEmojiSelected = jest.fn()
    window.addEventListener('emojiSelected', handleEmojiSelected)
    const {getByRole} = render(<EmojiPicker insertEmoji={insertEmoji} />)
    const triggerButton = getByRole('button', {name: /Open emoji menu/})
    userEvent.click(triggerButton)
    const region = getByRole('region', {name: /People & Body/})
    const emoji = within(region).getByRole('button', {name: /😘, kissing_heart/})
    userEvent.click(emoji)
    expect(handleEmojiSelected).toHaveBeenCalledWith(
      expect.objectContaining({detail: 'kissing_heart'})
    )
    window.removeEventListener('emojiSelected', handleEmojiSelected)
  })

  it('filters certain emojis by default', () => {
    const {getByRole} = render(<EmojiPicker insertEmoji={insertEmoji} />)
    const button = getByRole('button', {name: /Open emoji menu/})
    userEvent.click(button)
    const region = getByRole('region', {name: /People & Body/})
    const emoji = within(region).queryByRole('button', {name: /🖕, middle_finger/})
    expect(emoji).not.toBeInTheDocument()
  })

  it('filters out emojis blocked at the account level', () => {
    window.ENV.EMOJI_DENY_LIST = 'scream,kissing_heart'
    const {getByRole} = render(<EmojiPicker insertEmoji={insertEmoji} />)
    const button = getByRole('button', {name: /Open emoji menu/})
    userEvent.click(button)
    const region = getByRole('region', {name: /People & Body/})
    const emoji = within(region).queryByRole('button', {name: /😘, kissing_heart/})
    expect(emoji).not.toBeInTheDocument()
  })

  it('filters out emojis passed via the excludedEmojis prop', () => {
    const {getByRole} = render(
      <EmojiPicker insertEmoji={insertEmoji} excludedEmojis={['kissing_heart']} />
    )
    const button = getByRole('button', {name: /Open emoji menu/})
    userEvent.click(button)
    const region = getByRole('region', {name: /People & Body/})
    const emoji = within(region).queryByRole('button', {name: /😘, kissing_heart/})
    expect(emoji).not.toBeInTheDocument()
  })
})
