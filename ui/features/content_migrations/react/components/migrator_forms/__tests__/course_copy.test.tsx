/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, screen, waitFor} from '@testing-library/react'
import CourseCopyImporter from '../course_copy'
import userEvent from '@testing-library/user-event'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {sharedDateParsingTests} from './shared_form_cases'
import fakeENV from '@canvas/test-utils/fakeENV'
import {within} from '@testing-library/dom'

jest.mock('@canvas/do-fetch-api-effect')

const onSubmit = jest.fn()
const onCancel = jest.fn()

const renderComponent = (overrideProps?: any) =>
  render(
    <CourseCopyImporter
      onSubmit={onSubmit}
      onCancel={onCancel}
      isSubmitting={false}
      {...overrideProps}
    />,
  )

const defaultEnv = {
  current_user: {
    id: '0',
  },
  SHOW_BP_SETTINGS_IMPORT_OPTION: true,
  SHOW_SELECT: false,
}

const searchForACourse = 'Search for a course'
const selectACourse = 'Select a course'
const addToImportQueue = 'Add to Import Queue'

describe('CourseCopyImporter', () => {
  beforeEach(() => {
    fakeENV.setup({...defaultEnv})

    // @ts-expect-error
    doFetchApi.mockImplementation(() =>
      Promise.resolve({
        json: [
          {
            id: '0',
            label: 'Mathmatics',
            term: 'Default term',
            blueprint: true,
            end_at: '16 Oct 2024 at 0:00',
            start_at: '14 Oct 2024 at 0:00',
          },
          {
            id: '1',
            label: 'Biology',
            term: 'Other term',
            blueprint: false,
          },
        ],
      }),
    )
  })

  afterEach(() => {
    jest.clearAllMocks()
    fakeENV.teardown()
  })

  it('searches for matching courses and includes concluded by default', async () => {
    const {getByRole, getByText} = renderComponent()
    await userEvent.type(getByRole('combobox', {name: searchForACourse}), 'math')
    await waitFor(() => {
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/users/0/manageable_courses?term=math&include=concluded',
      })
    })
    expect(getByText('Mathmatics')).toBeInTheDocument()
  })

  it('searches for matching courses and display proper terms', async () => {
    const {getByRole, getByText} = renderComponent()
    await userEvent.type(getByRole('combobox', {name: searchForACourse}), 'math')
    await waitFor(() => {
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/users/0/manageable_courses?term=math&include=concluded',
      })
    })
    expect(getByText('Term: Default term')).toBeInTheDocument()
    expect(getByText('Term: Other term')).toBeInTheDocument()
  })

  it('searches for matching courses excluding concluded', async () => {
    const {getByRole} = renderComponent()
    await userEvent.click(getByRole('checkbox', {name: 'Include completed courses'}))
    await userEvent.type(getByRole('combobox', {name: searchForACourse}), 'math')
    await waitFor(() => {
      expect(doFetchApi).toHaveBeenCalledWith({
        path: '/users/0/manageable_courses?term=math',
      })
    })
    expect(screen.getByText('Mathmatics')).toBeInTheDocument()
  })

  it('calls onSubmit', async () => {
    const {getByRole, findByText} = renderComponent()
    await userEvent.type(getByRole('combobox', {name: searchForACourse}), 'math')
    await userEvent.click(await findByText('Mathmatics'))
    await userEvent.click(getByRole('button', {name: addToImportQueue}))
    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({
        settings: expect.objectContaining({
          source_course_id: '0',
        }),
      }),
    )
  })

  it('calls onCancel', async () => {
    const {getByRole} = renderComponent()
    await userEvent.click(getByRole('button', {name: 'Clear'}))
    expect(onCancel).toHaveBeenCalled()
  })

  // The testing of onCancel and onSubmit above need the actual common migrator controls
  // So instead of mocking it here and testing the prop being passed to the mock
  // we're following the precedent and testing all the way to the child in this suite
  it('Renders BP settings import option if appropriate', async () => {
    const {getByRole, findByText, getByText} = renderComponent()
    await userEvent.type(getByRole('combobox', {name: searchForACourse}), 'math')
    await userEvent.click(await findByText('Mathmatics'))
    await expect(await getByText('Import Blueprint Course settings')).toBeInTheDocument()
  })

  it('Does not renders BP settings import option when the destination course is marked ineligible', async () => {
    fakeENV.setup({...defaultEnv, SHOW_BP_SETTINGS_IMPORT_OPTION: false,})
    const {getByRole, findByText, queryByText} = renderComponent()
    await userEvent.type(getByRole('combobox', {name: searchForACourse}), 'math')
    await waitFor(async () => {
      await expect(findByText('Mathmatics')).resolves.toBeInTheDocument()
    })
    await userEvent.click(await findByText('Mathmatics'))
    expect(queryByText('Import Blueprint Course settings')).toBeNull()
  })

  it('Does not render BP settings import option when the selected course is not a blueprint', async () => {
    const {queryByText} = renderComponent()
    await userEvent.type(screen.getByRole('combobox', {name: searchForACourse}), 'biol')
    await userEvent.click(await screen.findByText('Biology'))
    expect(queryByText('Import Blueprint Course settings')).toBeNull()
  })

  it('disable inputs while uploading', async () => {
    const {getByRole} = renderComponent({isSubmitting: true})
    await waitFor(() => {
      expect(getByRole('button', {name: 'Clear'})).toBeDisabled()
      expect(getByRole('button', {name: /Adding.../})).toBeDisabled()
      expect(getByRole('combobox', {name: searchForACourse})).toBeDisabled()
      expect(getByRole('radio', {name: /All content/})).toBeDisabled()
      expect(getByRole('radio', {name: 'Select specific content'})).toBeDisabled()
      expect(getByRole('checkbox', {name: 'Adjust events and due dates'})).toBeDisabled()
    })
  })

  it('disable "Adjust events and due dates" inputs while uploading', async () => {
    const {getByRole, rerender, getByLabelText} = renderComponent()

    await userEvent.click(getByRole('checkbox', {name: 'Adjust events and due dates'}))

    rerender(<CourseCopyImporter onSubmit={onSubmit} onCancel={onCancel} isSubmitting={true} />)

    await waitFor(() => {
      expect(getByRole('radio', {name: 'Shift dates'})).toBeInTheDocument()
      expect(getByRole('radio', {name: 'Shift dates'})).toBeDisabled()
      expect(getByRole('radio', {name: 'Remove dates'})).toBeDisabled()
      expect(getByLabelText('Select original beginning date')).toBeDisabled()
      expect(getByLabelText('Select new beginning date')).toBeDisabled()
      expect(getByLabelText('Select original end date')).toBeDisabled()
      expect(getByLabelText('Select new end date')).toBeDisabled()
      expect(getByRole('button', {name: 'Add substitution'})).toBeDisabled()
    })
  })

  sharedDateParsingTests(CourseCopyImporter)

  describe('source course adjust date field prefills', () => {
    const expectDateField = (dataCid: string, value: string) => {
      expect((screen.getByTestId(dataCid) as HTMLInputElement).value).toBe(value)
    }

    it('parse the date from found course start date', async () => {
      const {getByRole, findByText} = renderComponent()

      await userEvent.type(getByRole('combobox', {name: searchForACourse}), 'math')
      await userEvent.click(await findByText('Mathmatics'))
      await userEvent.click(getByRole('checkbox', {name: 'Adjust events and due dates'}))

      expectDateField('old_start_date', 'Oct 14 at 8pm')
    })

    it('parse the date from found course end date', async () => {
      const {getByRole, findByText} = renderComponent()

      await userEvent.type(getByRole('combobox', {name: searchForACourse}), 'math')
      await userEvent.click(await findByText('Mathmatics'))
      await userEvent.click(getByRole('checkbox', {name: 'Adjust events and due dates'}))

      expectDateField('old_end_date', 'Oct 16 at 8pm')
    })
  })

  describe('SHOW_SELECT behaviour', () => {
    describe('when enabled', () => {
      beforeEach(() => {
        fakeENV.setup({...defaultEnv, SHOW_SELECT: true})
      })

      it('should render the dropdown', () => {
        const {queryByRole} = renderComponent()
        expect(queryByRole('combobox', {name: selectACourse})).not.toBeNull()
      })

      it('should render the search field', () => {
        const {queryByRole} = renderComponent()
        expect(queryByRole('combobox', {name: searchForACourse})).not.toBeNull()
      })

      it('should be disabled initially', () => {
        const {getByRole} = renderComponent()
        expect(getByRole('combobox', {name: selectACourse})).toBeDisabled()
        expect(getByRole('combobox', {name: searchForACourse})).toBeDisabled()
      })

      it('should call the manageable_courses', async () => {
        renderComponent()

        await waitFor(() => {
          expect(doFetchApi).toHaveBeenCalledWith({
            path: '/users/0/manageable_courses?include=concluded',
          })
        })
      })

      it('should group the manageable course by terms', async () => {
        const {getByRole} = renderComponent()

        await waitFor(() => expect(getByRole('combobox', {name: selectACourse})).toBeEnabled())
        await userEvent.click(getByRole('combobox', {name: selectACourse}))

        const defaultTermGroup = getByRole('group', { name: /Default term/ })
        expect(defaultTermGroup).toBeInTheDocument()
        expect(within(defaultTermGroup).getByRole('option', {name: /Mathmatics/})).toBeInTheDocument()

        const otherTermGroup = getByRole('group', { name: /Other term/ })
        expect(otherTermGroup).toBeInTheDocument()
        expect(within(otherTermGroup).getByRole('option', {name: /Biology/})).toBeInTheDocument()
      })

      describe('select course via search field', () => {
        const populateSearchField = async () => {
          const component = renderComponent()

          await waitFor(() => {
            expect(component.getByRole('combobox', {name: searchForACourse})).toBeEnabled()
          })
          await userEvent.type(component.getByRole('combobox', {name: searchForACourse}), 'math')
          await userEvent.click(await component.findByText('Mathmatics'))
          return component
        }

        it('should set the same value for dropdown on search change', async () => {
          const component = await populateSearchField()
          expect((component.getByTestId('course-copy-select-preloaded-courses') as HTMLInputElement).value)
            .toBe('Mathmatics')
        })

        it('should clear the dropdown on search field change', async () => {
          const component = await populateSearchField()
          await userEvent.type(component.getByRole('combobox', {name: searchForACourse}), 'invalid')
          expect((component.getByTestId('course-copy-select-preloaded-courses') as HTMLInputElement).value)
            .toBe('')
        })

        it('should throw invalid message on empty selected course', async () => {
          const component = await populateSearchField()
          await userEvent.clear(component.getByTestId('course-copy-select-course'))
          await userEvent.click(component.getByRole('button', {name: addToImportQueue}))

          await waitFor(() => {
            expect(component.queryAllByText(/You must select a course to copy content from/)).toHaveLength(2)
          })
          expect(onSubmit).not.toHaveBeenCalled()
        })

        it('should send the selected course in submit', async () => {
          const component = await populateSearchField()
          await userEvent.click(component.getByRole('button', {name: addToImportQueue}))
          expect(onSubmit).toHaveBeenCalledWith(
            expect.objectContaining({
              settings: expect.objectContaining({
                source_course_id: '0',
              }),
            }),
          )
        })
      })

      describe('select course via preloaded course dropdown', () => {
        const openPreloadedCoursesDropdown = async () => {
          const component = renderComponent()

          await waitFor(() => {
            expect(component.getByRole('combobox', {name: selectACourse})).toBeEnabled()
          })
          await userEvent.click(component.getByRole('combobox', {name: selectACourse}))
          return component
        }

        it('should set the same value for search field on dropdown change', async () => {
          const component = await openPreloadedCoursesDropdown()
          await userEvent.click(component.getByRole('option', { name: /Mathmatics/ }))
          expect((component.getByTestId('course-copy-select-course') as HTMLInputElement).value)
            .toBe('Mathmatics')
        })

        it('should throw invalid message on empty selected course', async () => {
          const component = await openPreloadedCoursesDropdown()
          await userEvent.click(component.getByRole('button', {name: addToImportQueue}))

          expect(component.queryAllByText(/You must select a course to copy content from/)).toHaveLength(2)
          expect(onSubmit).not.toHaveBeenCalled()
        })

        it('should send the selected course in submit', async () => {
          const component = await openPreloadedCoursesDropdown()
          await userEvent.click(component.getByRole('option', { name: /Mathmatics/ }))
          await userEvent.click(component.getByRole('button', {name: addToImportQueue}))

          expect(onSubmit).toHaveBeenCalledWith(
            expect.objectContaining({
              settings: expect.objectContaining({
                source_course_id: '0',
              }),
            }),
          )
        })
      })
    })

    describe('when disabled', () => {
      beforeEach(() => {
        fakeENV.setup({...defaultEnv, SHOW_SELECT: false})
      })

      it('should not render the dropdown', () => {
        const {queryByRole} = renderComponent()
        expect(queryByRole('combobox', {name: selectACourse})).toBeNull()
      })

      it('should render the search field', () => {
        const {queryByRole} = renderComponent()
        expect(queryByRole('combobox', {name: searchForACourse})).not.toBeNull()
      })
    })
  })

  describe('course input error focus', () => {
    it('when SHOW_SELECT is false it focuses on input', async () => {
      fakeENV.setup({...defaultEnv, SHOW_SELECT: false})
      renderComponent()
      await userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))
      await waitFor(() => {
        expect(screen.getByTestId('course-copy-select-course')).toHaveFocus()
      })
    })

    it('when SHOW_SELECT is true it focuses on dropdown', async () => {
      fakeENV.setup({...defaultEnv, SHOW_SELECT: true})
      renderComponent()
      await userEvent.click(screen.getByRole('button', {name: 'Add to Import Queue'}))
      expect(screen.getByTestId('course-copy-select-preloaded-courses')).toHaveFocus()
    })
  })

  describe('URL crafting', () => {
    it('includes current_course_id in composeManageableCourseURL when ENV.COURSE_ID is set', async () => {
      fakeENV.setup({
        ...defaultEnv,
        COURSE_ID: '123'
      })

      renderComponent()

      await userEvent.type(screen.getByTestId('course-copy-select-course'), 'coursetest')


      await waitFor(() => {
        expect(doFetchApi).toHaveBeenCalledWith({
          path: '/users/0/manageable_courses?current_course_id=123&term=coursetest&include=concluded',
        })
      })
    })
  })
})
