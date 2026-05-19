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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
// eslint-disable-next-line import/no-nodejs-modules
import fs from 'fs'
// eslint-disable-next-line import/no-nodejs-modules
import path from 'path'
import {AddLinkModal, validateUrl} from '../AddLinkModal'
import {expect} from 'vitest'

const cases = JSON.parse(
  fs.readFileSync(
    path.join(__dirname, '../../../../../../spec/fixtures/url_validation/nav_menu_link_cases.json'),
    'utf8',
  ),
) as {invalid: string[]; normalizable: Record<string, string>; valid: string[]}

const mockProps = {
  isOpen: true,
  onDismiss: jest.fn(),
  onAdd: jest.fn(),
}

describe('validateUrl', () => {
  // Test cases shared with Ruby spec — see spec/fixtures/url_validation/nav_menu_link_cases.json
  it('rejects invalid URLs', () => {
    for (const url of cases.invalid) {
      const result = validateUrl(url)
      expect.soft('error' in result, `expected "${url}" to be invalid`).toBe(true)
    }
  })

  it('accepts valid URLs', () => {
    for (const url of cases.valid) {
      const result = validateUrl(url)
      expect.soft('normalized' in result, `expected "${url}" to be valid`).toBe(true)
    }
  })

  it('normalizes normalizable URLs to their canonical form', () => {
    for (const [input, expected] of Object.entries(cases.normalizable)) {
      const result = validateUrl(input)
      expect
        .soft('normalized' in result, `expected "${input}" to produce a normalized URL`)
        .toBe(true)
      if ('normalized' in result) {
        expect
          .soft(result.normalized, `expected "${input}" to normalize to "${expected}"`)
          .toBe(expected)
      }
    }
  })

  it('discards extra https//', () => {
    const result = validateUrl('https://https://example.com/')
    expect(result).toEqual({normalized: 'https://example.com/'})
  })

  it('rejects URLs that exceed 2048 characters after URL encoding', () => {
    // 200 ant emojis: new URL() encodes each to %F0%9F%90%9C (12 chars), making the URL 2420 chars
    const url = 'https://example.com/' + '🐜'.repeat(200)
    const result = validateUrl(url)
    expect('error' in result).toBe(true)
  })
})

