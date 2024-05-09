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

import React from 'react'
import {render, screen} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import DiscussionSettings from '../DiscussionSettings'
import merge from 'lodash/merge'

const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})

describe('DiscussionsSettings', () => {
  const makeProps = (props = {}) =>
    merge(
      {
        courseSettings: {
          allow_student_discussion_topics: true,
          allow_student_forum_attachments: true,
          allow_student_discussion_editing: true,
          allow_student_discussion_reporting: true,
          allow_student_anonymous_discussion_topics: true,
          grading_standard_enabled: false,
          grading_standard_id: null,
          allow_student_organized_groups: true,
          hide_final_grades: false,
        },
        userSettings: {
          markAsRead: false,
          collapse_global_nav: false,
        },
        isSavingSettings: false,
        isSettingsModalOpen: true,
        permissions: {
          change_settings: false,
          create: false,
          manage_content: false,
          moderate: false,
        },
        saveSettings() {},
        toggleModalOpen() {},
        applicationElement: () => document.getElementById('fixtures'),
      },
      props
    )

  const oldEnv = window.ENV

  beforeEach(() => {
    window.ENV.student_reporting_enabled = true
    window.ENV.discussion_anonymity_enabled = true
  })

  afterEach(() => {
    window.ENV = oldEnv
  })

  it('should render discussion settings', () => {
    expect(() => {
      render(<DiscussionSettings {...makeProps()} />)
    }).not.toThrow()
  })

  it('should find 0 checked boxes', () => {
    render(
      <DiscussionSettings
        {...makeProps({
          permissions: {change_settings: true},
          courseSettings: {
            allow_student_discussion_topics: false,
            allow_student_forum_attachments: false,
            allow_student_discussion_editing: false,
            allow_student_discussion_reporting: false,
            allow_student_anonymous_discussion_topics: false,
          },
        })}
      />
    )

    const checkboxes = screen.getAllByRole('checkbox')
    expect(checkboxes).toHaveLength(6)
    checkboxes.forEach(checkbox => {
      expect(checkbox).not.toHaveAttribute('checked')
    })
  })

  it('should render one checkbox if can not change settings', () => {
    render(<DiscussionSettings {...makeProps({isSettingsModalOpen: true})} />)
    const checkboxes = screen.getAllByRole('checkbox')
    expect(checkboxes).toHaveLength(1)
  })

  it('should render 6 checkbox if can change settings', () => {
    render(
      <DiscussionSettings
        {...makeProps({isSettingsModalOpen: true, permissions: {change_settings: true}})}
      />
    )
    const checkboxes = screen.getAllByRole('checkbox')
    expect(checkboxes).toHaveLength(6)
  })

  it('will call save settings when button is clicked with correct args', async () => {
    const saveMock = jest.fn()

    const courseSettings = {
      allow_student_discussion_topics: false,
      allow_student_forum_attachments: false,
      allow_student_discussion_editing: false,
      allow_student_discussion_reporting: false,
      allow_student_anonymous_discussion_topics: false,
    }
    const expectedCourseSettings = {
      allow_student_discussion_topics: true,
      allow_student_forum_attachments: true,
      allow_student_discussion_editing: true,
      allow_student_discussion_reporting: true,
      allow_student_anonymous_discussion_topics: true,
    }
    const userSettings = {
      markAsRead: false,
      collapse_global_nav: false,
    }

    render(
      <DiscussionSettings
        {...makeProps({
          userSettings,
          courseSettings,
          saveSettings: saveMock,
          isSettingsModalOpen: true,
          isSavingSettings: false,
          permissions: {change_settings: true},
        })}
      />
    )

    const checkboxes = screen.getAllByRole('checkbox')
    for (const checkbox of checkboxes) {
      // eslint-disable-next-line no-await-in-loop
      await user.click(checkbox)
    }

    const button = screen.getByRole('button', {name: 'Save Settings'})
    await user.click(button)
    expect(saveMock).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining(expectedCourseSettings)
    )
  })

  it('will call save settings when button is clicked with correct args round 2', async () => {
    const saveMock = jest.fn()

    const courseSettings = {
      allow_student_discussion_topics: true,
      allow_student_forum_attachments: false,
      allow_student_discussion_editing: true,
      allow_student_discussion_reporting: false,
      allow_student_anonymous_discussion_topics: false,
    }
    const expectedCourseSettings = {
      allow_student_discussion_topics: false,
      allow_student_forum_attachments: true,
      allow_student_discussion_editing: false,
      allow_student_discussion_reporting: true,
      allow_student_anonymous_discussion_topics: false,
    }
    const userSettings = {
      markAsRead: false,
      collapse_global_nav: false,
    }

    render(
      <DiscussionSettings
        {...makeProps({
          userSettings,
          courseSettings,
          saveSettings: saveMock,
          isSettingsModalOpen: true,
          isSavingSettings: false,
          permissions: {change_settings: true},
        })}
      />
    )

    const checkboxes = screen.getAllByRole('checkbox')
    for (const checkbox of checkboxes) {
      // eslint-disable-next-line no-await-in-loop
      await user.click(checkbox)
    }

    const button = screen.getByRole('button', {name: 'Save Settings'})
    await user.click(button)
    expect(saveMock).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining(expectedCourseSettings)
    )
  })

  it('will render spinner when isSaving is set', () => {
    render(
      <DiscussionSettings
        {...makeProps({
          isSavingSettings: true,
          isSettingsModalOpen: true,
          permissions: {change_settings: true},
        })}
      />
    )

    expect(screen.getByTestId('discussion-settings-spinner-container')).toBeInTheDocument()
  })
})
