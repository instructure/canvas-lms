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
import {merge} from 'es-toolkit/compat'

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
          manage_content: true,
          moderate: false,
          apply_default_discussion_options: true,
        },
        saveSettings() {},
        toggleModalOpen() {},
        applicationElement: () => document.getElementById('fixtures'),
      },
      props,
    )

  const oldEnv = window.ENV

  beforeEach(() => {
    window.ENV.student_reporting_enabled = true
    window.ENV.discussion_anonymity_enabled = true
    window.ENV.FEATURES.default_discussion_options = true
  })

  afterEach(() => {
    window.ENV = oldEnv
  })

  it('should render discussion settings', () => {
    expect(() => {
      render(<DiscussionSettings {...makeProps()} />)
    }).not.toThrow()
  })

  it('should render discussion settings with buttonText', () => {
    render(<DiscussionSettings {...makeProps()} />)

    const settingsButton = screen.getByTestId('discussion-setting-button')
    expect(settingsButton).toHaveTextContent('Settings')
  })

  it('should render settings in a tray that opens from the right', () => {
    render(<DiscussionSettings {...makeProps()} />)

    expect(screen.getByLabelText('Discussion Settings')).toBeInTheDocument()
  })

  it('should render a close button in the tray', () => {
    render(<DiscussionSettings {...makeProps()} />)

    expect(screen.getByTestId('close-discussion-settings-tray')).toBeInTheDocument()
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
      />,
    )

    const checkboxes = screen
      .getByTestId('discussion-settings-modal-body')
      .querySelectorAll('input[type="checkbox"]')
    expect(checkboxes).toHaveLength(7)
    checkboxes.forEach(checkbox => {
      expect(checkbox).not.toHaveAttribute('checked')
    })
  })

  it('should render one checkbox if can not change settings', () => {
    render(<DiscussionSettings {...makeProps({isSettingsModalOpen: true})} />)
    const checkboxes = screen
      .getByTestId('discussion-settings-modal-body')
      .querySelectorAll('input[type="checkbox"]')
    expect(checkboxes).toHaveLength(1)
  })

  it('should render 7 checkbox if can change settings', () => {
    render(
      <DiscussionSettings
        {...makeProps({
          isSettingsModalOpen: true,
          permissions: {change_settings: true, manage_content: true},
        })}
      />,
    )
    const checkboxes = screen
      .getByTestId('discussion-settings-modal-body')
      .querySelectorAll('input[type="checkbox"]')
    expect(checkboxes).toHaveLength(7)
  })

  it('will call save settings when button is clicked with correct args', async () => {
    const saveMock = vi.fn()

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
      />,
    )

    const checkboxes = screen
      .getByTestId('discussion-settings-modal-body')
      .querySelectorAll('input[type="checkbox"]')
    for (const checkbox of checkboxes) {
      await user.click(checkbox)
    }

    const button = screen.getByTestId('save-discussion-settings')
    await user.click(button)
    expect(saveMock).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining(expectedCourseSettings),
    )
  })

  it('will call save settings when button is clicked with correct args round 2', async () => {
    const saveMock = vi.fn()

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
      />,
    )

    const checkboxes = screen
      .getByTestId('discussion-settings-modal-body')
      .querySelectorAll('input[type="checkbox"]')
    for (const checkbox of checkboxes) {
      await user.click(checkbox)
    }

    const button = screen.getByTestId('save-discussion-settings')
    await user.click(button)
    expect(saveMock).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining(expectedCourseSettings),
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
      />,
    )

    expect(screen.getByTestId('discussion-settings-spinner-container')).toBeInTheDocument()
  })

  describe('Default Discussion Options section', () => {
    it('does not render for users without change_settings permission', () => {
      render(
        <DiscussionSettings
          {...makeProps({
            permissions: {change_settings: false},
            useDefaultDiscussionSettings: true,
          })}
        />,
      )
      expect(screen.queryByText('Default Settings')).not.toBeInTheDocument()
    })

    it('renders the section heading for users with change_settings', () => {
      render(
        <DiscussionSettings
          {...makeProps({
            permissions: {change_settings: true, manage_content: true},
            useDefaultDiscussionSettings: true,
          })}
        />,
      )
      expect(screen.getByText('Default Settings')).toBeInTheDocument()
    })

    describe('granular permissions', () => {
      const enableAndOpen = async () => {
        const toggle = screen.getByLabelText(
          'Apply the following options to newly created discussions',
        )
        await user.click(toggle)
      }

      it('disables anonymous discussion when edit_discussion_anonymity is false', async () => {
        render(
          <DiscussionSettings
            {...makeProps({
              useDefaultDiscussionSettings: true,
              permissions: {
                change_settings: true,
                manage_content: true,
                edit_discussion_anonymity: false,
                edit_discussion_options: true,
                edit_discussion_views: true,
              },
            })}
          />,
        )
        await enableAndOpen()
        const radioInputs = screen
          .getByText('Anonymous Discussion')
          .closest('fieldset')
          ?.querySelectorAll('input[type="radio"]')
        radioInputs?.forEach(input => {
          expect(input).toBeDisabled()
        })
      })

      it('enables anonymous discussion when edit_discussion_anonymity is true', async () => {
        render(
          <DiscussionSettings
            {...makeProps({
              useDefaultDiscussionSettings: true,
              permissions: {
                change_settings: true,
                manage_content: true,
                edit_discussion_anonymity: true,
                edit_discussion_options: true,
                edit_discussion_views: true,
              },
            })}
          />,
        )
        await enableAndOpen()
        const radioInputs = screen
          .getByText('Anonymous Discussion')
          .closest('fieldset')
          ?.querySelectorAll('input[type="radio"]')
        radioInputs?.forEach(input => {
          expect(input).not.toBeDisabled()
        })
      })

      it('disables options checkboxes when edit_discussion_options is false', async () => {
        render(
          <DiscussionSettings
            {...makeProps({
              useDefaultDiscussionSettings: true,
              permissions: {
                change_settings: true,
                manage_content: true,
                edit_discussion_anonymity: true,
                edit_discussion_options: false,
                edit_discussion_views: true,
              },
            })}
          />,
        )
        await enableAndOpen()
        expect(screen.getByLabelText('Disallow threaded replies')).toBeDisabled()
        expect(
          screen.getByLabelText(
            'Participants must respond to the topic before viewing other replies',
          ),
        ).toBeDisabled()
        expect(screen.getByLabelText('Enable podcast feed')).toBeDisabled()
        expect(screen.getByLabelText('Allow liking')).toBeDisabled()
      })

      it('enables options checkboxes when edit_discussion_options is true', async () => {
        render(
          <DiscussionSettings
            {...makeProps({
              useDefaultDiscussionSettings: true,
              permissions: {
                change_settings: true,
                manage_content: true,
                edit_discussion_anonymity: true,
                edit_discussion_options: true,
                edit_discussion_views: true,
              },
            })}
          />,
        )
        await enableAndOpen()
        expect(screen.getByLabelText('Disallow threaded replies')).not.toBeDisabled()
        expect(screen.getByLabelText('Enable podcast feed')).not.toBeDisabled()
        expect(screen.getByLabelText('Allow liking')).not.toBeDisabled()
      })

      it('disables view inputs when edit_discussion_views is false', async () => {
        render(
          <DiscussionSettings
            {...makeProps({
              useDefaultDiscussionSettings: true,
              permissions: {
                change_settings: true,
                manage_content: true,
                edit_discussion_anonymity: true,
                edit_discussion_options: true,
                edit_discussion_views: false,
              },
            })}
          />,
        )
        await enableAndOpen()
        const expandedRadios = screen
          .getByText('Default Thread State')
          .closest('fieldset')
          ?.querySelectorAll('input[type="radio"]')
        expandedRadios?.forEach(input => {
          expect(input).toBeDisabled()
        })
        expect(screen.getByLabelText('Lock thread state for students')).toBeDisabled()
        const sortOrderRadios = screen
          .getByText('Default Sort Order')
          .closest('fieldset')
          ?.querySelectorAll('input[type="radio"]')
        sortOrderRadios?.forEach(input => {
          expect(input).toBeDisabled()
        })
        expect(screen.getByLabelText('Lock sort order for students')).toBeDisabled()
      })

      it('enables view inputs when edit_discussion_views is true', async () => {
        render(
          <DiscussionSettings
            {...makeProps({
              useDefaultDiscussionSettings: true,
              permissions: {
                change_settings: true,
                manage_content: true,
                edit_discussion_anonymity: true,
                edit_discussion_options: true,
                edit_discussion_views: true,
              },
            })}
          />,
        )
        await enableAndOpen()
        expect(screen.getByLabelText('Lock thread state for students')).not.toBeDisabled()
        expect(screen.getByLabelText('Lock sort order for students')).not.toBeDisabled()
      })

      describe('locked setting tooltip', () => {
        const lockedMsg = 'Modifying this option has been disabled by administrators'

        it('shows tooltip on hover when edit_discussion_anonymity is false', async () => {
          render(
            <DiscussionSettings
              {...makeProps({
                useDefaultDiscussionSettings: true,
                permissions: {
                  change_settings: true,
                  manage_content: true,
                  edit_discussion_anonymity: false,
                  edit_discussion_options: true,
                  edit_discussion_views: true,
                },
              })}
            />,
          )
          await enableAndOpen()
          const wrapper = screen.getByText('Anonymous Discussion').closest('span')
          await user.hover(wrapper)
          expect(await screen.findByText(lockedMsg)).toBeInTheDocument()
        })

        it('does not show tooltip when edit_discussion_anonymity is true', async () => {
          render(
            <DiscussionSettings
              {...makeProps({
                useDefaultDiscussionSettings: true,
                permissions: {
                  change_settings: true,
                  manage_content: true,
                  edit_discussion_anonymity: true,
                  edit_discussion_options: true,
                  edit_discussion_views: true,
                },
              })}
            />,
          )
          await enableAndOpen()
          const anonymitySection = screen.getByText('Anonymous Discussion').closest('fieldset')
          await user.hover(anonymitySection)
          expect(screen.queryByText(lockedMsg)).not.toBeInTheDocument()
        })

        it('shows tooltip on hover when edit_discussion_options is false', async () => {
          render(
            <DiscussionSettings
              {...makeProps({
                useDefaultDiscussionSettings: true,
                permissions: {
                  change_settings: true,
                  manage_content: true,
                  edit_discussion_anonymity: true,
                  edit_discussion_options: false,
                  edit_discussion_views: true,
                },
              })}
            />,
          )
          await enableAndOpen()
          const wrapper = screen.getByLabelText('Disallow threaded replies').closest('span')
          await user.hover(wrapper)
          expect((await screen.findAllByText(lockedMsg)).length).toBeGreaterThan(0)
        })

        it('shows tooltip on hover when edit_discussion_views is false', async () => {
          render(
            <DiscussionSettings
              {...makeProps({
                useDefaultDiscussionSettings: true,
                permissions: {
                  change_settings: true,
                  manage_content: true,
                  edit_discussion_anonymity: true,
                  edit_discussion_options: true,
                  edit_discussion_views: false,
                },
              })}
            />,
          )
          await enableAndOpen()
          const wrapper = screen.getByLabelText('Lock thread state for students').closest('span')
          await user.hover(wrapper)
          expect((await screen.findAllByText(lockedMsg)).length).toBeGreaterThan(0)
        })
      })

      it('each permission gates only its own section independently', async () => {
        render(
          <DiscussionSettings
            {...makeProps({
              permissions: {
                change_settings: true,
                edit_discussion_anonymity: false,
                edit_discussion_options: true,
                edit_discussion_views: false,
              },
            })}
          />,
        )
        await enableAndOpen()
        // options enabled
        expect(screen.getByLabelText('Disallow threaded replies')).not.toBeDisabled()
        // views disabled
        expect(screen.getByLabelText('Lock sort order for students')).toBeDisabled()
        // anonymity disabled
        const radioInputs = screen
          .getByText('Anonymous Discussion')
          .closest('fieldset')
          ?.querySelectorAll('input[type="radio"]')
        radioInputs?.forEach(input => {
          expect(input).toBeDisabled()
        })
      })
    })

    it('renders the enable toggle checkbox', () => {
      render(<DiscussionSettings {...makeProps({permissions: {change_settings: true}})} />)
      expect(
        screen.getByLabelText('Apply the following options to newly created discussions'),
      ).toBeInTheDocument()
    })

    it('does not show sub-settings when toggle is off', () => {
      render(<DiscussionSettings {...makeProps({permissions: {change_settings: true}})} />)
      expect(screen.queryByText('Options')).not.toBeInTheDocument()
      expect(screen.queryByText('View')).not.toBeInTheDocument()
    })

    it('shows sub-settings when toggle is turned on', async () => {
      render(<DiscussionSettings {...makeProps({permissions: {change_settings: true}})} />)
      const toggle = screen.getByLabelText(
        'Apply the following options to newly created discussions',
      )
      await user.click(toggle)
      expect(screen.getByText('Options')).toBeInTheDocument()
      expect(screen.getByText('View')).toBeInTheDocument()
    })

    it('shows anonymous discussion options when discussion_anonymity_enabled', async () => {
      render(<DiscussionSettings {...makeProps({permissions: {change_settings: true}})} />)
      const toggle = screen.getByLabelText(
        'Apply the following options to newly created discussions',
      )
      await user.click(toggle)
      expect(screen.getByText('Anonymous Discussion')).toBeInTheDocument()
    })

    it('shows podcast sub-option when podcast feed is enabled', async () => {
      render(
        <DiscussionSettings
          {...makeProps({
            permissions: {
              change_settings: true,
              edit_discussion_options: true,
              manage_content: true,
            },
          })}
        />,
      )
      const toggle = screen.getByLabelText(
        'Apply the following options to newly created discussions',
      )
      await user.click(toggle)
      const podcastCheckbox = screen.getByLabelText('Enable podcast feed')
      await user.click(podcastCheckbox)
      expect(screen.getByLabelText('Include student replies in podcast feed')).toBeInTheDocument()
    })

    it('shows graders-only sub-option when allow liking is enabled', async () => {
      render(
        <DiscussionSettings
          {...makeProps({
            useDefaultDiscussionSettings: true,
            permissions: {
              change_settings: true,
              manage_content: true,
              edit_discussion_options: true,
            },
          })}
        />,
      )
      const toggle = screen.getByLabelText(
        'Apply the following options to newly created discussions',
      )
      await user.click(toggle)
      const likeCheckbox = screen.getByText('Allow liking')
      await user.click(likeCheckbox)
      expect(screen.getByText('Only graders can like')).toBeInTheDocument()
    })

    it('loads use_default from ENV.COURSE_DISCUSSION_SETTINGS on prop change', () => {
      window.ENV.COURSE_DISCUSSION_SETTINGS = {use_default: true, defaults: {}}
      const props = makeProps({permissions: {change_settings: true}})
      const {rerender} = render(<DiscussionSettings {...props} />)
      // Trigger UNSAFE_componentWillReceiveProps
      rerender(
        <DiscussionSettings
          {...makeProps({
            permissions: {change_settings: true},
            userSettings: {manual_mark_as_read: true, collapse_global_nav: false},
          })}
        />,
      )
      expect(screen.getByText('Options')).toBeInTheDocument()
      delete window.ENV.COURSE_DISCUSSION_SETTINGS
    })
  })
})