describe('AddLinkModal', () => {
  let user: ReturnType<typeof userEvent.setup>
  let textInput: HTMLInputElement
  let linkInput: HTMLInputElement

  beforeEach(async () => {
    jest.clearAllMocks()

    user = userEvent.setup()
    render(<AddLinkModal {...mockProps} />)

    // Get inputs and verify their labels
    const inputs = await screen.findAllByRole('textbox')
    expect(inputs).toHaveLength(2)

    textInput = inputs[0] as HTMLInputElement
    linkInput = inputs[1] as HTMLInputElement
  })

  function clickAdd() {
    const addButton = screen.getByRole('button', {name: 'Add'})
    expect(addButton).not.toBeDisabled()
    return user.click(addButton)
  }

  it('calls onAdd with normalized text and url', async () => {
    // Verify the first input has "Text" in its label
    const textLabel = screen.getByText('Text', {selector: 'label *'})
    expect(textLabel).toBeInTheDocument()

    // Verify the second input has "Link" in its label
    const linkLabel = screen.getByText('Link', {selector: 'label *'})
    expect(linkLabel).toBeInTheDocument()

    fireEvent.change(textInput, {target: {value: '  TestLink '}})
    fireEvent.change(linkInput, {target: {value: ' https://example.com '}})

    await clickAdd()

    expect(mockProps.onAdd).toHaveBeenCalledWith({
      label: 'TestLink',
      url: 'https://example.com/',
      placements: {course_nav: true, account_nav: false, user_nav: false},
    })
  })

  it('Add button is always enabled', () => {
    expect(screen.getByRole('button', {name: 'Add'})).not.toBeDisabled()
  })

  it('prevents submission and focuses text input when text is empty', async () => {
    await user.clear(textInput)
    await user.type(linkInput, 'https://example.com')

    await clickAdd()

    expect(mockProps.onAdd).not.toHaveBeenCalled()
    await waitFor(() => expect(textInput).toHaveFocus())
    expect(
      await screen.findByText('Please enter text between 1 and 50 characters long'),
    ).toBeInTheDocument()
  })

  it('prevents submission and focuses URL input when URL is invalid', async () => {
    // Ensure text field is valid
    await user.clear(textInput)
    await user.type(textInput, 'TestLink')

    // Clear the URL field completely and type an invalid URL
    await user.clear(linkInput)
    await user.type(linkInput, 'not-a-url')

    await clickAdd()

    expect(mockProps.onAdd).not.toHaveBeenCalled()
    await waitFor(() => expect(linkInput).toHaveFocus())
    expect(
      await screen.findByText('Please enter a valid URL beginning with https:// or http://'),
    ).toBeInTheDocument()
  })

  it('does not show URL error until field is blurred', async () => {
    // Directly change the value to an invalid URL without causing blur
    fireEvent.change(linkInput, {target: {value: 'just-text'}})

    // Error should NOT appear yet
    expect(
      screen.queryByText('Please enter a valid URL beginning with https:// or http://'),
    ).not.toBeInTheDocument()

    // Blur the field by triggering blur event directly
    fireEvent.blur(linkInput)

    // Now error should appear
    expect(
      await screen.findByText('Please enter a valid URL beginning with https:// or http://'),
    ).toBeInTheDocument()
  })

  it('does not show text error until field is blurred', async () => {
    // Directly change the value to empty without causing blur
    fireEvent.change(textInput, {target: {value: ''}})

    // Error should NOT appear yet
    expect(
      screen.queryByText('Please enter text between 1 and 50 characters long'),
    ).not.toBeInTheDocument()

    // Blur the field by triggering blur event directly
    fireEvent.blur(textInput)

    // Now error should appear
    expect(
      await screen.findByText('Please enter text between 1 and 50 characters long'),
    ).toBeInTheDocument()
  })

  it('shows hint text when URL is valid or the default', async () => {
    expect(
      screen.queryByText('Please enter a valid URL beginning with https:// or http://'),
    ).not.toBeInTheDocument()
    expect(
      screen.getByText(
        'This can be an external link or a Canvas URL. This link will open in a new tab.',
      ),
    ).toBeInTheDocument()

    await user.clear(linkInput)
    await user.type(linkInput, 'https://example.com')

    expect(
      screen.queryByText('Please enter a valid URL beginning with https:// or http://'),
    ).not.toBeInTheDocument()
    expect(
      screen.getByText(
        'This can be an external link or a Canvas URL. This link will open in a new tab.',
      ),
    ).toBeInTheDocument()
  })

  it('shows required indicators on both fields', () => {
    expect(textInput).toBeRequired()
    expect(linkInput).toBeRequired()
  })

  describe('with multiple availablePlacements', () => {
    it('shows placement checkboxes and submits selected placements', async () => {
      const onAdd = jest.fn()
      render(
        <AddLinkModal
          onDismiss={jest.fn()}
          onAdd={onAdd}
          availablePlacements={['course_nav', 'account_nav']}
        />,
      )

      const [textIn, linkIn] = (await screen.findAllByRole('textbox')).slice(
        -2,
      ) as HTMLInputElement[]
      fireEvent.change(textIn, {target: {value: 'My Link'}})
      fireEvent.change(linkIn, {target: {value: 'https://example.com'}})

      // No placements are pre-checked; select course_nav and account_nav
      const courseCheckbox = screen.getByRole('checkbox', {name: 'Course Navigation'})
      const accountCheckbox = screen.getByRole('checkbox', {name: 'Account Navigation'})
      await user.click(courseCheckbox)
      await user.click(accountCheckbox)

      await user.click(screen.getAllByRole('button', {name: 'Add'}).at(-1)!)

      expect(onAdd).toHaveBeenCalledWith({
        label: 'My Link',
        url: 'https://example.com/',
        placements: {course_nav: true, account_nav: true, user_nav: false},
      })
    })
  })
})
