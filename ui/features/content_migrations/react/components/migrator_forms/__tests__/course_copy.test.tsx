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
import {sharedDateParsingTests} from './shared_form_cases'
import fakeENV from '@canvas/test-utils/fakeENV'
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
  http.get('/api/v1/courses/:courseId/late_policy', () => {
    return HttpResponse.json({late_policy: {missing_submission_deduction_enabled: false}})
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

describe('CourseCopyImporter', () => {
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

  it('searches for matching courses and includes concluded by default', async () => {
    const {getByText} = renderComponent()
    await userEvent.type(screen.getByTestId('course-copy-select-course'), 'math')
    await waitFor(() => {
      expect(getByText('Mathmatics')).toBeInTheDocument()
    })
  })

  it('searches for matching courses and display proper terms', async () => {
    const {getByText} = renderComponent()
    await userEvent.type(screen.getByTestId('course-copy-select-course'), 'math')
    await waitFor(() => {
      expect(getByText('Term: Default term')).toBeInTheDocument()
    })
    expect(getByText('Term: Other term')).toBeInTheDocument()
  })

  it('searches for matching courses excluding concluded', async () => {
    renderComponent()
    await userEvent.click(screen.getByLabelText('Include completed courses'))
    await userEvent.type(screen.getByTestId('course-copy-select-course'), 'math')
    await waitFor(() => {
      expect(screen.getByText('Mathmatics')).toBeInTheDocument()
    })
  })

  it('calls onSubmit', async () => {
    const {findByText} = renderComponent()
    await userEvent.type(screen.getByTestId('course-copy-select-course'), 'math')
    await userEvent.click(await findByText('Mathmatics'))
    await userEvent.click(screen.getByTestId('submitMigration'))
    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({
        settings: expect.objectContaining({
          source_course_id: '0',
        }),
      }),
    )
  })

  it('calls onCancel', async () => {
    renderComponent()
    await userEvent.click(screen.getByTestId('clear-migration-button'))
    expect(onCancel).toHaveBeenCalled()
  })

  // The testing of onCancel and onSubmit above need the actual common migrator controls
  // So instead of mocking it here and testing the prop being passed to the mock
  // we're following the precedent and testing all the way to the child in this suite
  it('Renders BP settings import option if appropriate', async () => {
    const {findByText, getByText} = renderComponent()
    await userEvent.type(screen.getByTestId('course-copy-select-course'), 'math')
    await userEvent.click(await findByText('Mathmatics'))
    await expect(await getByText('Import Blueprint Course settings')).toBeInTheDocument()
  })

  it('Does not renders BP settings import option when the destination course is marked ineligible', async () => {
    fakeENV.setup({...defaultEnv, SHOW_BP_SETTINGS_IMPORT_OPTION: false})
    const {findByText, queryByText} = renderComponent()
    await userEvent.type(screen.getByTestId('course-copy-select-course'), 'math')
    await waitFor(async () => {
      await expect(findByText('Mathmatics')).resolves.toBeInTheDocument()
    })
    await userEvent.click(await findByText('Mathmatics'))
    expect(queryByText('Import Blueprint Course settings')).toBeNull()
  })

  it('Does not render BP settings import option when the selected course is not a blueprint', async () => {
    const {queryByText} = renderComponent()
    await userEvent.type(screen.getByTestId('course-copy-select-course'), 'biol')
    await userEvent.click(await screen.findByText('Biology'))
    expect(queryByText('Import Blueprint Course settings')).toBeNull()
  })

  describe('Missing Policy Warning Modal', () => {
    beforeEach(() => {
      fakeENV.setup({
        ...defaultEnv,
        MISSING_POLICY_ENABLED: true,
        COURSE_ID: '123',
      })
    })

    it('shows warning modal when missing policy is enabled and dates not adjusted', async () => {
      const {findByText} = renderComponent()
      await userEvent.type(screen.getByTestId('course-copy-select-course'), 'math')
      await userEvent.click(await findByText('Mathmatics'))
      await userEvent.click(screen.getByTestId('submitMigration'))

      await waitFor(() => {
        expect(screen.getByTestId('missing-policy-warning-modal')).toBeInTheDocument()
      })
      expect(
        screen.getByText('Warning: This course has Automatic Missing Policy enabled'),
      ).toBeInTheDocument()
    })

    it('does not show warning modal when adjust dates is enabled', async () => {
      const {findByText} = renderComponent()
      await userEvent.type(screen.getByTestId('course-copy-select-course'), 'math')
      await userEvent.click(await findByText('Mathmatics'))
      await userEvent.click(screen.getByTestId('date-adjust-checkbox'))
      await userEvent.click(screen.getByTestId('submitMigration'))

      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalled()
      })
      expect(screen.queryByTestId('missing-policy-warning-modal')).not.toBeInTheDocument()
    })

    it('does not show warning modal when missing policy is not enabled', async () => {
      fakeENV.setup({
        ...defaultEnv,
        MISSING_POLICY_ENABLED: false,
        COURSE_ID: '123',
      })

      const {findByText} = renderComponent()
      await userEvent.type(screen.getByTestId('course-copy-select-course'), 'math')
      await userEvent.click(await findByText('Mathmatics'))
      await userEvent.click(screen.getByTestId('submitMigration'))

      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalled()
      })
      expect(screen.queryByTestId('missing-policy-warning-modal')).not.toBeInTheDocument()
    })

    it('submits import when Import Anyway is clicked', async () => {
      const {findByText} = renderComponent()
      await userEvent.type(screen.getByTestId('course-copy-select-course'), 'math')
      await userEvent.click(await findByText('Mathmatics'))
      await userEvent.click(screen.getByTestId('submitMigration'))

      await waitFor(() => {
        expect(screen.getByTestId('missing-policy-warning-modal')).toBeInTheDocument()
      })

      await userEvent.click(screen.getByTestId('import-anyway-button'))

      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalled()
      })
    })

    it('disables policy and submits import with LatePolicy skipped when Disable Policy is clicked', async () => {
      server.use(
        http.patch('/api/v1/courses/123/late_policy', () => {
          return HttpResponse.json({late_policy: {missing_submission_deduction_enabled: false}})
        }),
      )

      const {findByText} = renderComponent()
      await userEvent.type(screen.getByTestId('course-copy-select-course'), 'math')
      await userEvent.click(await findByText('Mathmatics'))
      await userEvent.click(screen.getByTestId('submitMigration'))

      await waitFor(() => {
        expect(screen.getByTestId('missing-policy-warning-modal')).toBeInTheDocument()
      })

      await userEvent.click(screen.getByTestId('disable-policy-button'))

      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalled()
      })

      const submittedData = onSubmit.mock.calls[0][0]
      expect(submittedData.settings.importer_skips).toContain('LatePolicy')
    })

    it('cancels import when Cancel is clicked in modal', async () => {
      const {findByText} = renderComponent()
      await userEvent.type(screen.getByTestId('course-copy-select-course'), 'math')
      await userEvent.click(await findByText('Mathmatics'))
      await userEvent.click(screen.getByTestId('submitMigration'))

      await waitFor(() => {
        expect(screen.getByTestId('missing-policy-warning-modal')).toBeInTheDocument()
      })

      await userEvent.click(screen.getByTestId('cancel-button'))

      await waitFor(() => {
        expect(screen.queryByTestId('missing-policy-warning-modal')).not.toBeInTheDocument()
      })
      expect(onSubmit).not.toHaveBeenCalled()
    })

    it('shows warning when source course has missing policy enabled', async () => {
      server.use(
        http.get('/api/v1/courses/0/late_policy', () => {
          return HttpResponse.json({late_policy: {missing_submission_deduction_enabled: true}})
        }),
      )

      fakeENV.setup({
        ...defaultEnv,
        MISSING_POLICY_ENABLED: false,
        COURSE_ID: '123',
      })

      const {findByText} = renderComponent()
      await userEvent.type(screen.getByTestId('course-copy-select-course'), 'math')
      await userEvent.click(await findByText('Mathmatics'))

      await waitFor(() => {
        expect(screen.getByTestId('submitMigration')).not.toBeDisabled()
      })

      await userEvent.click(screen.getByTestId('submitMigration'))

      await waitFor(() => {
        expect(screen.getByTestId('missing-policy-warning-modal')).toBeInTheDocument()
      })
      expect(
        screen.getByText(/importing from a course with Automatic Missing Policy enabled/),
      ).toBeInTheDocument()
    })

    it("skips importing late policy when Don't Import Policy is clicked", async () => {
      server.use(
        http.get('/api/v1/courses/0/late_policy', () => {
          return HttpResponse.json({late_policy: {missing_submission_deduction_enabled: true}})
        }),
      )

      fakeENV.setup({
        ...defaultEnv,
        MISSING_POLICY_ENABLED: false,
        COURSE_ID: '123',
      })

      const {findByText} = renderComponent()
      await userEvent.type(screen.getByTestId('course-copy-select-course'), 'math')
      await userEvent.click(await findByText('Mathmatics'))

      await waitFor(() => {
        expect(screen.getByTestId('submitMigration')).not.toBeDisabled()
      })

      await userEvent.click(screen.getByTestId('submitMigration'))

      await waitFor(() => {
        expect(screen.getByTestId('missing-policy-warning-modal')).toBeInTheDocument()
      })

      await userEvent.click(screen.getByTestId('disable-policy-button'))

      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalled()
      })

      const submittedData = onSubmit.mock.calls[0][0]
      expect(submittedData.settings.importer_skips).toContain('LatePolicy')
    })

    it('shows warning and handles both courses having missing policy', async () => {
      server.use(
        http.get('/api/v1/courses/0/late_policy', () => {
          return HttpResponse.json({late_policy: {missing_submission_deduction_enabled: true}})
        }),
        http.patch('/api/v1/courses/123/late_policy', () => {
          return HttpResponse.json({late_policy: {missing_submission_deduction_enabled: false}})
        }),
      )

      const {findByText} = renderComponent()
      await userEvent.type(screen.getByTestId('course-copy-select-course'), 'math')
      await userEvent.click(await findByText('Mathmatics'))

      await waitFor(() => {
        expect(screen.getByTestId('submitMigration')).not.toBeDisabled()
      })

      await userEvent.click(screen.getByTestId('submitMigration'))

      await waitFor(() => {
        expect(screen.getByTestId('missing-policy-warning-modal')).toBeInTheDocument()
      })
      expect(
        screen.getByText('Warning: Both courses have Automatic Missing Policy enabled'),
      ).toBeInTheDocument()

      await userEvent.click(screen.getByTestId('disable-policy-button'))

      await waitFor(() => {
        expect(onSubmit).toHaveBeenCalled()
      })

      const submittedData = onSubmit.mock.calls[0][0]
      expect(submittedData.settings.importer_skips).toContain('LatePolicy')
    })
  })

  sharedDateParsingTests(CourseCopyImporter)
})
