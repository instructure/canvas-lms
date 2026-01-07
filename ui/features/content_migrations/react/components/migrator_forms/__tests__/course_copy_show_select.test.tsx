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
import fakeENV from '@canvas/test-utils/fakeENV'
import {within} from '@testing-library/dom'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const onSubmit = vi.fn()
const onCancel = vi.fn()

const fakeCourses = [
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
]

const server = setupServer(
  http.get('/users/:userId/manageable_courses', () => {
    return HttpResponse.json(fakeCourses)
  }),
)

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

describe('CourseCopyImporter SHOW_SELECT behaviour', () => {
  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    fakeENV.setup({...defaultEnv})
  })

  afterEach(() => {
    vi.clearAllMocks()
    fakeENV.teardown()
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

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
      const {getByRole} = renderComponent()

      await waitFor(() => {
        expect(getByRole('combobox', {name: selectACourse})).toBeEnabled()
      })
    })

    it('should group the manageable course by terms', async () => {
      const {getByRole} = renderComponent()

      await waitFor(() => expect(getByRole('combobox', {name: selectACourse})).toBeEnabled())
      await userEvent.click(getByRole('combobox', {name: selectACourse}))

      const defaultTermGroup = getByRole('group', {name: /Default term/})
      expect(defaultTermGroup).toBeInTheDocument()
      expect(within(defaultTermGroup).getByRole('option', {name: /Mathmatics/})).toBeInTheDocument()

      const otherTermGroup = getByRole('group', {name: /Other term/})
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
        expect(
          (component.getByTestId('course-copy-select-preloaded-courses') as HTMLInputElement).value,
        ).toBe('Mathmatics')
      })

      it('should clear the dropdown on search field change', async () => {
        const component = await populateSearchField()
        await userEvent.type(component.getByRole('combobox', {name: searchForACourse}), 'invalid')
        await waitFor(() => {
          expect(
            (component.getByTestId('course-copy-select-preloaded-courses') as HTMLInputElement)
              .value,
          ).toBe('')
        })
      })

      it('should throw invalid message on empty selected course', async () => {
        const component = await populateSearchField()
        await userEvent.clear(component.getByTestId('course-copy-select-course'))
        await userEvent.click(component.getByRole('button', {name: addToImportQueue}))

        await waitFor(() => {
          expect(
            component.queryAllByText(/You must select a course to copy content from/),
          ).toHaveLength(2)
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
        await userEvent.click(component.getByRole('option', {name: /Mathmatics/}))
        expect((component.getByTestId('course-copy-select-course') as HTMLInputElement).value).toBe(
          'Mathmatics',
        )
      })

      it('should throw invalid message on empty selected course', async () => {
        const component = await openPreloadedCoursesDropdown()
        await userEvent.click(component.getByRole('button', {name: addToImportQueue}))

        expect(
          component.queryAllByText(/You must select a course to copy content from/),
        ).toHaveLength(2)
        expect(onSubmit).not.toHaveBeenCalled()
      })

      it('should send the selected course in submit', async () => {
        const component = await openPreloadedCoursesDropdown()
        await userEvent.click(component.getByRole('option', {name: /Mathmatics/}))
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
