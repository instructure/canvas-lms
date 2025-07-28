/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import SpeedGraderSettingsMenu from '../SpeedGraderSettingsMenu'
import {render, waitFor} from '@testing-library/react'

describe('Webzip export app', () => {
  let $container
  const props = {
    assignmentID: '71',
    courseID: '8',
    helpURL: 'example.com/support',
    onMenuShow: () => {},
    openOptionsModal() {},
    openKeyboardShortcutsModal() {},
    showHelpMenuItem: false,
    showModerationMenuItem: false,
    showKeyboardShortcutsMenuItem: false, // Add missing required prop
  }

  beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)
    jest.spyOn(SpeedGraderSettingsMenu, 'setURL').mockImplementation(() => {})
    jest.spyOn(window, 'open').mockImplementation(() => {})
  })

  afterEach(() => {
    jest.restoreAllMocks()
    $container.remove()
  })

  test('includes an "Options" menu item', async () => {
    props.showKeyboardShortcutsMenuItem = false
    const wrapper = render(<SpeedGraderSettingsMenu {...props} />, {attachTo: $container})
    await wrapper.getByRole('button').click()
    await waitFor(() => {
      expect(wrapper.getByText('Options')).toBeInTheDocument()
    })
  })

  test('calls the openOptionsModal prop when "Options" is clicked', async () => {
    props.openOptionsModal = jest.fn()
    const wrapper = render(<SpeedGraderSettingsMenu {...props} />, {attachTo: $container})
    await wrapper.getByRole('button').click()
    await waitFor(() => {
      expect(wrapper.getByText('Options')).toBeInTheDocument()
    })
    wrapper.getByText('Options').click()
    expect(props.openOptionsModal).toHaveBeenCalledTimes(1)
  })

  test('includes a "Keyboard Shortcuts" menu item when keyboard shortcuts are enabled', async () => {
    props.showKeyboardShortcutsMenuItem = true
    const wrapper = render(<SpeedGraderSettingsMenu {...props} />, {attachTo: $container})
    await wrapper.getByRole('button').click()
    expect(wrapper.getByText('Keyboard Shortcuts')).toBeInTheDocument()
  })

  test('does not include a "Keyboard Shortcuts" menu item when keyboard shortcuts are disabled', async () => {
    props.showKeyboardShortcutsMenuItem = false
    const wrapper = render(<SpeedGraderSettingsMenu {...props} />, {attachTo: $container})
    await wrapper.getByRole('button').click()
    expect(wrapper.queryByText('Keyboard Shortcuts')).toBeNull()
  })

  test('calls the openKeyboardShortcutsModal prop when "Keyboard Shortcuts" is clicked', async () => {
    props.showKeyboardShortcutsMenuItem = true
    props.openKeyboardShortcutsModal = jest.fn()
    const wrapper = render(<SpeedGraderSettingsMenu {...props} />, {attachTo: $container})
    await wrapper.getByRole('button').click()
    wrapper.getByText('Keyboard Shortcuts').click()
    expect(props.openKeyboardShortcutsModal).toHaveBeenCalledTimes(1)
  })

  test('does not include a "Moderation Page" menu item if passed showModerationMenuItem: false', async () => {
    // Make sure showModerationMenuItem is explicitly set to false
    props.showModerationMenuItem = false
    const wrapper = render(<SpeedGraderSettingsMenu {...props} />, {attachTo: $container})
    await wrapper.getByRole('button').click()
    expect(wrapper.queryByText('Moderation Page')).toBeNull()
  })

  test('includes a "Moderation Page" menu item if passed showModerationMenuItem: true', async () => {
    props.showModerationMenuItem = true
    const wrapper = render(<SpeedGraderSettingsMenu {...props} />, {attachTo: $container})
    await wrapper.getByRole('button').click()
    expect(wrapper.getByText('Moderation Page')).toBeInTheDocument()
  })

  test('calls window.open when the "Moderation Page" is clicked', async () => {
    props.showModerationMenuItem = true
    const wrapper = render(<SpeedGraderSettingsMenu {...props} />, {attachTo: $container})
    await wrapper.getByRole('button').click()
    await wrapper.getByText('Moderation Page').click()
    expect(window.open).toHaveBeenCalledTimes(1)
  })

  test('opens the moderation page when the "Moderation Page" is clicked', async () => {
    props.showModerationMenuItem = true
    const wrapper = render(<SpeedGraderSettingsMenu {...props} />, {attachTo: $container})
    await wrapper.getByRole('button').click()
    await wrapper.getByText('Moderation Page').click()
    const expectedURL = `/courses/${props.courseID}/assignments/${props.assignmentID}/moderate`
    expect(window.open).toHaveBeenCalledWith(expectedURL, '_blank')
  })

  test('opens the page in a new tab when the "Moderation Page" is clicked', async () => {
    props.showModerationMenuItem = true
    const wrapper = render(<SpeedGraderSettingsMenu {...props} />, {attachTo: $container})
    await wrapper.getByRole('button').click()
    await wrapper.getByText('Moderation Page').click()
    const openInNewTabArgument = '_blank'
    expect(window.open).toHaveBeenCalledWith(expect.any(String), openInNewTabArgument)
  })

  test('does not include a "Help" menu item if passed showHelpMenuItem: false', async () => {
    // Explicitly set showHelpMenuItem to false
    props.showHelpMenuItem = false
    const wrapper = render(<SpeedGraderSettingsMenu {...props} />, {attachTo: $container})
    await wrapper.getByRole('button').click()
    expect(wrapper.queryByText('Help')).toBeNull()
  })

  test('includes a "Help" menu item if passed showHelpMenuItem: true', async () => {
    props.showHelpMenuItem = true
    const wrapper = render(<SpeedGraderSettingsMenu {...props} />, {attachTo: $container})
    await wrapper.getByRole('button').click()
    expect(wrapper.getByText('Help')).toBeInTheDocument()
  })

  test('sets the URL when "Help" is clicked', async () => {
    props.showHelpMenuItem = true
    const wrapper = render(<SpeedGraderSettingsMenu {...props} />, {attachTo: $container})
    await wrapper.getByRole('button').click()
    await wrapper.getByText('Help').click()
    expect(SpeedGraderSettingsMenu.setURL).toHaveBeenCalledTimes(1)
  })

  test('navigates to the help URL when "Help" is clicked', async () => {
    props.showHelpMenuItem = true
    const wrapper = render(<SpeedGraderSettingsMenu {...props} />, {attachTo: $container})
    await wrapper.getByRole('button').click()
    await wrapper.getByText('Help').click()
    expect(SpeedGraderSettingsMenu.setURL).toHaveBeenCalledWith(props.helpURL)
  })
})
