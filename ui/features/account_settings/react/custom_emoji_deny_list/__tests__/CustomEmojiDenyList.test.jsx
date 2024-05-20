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
import CustomEmojiDenyList from '../CustomEmojiDenyList'

describe('CustomEmojiDenyList', () => {
  let originalENV

  beforeEach(() => {
    originalENV = window.ENV
    window.ENV = {}
  })

  afterEach(() => {
    window.ENV = originalENV
    localStorage.clear()
  })

  it('renders a tag for each emoji in the deny list', () => {
    window.ENV.EMOJI_DENY_LIST = 'middle_finger,eggplant'
    const {getByRole} = render(<CustomEmojiDenyList />)
    expect(
      getByRole('button', {name: /Remove emoji "Reversed Hand with Middle Finger Extended"/})
    ).toBeInTheDocument()
    expect(getByRole('button', {name: /Remove emoji "Aubergine"/})).toBeInTheDocument()
  })

  it('removes a tag when it is clicked', async () => {
    window.ENV.EMOJI_DENY_LIST = 'middle_finger,eggplant'
    const {getByRole, queryByRole} = render(<CustomEmojiDenyList />)
    const tagCriteria = {name: /Remove emoji "Reversed Hand with Middle Finger Extended"/}
    const tag = getByRole('button', tagCriteria)
    await userEvent.click(tag)
    expect(queryByRole('button', tagCriteria)).not.toBeInTheDocument()
  })

  it.skip('adds a tag to the list when an emoji is clicked', async () => {
    const {getByRole} = render(<CustomEmojiDenyList />)
    await userEvent.click(getByRole('button', {name: /Open emoji menu/}))
    await userEvent.click(getByRole('button', {name: /😘, kissing_heart/}))
    expect(getByRole('button', {name: /Remove emoji "Face Throwing a Kiss"/})).toBeInTheDocument()
  })

  it.skip('maintains the deny list value in a hidden input', async () => {
    const {getByRole, getByTestId} = render(<CustomEmojiDenyList />)
    const button = getByRole('button', {name: /Open emoji menu/})
    await userEvent.click(button)
    await userEvent.click(getByRole('button', {name: /😘, kissing_heart/}))
    await userEvent.click(button)
    await userEvent.click(getByRole('button', {name: /😝, stuck_out_tongue_closed_eyes/}))
    const input = getByTestId('account-settings-emoji-deny-list', {hidden: true})
    expect(input.value).toEqual('kissing_heart,stuck_out_tongue_closed_eyes')
  })
})
