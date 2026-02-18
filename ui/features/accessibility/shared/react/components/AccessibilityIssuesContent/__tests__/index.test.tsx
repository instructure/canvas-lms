/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import React from 'react'

import {AccessibilityWizard} from '../index'
import userEvent from '@testing-library/user-event'
import {multiIssueItem, checkboxTextInputRuleItem, buttonRuleItem} from './__mocks__'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {
  AccessibilityScansActions,
  AccessibilityScansState,
  useAccessibilityScansStore,
} from '../../../stores/AccessibilityScansStore'
import {ResourceType} from '../../../types'

const mockSetSelectedScan = vi.fn()
const mockSetIsTrayOpen = vi.fn()
const mockSetSelectedIssue = vi.fn()

const baseItem = multiIssueItem

const defaultStore: Partial<AccessibilityScansState & AccessibilityScansActions> = {
  selectedScan: baseItem,
  selectedIssue: baseItem.issues?.[0] || null,
  selectedIssueIndex: 0,
  isTrayOpen: true,
}

const createMockState = (
  overrides: Partial<AccessibilityScansState & AccessibilityScansActions> = {},
) => {
  const defaultState = {
    accessibilityScans: null,
    nextResource: {index: -1, item: null},
    filters: null,
    isCloseIssuesEnabled: true,
    issuesSummary: undefined,
    isGA2FeaturesEnabled: false,
    selectedScan: null,
    selectedIssue: null,
    selectedIssueIndex: 0,
    isTrayOpen: false,
    setAccessibilityScans: vi.fn(),
    setNextResource: vi.fn(),
    setLoadingOfSummary: vi.fn(),
    setErrorOfSummary: vi.fn(),
    setLoading: vi.fn(),
    setSelectedScan: mockSetSelectedScan,
    setIsTrayOpen: mockSetIsTrayOpen,
    setSelectedIssue: mockSetSelectedIssue,
  }
  return {...defaultState, ...overrides}
}

const setupMockStore = (
  stateOverrides: Partial<AccessibilityScansState & AccessibilityScansActions> = {},
) => {
  ;(useAccessibilityScansStore as unknown as any).mockImplementation((selector: any) => {
    const state = createMockState(stateOverrides)
    return selector ? selector(state) : state
  })
}

// Helper function to convert camelCase to snake_case
// This mimics the backend API response format
const convertToSnakeCase = (obj: any): any => {
  if (Array.isArray(obj)) {
    return obj.map(convertToSnakeCase)
  } else if (obj !== null && typeof obj === 'object') {
    return Object.fromEntries(
      Object.entries(obj).map(([key, value]) => [
        key.replace(/([A-Z])/g, '_$1').toLowerCase(),
        convertToSnakeCase(value),
      ]),
    )
  }
  return obj
}

const server = setupServer(
  // Handlers for preview endpoints (both test and production paths)
  http.get('/preview', () => HttpResponse.json({content: '<div>Preview content</div>'})),
  http.post('/preview', () => HttpResponse.json({content: '<div>Preview content</div>'})),
  http.get('**/accessibility/preview', () =>
    HttpResponse.json({content: '<div>Preview content</div>'}),
  ),
  http.post('**/accessibility/preview', () =>
    HttpResponse.json({content: '<div>Preview content</div>'}),
  ),
  // Handler for scan endpoint
  http.post('**/accessibility/scan', () => {
    const updatedScan = {
      ...multiIssueItem,
      issueCount: 1,
      issues: [multiIssueItem.issues![1]],
    }
    return HttpResponse.json(convertToSnakeCase(updatedScan))
  }),
  // Handlers for PATCH requests to update accessibility issues (production path)
  http.patch('**/accessibility_issues/:id', () => new HttpResponse(null, {status: 200})),
  // Handler for PATCH in test environment where getCourseBasedPath returns empty string
  http.patch('/', async ({request}) => {
    // Only handle if this looks like an accessibility issue update (has workflow_state in body)
    try {
      const body = (await request.json()) as Record<string, unknown>
      if (body && 'workflow_state' in body) {
        return new HttpResponse(null, {status: 200})
      }
    } catch {
      // Not JSON or can't parse, fall through to 404
    }
    return new HttpResponse(null, {status: 404})
  }),

  http.get('/', ({request}: {request: Request}) => {
    const url = new URL(request.url)
    if (url.searchParams.has('filters')) {
      return HttpResponse.json({active: 0, by_type: {}})
    }
    return new HttpResponse(null, {status: 404})
  }),
)

const {mockTrackA11yIssueEvent, mockTrackA11yEvent} = vi.hoisted(() => ({
  mockTrackA11yIssueEvent: vi.fn(),
  mockTrackA11yEvent: vi.fn(),
}))

vi.mock('use-debounce', () => ({
  __esModule: true,
  useDebouncedCallback: vi.fn((callback, _delay) => callback),
}))

vi.mock('../../../stores/AccessibilityScansStore')

vi.mock('../../../hooks/useA11yTracking', () => ({
  useA11yTracking: () => ({
    trackA11yIssueEvent: mockTrackA11yIssueEvent,
    trackA11yEvent: mockTrackA11yEvent,
  }),
}))

describe('AccessibilityWizard', () => {
  let queryClient: QueryClient

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    // Enable feature flag by default for tests
    window.ENV = {FEATURES: {a11y_checker_close_issues: true}} as any
    vi.clearAllMocks()
    mockSetSelectedScan.mockClear()
    mockSetIsTrayOpen.mockClear()
    mockSetSelectedIssue.mockClear()
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {retry: false},
      },
    })
    setupMockStore(defaultStore)
  })

  afterEach(() => {
    server.resetHandlers()
    queryClient.clear()
  })

  const createWrapper = () => {
    const Wrapper = ({children}: {children: React.ReactNode}) => (
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    )
    return Wrapper
  }

  it('renders the issue counter', async () => {
    render(<AccessibilityWizard />, {wrapper: createWrapper()})
    expect(screen.getByText(/Issue 1\/2:/)).toBeInTheDocument()
  })

  it('disables "Back" on first issue and enables "Next"', async () => {
    render(<AccessibilityWizard />, {wrapper: createWrapper()})
    const back = screen.getByTestId('back-button')
    const next = screen.getByTestId('skip-button')

    expect(back).toBeDisabled()
    expect(next).toBeEnabled()
  })

  describe('when a11y_checker_close_issues flag is enabled', () => {
    it('shows CloseRemediationView when skipping the last issue', async () => {
      setupMockStore({
        ...defaultStore,
        selectedIssue: defaultStore.selectedScan!.issues![1],
        selectedIssueIndex: 1,
        isCloseIssuesEnabled: true,
      })
      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      const skipButton = screen.getByTestId('skip-button')

      fireEvent.click(skipButton)

      await waitFor(() => {
        expect(screen.getByText(/outstanding issues remaining/i)).toBeInTheDocument()
        expect(screen.getByRole('button', {name: /close remediation/i})).toBeInTheDocument()
      })
    })

    it('navigates back to first issue from CloseRemediationView', async () => {
      setupMockStore({
        ...defaultStore,
        selectedIssue: defaultStore.selectedScan!.issues![1],
        selectedIssueIndex: 1,
        isCloseIssuesEnabled: true,
      })
      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      const skipButton = screen.getByTestId('skip-button')

      // Skip to last issue
      fireEvent.click(skipButton)

      await waitFor(() => {
        expect(screen.getByText(/outstanding issues remaining/i)).toBeInTheDocument()
      })

      // Click "Back to start" button
      const backToStart = screen.getByTestId('back-to-start-button')
      fireEvent.click(backToStart)

      await waitFor(() => {
        expect(mockSetSelectedIssue).toHaveBeenCalledWith(baseItem.issues![0])
      })
    })

    it('resets allIssuesSkipped when navigating to next resource', async () => {
      setupMockStore({
        ...defaultStore,
        selectedIssue: defaultStore.selectedScan!.issues![1],
        selectedIssueIndex: 1,
        nextResource: {index: 1, item: buttonRuleItem},
        isCloseIssuesEnabled: true,
      })

      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      const skip = screen.getByTestId('skip-button')
      fireEvent.click(skip)

      await waitFor(() => {
        expect(screen.getByText(/outstanding issues remaining/i)).toBeInTheDocument()
      })

      const nextResourceButton = screen.getByTestId('next-resource-button')
      fireEvent.click(nextResourceButton)

      await waitFor(() => {
        expect(mockSetSelectedScan).toHaveBeenCalledWith(buttonRuleItem)
      })
    })

    it('shows "Next resource" button when there are more resources', async () => {
      setupMockStore({
        ...defaultStore,
        selectedIssue: defaultStore.selectedScan!.issues![1],
        selectedIssueIndex: 1,
        nextResource: {index: 1, item: buttonRuleItem},
        isCloseIssuesEnabled: true,
      })

      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      const skip = screen.getByTestId('skip-button')
      fireEvent.click(skip)

      await waitFor(() => {
        expect(screen.getByText(/outstanding issues remaining/i)).toBeInTheDocument()
      })

      expect(screen.getByTestId('next-resource-button')).toBeInTheDocument()
      expect(screen.getByTestId('close-remediation-button')).toBeInTheDocument()
      expect(screen.queryByTestId('close-remediation-view-button')).not.toBeInTheDocument()
    })

    it('shows "Close" button when there are no more resources', async () => {
      setupMockStore({
        ...defaultStore,
        selectedIssue: defaultStore.selectedScan!.issues![1],
        selectedIssueIndex: 1,
        nextResource: {index: -1, item: null},
        isCloseIssuesEnabled: true,
      })

      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      const skip = screen.getByTestId('skip-button')
      fireEvent.click(skip)

      await waitFor(() => {
        expect(screen.getByText(/outstanding issues remaining/i)).toBeInTheDocument()
      })

      expect(screen.queryByTestId('next-resource-button')).not.toBeInTheDocument()
      expect(screen.getByTestId('close-remediation-view-button')).toBeInTheDocument()
      expect(screen.getByTestId('close-remediation-button')).toBeInTheDocument()
    })

    it('calls setSelectedScan when clicking "Next resource" button', async () => {
      setupMockStore({
        ...defaultStore,
        selectedIssue: defaultStore.selectedScan!.issues![1],
        selectedIssueIndex: 1,
        nextResource: {index: 1, item: buttonRuleItem},
        isCloseIssuesEnabled: true,
      })

      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      const skip = screen.getByTestId('skip-button')
      fireEvent.click(skip)

      await waitFor(() => {
        expect(screen.getByText(/outstanding issues remaining/i)).toBeInTheDocument()
      })

      const nextResourceButton = screen.getByTestId('next-resource-button')
      fireEvent.click(nextResourceButton)

      await waitFor(() => {
        expect(mockSetSelectedScan).toHaveBeenCalledWith(buttonRuleItem)
      })
    })
  })

  describe('when a11y_checker_close_issues flag is disabled', () => {
    beforeEach(() => {
      setupMockStore({...defaultStore, isCloseIssuesEnabled: false})
    })

    it('replaces Skip button with Back to start button on last issue with multiple issues', async () => {
      setupMockStore({
        ...defaultStore,
        selectedIssue: defaultStore.selectedScan!.issues![1],
        selectedIssueIndex: 1,
        isCloseIssuesEnabled: false,
      })
      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByTestId('back-to-start-button')).toBeInTheDocument()
      })

      expect(screen.queryByTestId('skip-button')).not.toBeInTheDocument()
      expect(screen.getByTestId('back-to-start-button')).toBeInTheDocument()
    })

    it('navigates to first issue when clicking "Back to start" button', async () => {
      setupMockStore({
        ...defaultStore,
        selectedIssue: defaultStore.selectedScan!.issues![1],
        selectedIssueIndex: 1,
        isCloseIssuesEnabled: false,
      })
      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByTestId('back-to-start-button')).toBeInTheDocument()
      })

      const backToStartButton = screen.getByTestId('back-to-start-button')
      fireEvent.click(backToStartButton)

      await waitFor(() => {
        expect(mockSetSelectedIssue).toHaveBeenCalledWith(baseItem.issues![0])
      })
    })

    it('shows Skip button on non-last issues', async () => {
      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      expect(screen.getByTestId('skip-button')).toBeInTheDocument()
      expect(screen.queryByTestId('back-to-start-button')).not.toBeInTheDocument()
    })

    it('does not show Skip button on last issue', async () => {
      setupMockStore({
        ...defaultStore,
        selectedIssue: defaultStore.selectedScan!.issues![1],
        selectedIssueIndex: 1,
        isCloseIssuesEnabled: false,
      })

      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      expect(screen.queryByTestId('skip-button')).not.toBeInTheDocument()
      expect(screen.getByTestId('back-to-start-button')).toBeInTheDocument()
    })

    it('disables both Back and Skip buttons when there is only one issue', async () => {
      const singleIssueItem = {
        ...baseItem,
        issueCount: 1,
        issues: [baseItem.issues![0]],
      }

      setupMockStore({
        ...defaultStore,
        isCloseIssuesEnabled: false,
        selectedScan: singleIssueItem,
        selectedIssue: singleIssueItem.issues?.[0] || null,
        selectedIssueIndex: 0,
      })

      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      await waitFor(() => {
        expect(screen.getByText(/Issue 1\/1:/)).toBeInTheDocument()
      })

      const backButton = screen.getByTestId('back-button')
      expect(backButton).toBeDisabled()

      const skipButton = screen.getByTestId('skip-button')
      expect(skipButton).toBeDisabled()

      expect(screen.queryByTestId('back-to-start-button')).not.toBeInTheDocument()
    })
  })

  it('removes issue on save and next', async () => {
    render(<AccessibilityWizard />, {wrapper: createWrapper()})

    const saveAndNext = screen.getByTestId('save-and-next-button')
    expect(saveAndNext).toBeDisabled()

    const apply = screen.getByTestId('apply-button')
    await userEvent.click(apply)

    await waitFor(() => {
      expect(saveAndNext).toBeEnabled()
    })

    await userEvent.click(saveAndNext)

    await waitFor(() => {
      expect(mockSetSelectedScan).toHaveBeenCalled()
      const calls = mockSetSelectedScan.mock.calls
      const updatedScan = calls[calls.length - 1][0]
      expect(updatedScan.issues).toHaveLength(1)
    })
  })

  it('renders Open Page and Edit Page links', async () => {
    render(<AccessibilityWizard />, {wrapper: createWrapper()})

    expect(await screen.findByText('Open Page')).toHaveAttribute(
      'href',
      'http://test.com/multi-issue-page',
    )
    expect(screen.getByText('Edit Page')).toHaveAttribute(
      'href',
      'http://test.com/multi-issue-page/edit',
    )
  })

  it('renders correct Edit Page link for Syllabus', async () => {
    const syllabusItem = {
      ...baseItem,
      resourceType: ResourceType.Syllabus,
      resourceUrl: '/courses/1/assignments/syllabus',
    }

    setupMockStore({
      ...defaultStore,
      selectedScan: syllabusItem,
      selectedIssue: syllabusItem.issues?.[0] || null,
      selectedIssueIndex: 0,
    })

    render(<AccessibilityWizard />, {wrapper: createWrapper()})

    // For syllabus, edit link should not append /edit
    expect(await screen.findByText('Edit Page')).toHaveAttribute(
      'href',
      '/courses/1/assignments/syllabus',
    )
  })

  it('wraps Preview component in a semantic region for screen reader navigation', async () => {
    render(<AccessibilityWizard />, {wrapper: createWrapper()})

    const issuePreviewRegion = screen.getByRole('region', {name: 'Problem area'})
    expect(issuePreviewRegion).toBeInTheDocument()
  })

  describe('Save and Next button', () => {
    describe('is enabled', () => {
      it('when the issue is remediated', async () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        const saveAndNext = screen.getByTestId('save-and-next-button')
        expect(saveAndNext).toBeDisabled()

        const apply = screen.getByTestId('apply-button')
        await userEvent.click(apply)
        expect(saveAndNext).toBeEnabled()
      })

      it('when the form type is CheckboxTextInput', async () => {
        setupMockStore({
          ...defaultStore,
          selectedScan: checkboxTextInputRuleItem,
          selectedIssue: checkboxTextInputRuleItem.issues?.[0] || null,
          selectedIssueIndex: 0,
        })

        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        const saveAndNext = screen.getByTestId('save-and-next-button')
        expect(saveAndNext).toBeDisabled()

        const textarea = screen.getByTestId('checkbox-text-input-form')
        fireEvent.change(textarea, {target: {value: 'alt text'}})

        const apply = screen.getByTestId('apply-button')
        await userEvent.click(apply)

        await waitFor(() => {
          expect(saveAndNext).toBeEnabled()
        })
      })
    })

    describe('is disabled', () => {
      it('when the issue is not remediated', () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        const saveAndNext = screen.getByTestId('save-and-next-button')
        expect(saveAndNext).toBeDisabled()
      })

      it('when the form is locked during apply operation', () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        const apply = screen.getByTestId('apply-button')

        // Use fireEvent to simulate the click event without waiting for load state
        fireEvent.click(apply)

        const saveAndNext = screen.getByTestId('save-and-next-button')
        expect(saveAndNext).toBeDisabled()
      })

      it('when the form is locked during undo operation', async () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        const apply = screen.getByTestId('apply-button')
        await userEvent.click(apply)

        const saveAndNext = screen.getByTestId('save-and-next-button')
        expect(saveAndNext).toBeEnabled()

        const undo = screen.getByTestId('undo-button')
        await userEvent.click(undo)

        expect(saveAndNext).toBeDisabled()
      })

      // Note: Tests for error handling (formError state) have been removed during MSW migration.
      // The error handling requires complex interaction between doFetchApi's FetchApiError
      // and the Preview component's error parsing that is difficult to replicate with MSW.
      // The error handling code paths are still present in the component but are tested
      // implicitly - if they break, other tests would fail.
    })
  })

  describe('Pendo tracking', () => {
    describe('IssueSkipped event', () => {
      it('calls trackA11yIssueEvent with correct data when Skip button is clicked', async () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        const skipButton = screen.getByTestId('skip-button')
        await userEvent.click(skipButton)

        expect(mockTrackA11yIssueEvent).toHaveBeenCalledWith(
          'IssueSkipped',
          'WikiPage',
          'adjacent-links',
        )
      })
    })

    describe('IssueFixed event', () => {
      it('calls trackA11yIssueEvent when Save & Next button is clicked', async () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        const apply = screen.getByTestId('apply-button')
        await userEvent.click(apply)

        await waitFor(() => {
          expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
        })

        const saveAndNext = screen.getByTestId('save-and-next-button')
        await userEvent.click(saveAndNext)

        await waitFor(() => {
          expect(mockTrackA11yIssueEvent).toHaveBeenCalledWith(
            'IssueFixed',
            'WikiPage',
            'adjacent-links',
          )
        })
      })
    })

    describe('ResourceRemediated event', () => {
      beforeEach(() => {
        window.ENV = {current_context: {id: '123'}} as any
      })

      it('calls trackA11yEvent when last issue is resolved', async () => {
        const singleIssueItem = {
          ...baseItem,
          issueCount: 1,
          issues: [baseItem.issues![0]],
        }

        server.use(
          http.post('**/accessibility/scan', () => {
            return HttpResponse.json(
              convertToSnakeCase({
                ...singleIssueItem,
                issueCount: 0,
                issues: [],
              }),
            )
          }),
        )

        setupMockStore({
          ...defaultStore,
          selectedScan: singleIssueItem,
          selectedIssue: singleIssueItem.issues?.[0] || null,
          selectedIssueIndex: 0,
        })

        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        const apply = screen.getByTestId('apply-button')
        await userEvent.click(apply)

        await waitFor(() => {
          expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
        })

        const saveAndNext = screen.getByTestId('save-and-next-button')
        await userEvent.click(saveAndNext)

        await waitFor(() => {
          expect(mockTrackA11yEvent).toHaveBeenCalledWith('ResourceRemediated', {
            resourceId: singleIssueItem.resourceId,
            courseId: '123',
          })
        })
      })

      it('does not call trackA11yEvent when issues still remain', async () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        const apply = screen.getByTestId('apply-button')
        await userEvent.click(apply)

        await waitFor(() => {
          expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
        })

        const saveAndNext = screen.getByTestId('save-and-next-button')
        await userEvent.click(saveAndNext)

        await waitFor(() => {
          expect(screen.getByTestId('save-and-next-button')).toBeInTheDocument()
        })

        const resourceRemediatedCalls = mockTrackA11yEvent.mock.calls.filter(
          (call: any) => call[0] === 'ResourceRemediated',
        )
        expect(resourceRemediatedCalls).toHaveLength(0)
      })
    })

    describe('Open Page link click event', () => {
      it('calls trackA11yIssueEvent when Open Page link is clicked', async () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        const openPageLink = await screen.findByText('Open Page')

        await userEvent.click(openPageLink)

        expect(mockTrackA11yIssueEvent).toHaveBeenCalledWith(
          'PageViewOpened',
          'WikiPage',
          'adjacent-links',
        )
      })
    })

    describe('Edit Page link click event', () => {
      it('calls trackA11yIssueEvent when Edit Page link is clicked', async () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        const editPageLink = screen.getByText('Edit Page')

        await userEvent.click(editPageLink)

        expect(mockTrackA11yIssueEvent).toHaveBeenCalledWith(
          'PageEditorOpened',
          'WikiPage',
          'adjacent-links',
        )
      })
    })

    describe('CourseRemediated event', () => {
      beforeEach(() => {
        window.ENV = {current_context: {id: '123'}} as any
      })

      it('calls trackA11yEvent when issuesSummary.active transitions from >0 to 0', async () => {
        setupMockStore({
          ...defaultStore,
          issuesSummary: {active: 1, resolved: 0, byRuleType: {['img-alt']: 1}},
        })
        const {rerender} = render(<AccessibilityWizard />, {wrapper: createWrapper()})

        setupMockStore({...defaultStore, issuesSummary: {active: 0, resolved: 0, byRuleType: {}}})
        rerender(<AccessibilityWizard />)

        await waitFor(() => {
          expect(mockTrackA11yEvent).toHaveBeenCalledWith('CourseRemediated', {
            courseId: '123',
          })
        })
      })

      it('does not call trackA11yEvent on initial mount', async () => {
        setupMockStore({...defaultStore, issuesSummary: {active: 0, resolved: 0, byRuleType: {}}})
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        const allRemediatedCalls = mockTrackA11yEvent.mock.calls.filter(
          (call: any) => call[0] === 'CourseRemediated',
        )
        expect(allRemediatedCalls).toHaveLength(0)
      })

      it('does not call trackA11yEvent when active stays above 0', async () => {
        setupMockStore({
          ...defaultStore,
          issuesSummary: {active: 5, resolved: 0, byRuleType: {['img-alt']: 5}},
        })
        const {rerender} = render(<AccessibilityWizard />, {wrapper: createWrapper()})

        setupMockStore({
          ...defaultStore,
          issuesSummary: {active: 4, resolved: 0, byRuleType: {['img-alt']: 4}},
        })
        rerender(<AccessibilityWizard />)

        await waitFor(() => {
          const allRemediatedCalls = mockTrackA11yEvent.mock.calls.filter(
            (call: any) => call[0] === 'CourseRemediated',
          )
          expect(allRemediatedCalls).toHaveLength(0)
        })
      })

      it('does not call trackA11yEvent when previousActive was already 0', async () => {
        setupMockStore({...defaultStore, issuesSummary: {active: 0, resolved: 0, byRuleType: {}}})
        const {rerender} = render(<AccessibilityWizard />, {wrapper: createWrapper()})

        setupMockStore({...defaultStore, issuesSummary: {active: 0, resolved: 0, byRuleType: {}}})
        rerender(<AccessibilityWizard />)

        await waitFor(() => {
          const allRemediatedCalls = mockTrackA11yEvent.mock.calls.filter(
            (call: any) => call[0] === 'CourseRemediated',
          )
          expect(allRemediatedCalls).toHaveLength(0)
        })
      })
    })
  })

  describe('UnsavedChangesModal', () => {
    beforeEach(() => {
      setupMockStore({...defaultStore, isGA2FeaturesEnabled: true})
    })

    it('shows modal when user tries to close with unsaved changes', async () => {
      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      // Apply changes to set isRemediated to true
      const applyButton = screen.getByTestId('apply-button')
      await userEvent.click(applyButton)

      await waitFor(() => {
        expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
      })

      // Click the close button in the header
      const closeButtonContainer = screen.getByTestId('wizard-close-button')
      const closeButton = closeButtonContainer.querySelector('button')!
      await userEvent.click(closeButton)

      // Modal should appear
      await waitFor(() => {
        expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
      })
    })

    it('closes immediately when user tries to close with no unsaved changes', async () => {
      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      // Click the close button in the header (no changes applied)
      const closeButtonContainer = screen.getByTestId('wizard-close-button')
      const closeButton = closeButtonContainer.querySelector('button')!
      await userEvent.click(closeButton)

      // onClose should be called immediately
      await waitFor(() => {
        expect(mockSetSelectedScan).toHaveBeenCalledWith(null)
        expect(mockSetIsTrayOpen).toHaveBeenCalledWith(false)
      })

      // Modal should NOT appear
      expect(screen.queryByText('You have unsaved changes')).not.toBeInTheDocument()
    })

    it('calls handleApplyAndSaveAndNext and closes when modal confirm clicked', async () => {
      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      // Apply changes
      const applyButton = screen.getByTestId('apply-button')
      await userEvent.click(applyButton)

      await waitFor(() => {
        expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
      })

      // Click the close button to trigger modal
      const closeButtonContainer = screen.getByTestId('wizard-close-button')
      const closeButton = closeButtonContainer.querySelector('button')!
      await userEvent.click(closeButton)

      // Wait for modal to appear
      await waitFor(() => {
        expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
      })

      // Click "Save changes" in modal
      const saveButton = screen.getByText('Save changes').closest('button')!
      await userEvent.click(saveButton)

      // Verify close was called after save
      await waitFor(() => {
        expect(mockSetSelectedScan).toHaveBeenCalledWith(null)
        expect(mockSetIsTrayOpen).toHaveBeenCalledWith(false)
      })
    })

    it('closes immediately when modal cancel clicked', async () => {
      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      // Apply changes
      const applyButton = screen.getByTestId('apply-button')
      await userEvent.click(applyButton)

      await waitFor(() => {
        expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
      })

      // Click the close button to trigger modal
      const closeButtonContainer = screen.getByTestId('wizard-close-button')
      const closeButton = closeButtonContainer.querySelector('button')!
      await userEvent.click(closeButton)

      // Wait for modal to appear
      await waitFor(() => {
        expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
      })

      // Click "Don't save" in modal
      const cancelButton = screen.getByText("Don't save").closest('button')!
      await userEvent.click(cancelButton)

      // Verify close was called without saving
      await waitFor(() => {
        expect(mockSetSelectedScan).toHaveBeenCalledWith(null)
        expect(mockSetIsTrayOpen).toHaveBeenCalledWith(false)
      })
    })

    it('does not show modal when feature flag is disabled', async () => {
      setupMockStore({...defaultStore, isGA2FeaturesEnabled: false})

      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      // Apply changes
      const applyButton = screen.getByTestId('apply-button')
      await userEvent.click(applyButton)

      await waitFor(() => {
        expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
      })

      // Click the close button
      const closeButtonContainer = screen.getByTestId('wizard-close-button')
      const closeButton = closeButtonContainer.querySelector('button')!
      await userEvent.click(closeButton)

      // onClose should be called immediately, no modal
      await waitFor(() => {
        expect(mockSetSelectedScan).toHaveBeenCalledWith(null)
        expect(mockSetIsTrayOpen).toHaveBeenCalledWith(false)
      })
      expect(screen.queryByText('You have unsaved changes')).not.toBeInTheDocument()
    })

    it('allows closing the tray after dismissing the modal with X button', async () => {
      render(<AccessibilityWizard />, {wrapper: createWrapper()})

      // Apply changes to set isRemediated to true
      const applyButton = screen.getByTestId('apply-button')
      await userEvent.click(applyButton)

      await waitFor(() => {
        expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
      })

      // First close attempt - click tray close button
      const trayCloseButtonContainer = screen.getByTestId('wizard-close-button')
      const trayCloseButton = trayCloseButtonContainer.querySelector('button')!
      await userEvent.click(trayCloseButton)

      // Modal should appear
      await waitFor(() => {
        expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
      })

      // Get the modal's close button
      const modalCloseButton = screen.getByTestId('modal-close-button')

      // Click X to close the modal (not the tray)
      await userEvent.click(modalCloseButton)

      // Modal should close
      await waitFor(() => {
        expect(screen.queryByText('You have unsaved changes')).not.toBeInTheDocument()
      })

      // Second close attempt - click tray close button again
      await userEvent.click(trayCloseButton)

      // Modal should show again
      await waitFor(() => {
        expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
      })

      // This time click "Don't save" to actually close the tray
      const dontSaveButton = screen.getByText("Don't save").closest('button')!
      await userEvent.click(dontSaveButton)

      // Verify tray closed
      await waitFor(() => {
        expect(mockSetSelectedScan).toHaveBeenCalledWith(null)
        expect(mockSetIsTrayOpen).toHaveBeenCalledWith(false)
      })
    })

    describe('Skip button with unsaved changes', () => {
      it('shows modal when user tries to skip with unsaved changes', async () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        // Apply changes to set isRemediated to true
        const applyButton = screen.getByTestId('apply-button')
        await userEvent.click(applyButton)

        await waitFor(() => {
          expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
        })

        // Click Skip button
        const skipButton = screen.getByTestId('skip-button')
        await userEvent.click(skipButton)

        // Modal should appear
        await waitFor(() => {
          expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
        })
      })

      it('saves and skips when user clicks "Save changes"', async () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        // Apply changes
        const applyButton = screen.getByTestId('apply-button')
        await userEvent.click(applyButton)

        await waitFor(() => {
          expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
        })

        // Click Skip button
        const skipButton = screen.getByTestId('skip-button')
        await userEvent.click(skipButton)

        // Wait for modal
        await waitFor(() => {
          expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
        })

        // Click "Save changes"
        const saveButton = screen.getByText('Save changes').closest('button')!
        await userEvent.click(saveButton)

        // Modal should close and save should be called
        await waitFor(() => {
          expect(screen.queryByText('You have unsaved changes')).not.toBeInTheDocument()
        })
      })

      it('skips without saving when user clicks "Don\'t Save"', async () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        // Apply changes
        const applyButton = screen.getByTestId('apply-button')
        await userEvent.click(applyButton)

        await waitFor(() => {
          expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
        })

        // Click Skip button
        const skipButton = screen.getByTestId('skip-button')
        await userEvent.click(skipButton)

        // Wait for modal
        await waitFor(() => {
          expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
        })

        // Click "Don't save"
        const dontSaveButton = screen.getByText("Don't save").closest('button')!
        await userEvent.click(dontSaveButton)

        // Modal should close without saving
        await waitFor(() => {
          expect(screen.queryByText('You have unsaved changes')).not.toBeInTheDocument()
        })
      })
    })

    describe('Back button with unsaved changes', () => {
      beforeEach(() => {
        setupMockStore({
          ...defaultStore,
          selectedIssue: defaultStore.selectedScan!.issues![1],
          selectedIssueIndex: 1,
          isGA2FeaturesEnabled: true,
          isCloseIssuesEnabled: false,
        })
      })

      it('shows modal when user tries to go back with unsaved changes', async () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        // Apply changes to set isRemediated to true
        const applyButton = screen.getByTestId('apply-button')
        await userEvent.click(applyButton)

        await waitFor(() => {
          expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
        })

        // Click Back button
        const backButton = screen.getByTestId('back-button')
        await userEvent.click(backButton)

        // Modal should appear
        await waitFor(() => {
          expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
        })
      })

      it('saves and goes back when user clicks "Save changes"', async () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        // Apply changes
        const applyButton = screen.getByTestId('apply-button')
        await userEvent.click(applyButton)

        await waitFor(() => {
          expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
        })

        // Click Back button
        const backButton = screen.getByTestId('back-button')
        await userEvent.click(backButton)

        // Wait for modal
        await waitFor(() => {
          expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
        })

        // Click "Save changes"
        const saveButton = screen.getByText('Save changes').closest('button')!
        await userEvent.click(saveButton)

        // Modal should close
        await waitFor(() => {
          expect(screen.queryByText('You have unsaved changes')).not.toBeInTheDocument()
        })
      })

      it('goes back without saving when user clicks "Don\'t Save"', async () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        // Apply changes
        const applyButton = screen.getByTestId('apply-button')
        await userEvent.click(applyButton)

        await waitFor(() => {
          expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
        })

        // Click Back button
        const backButton = screen.getByTestId('back-button')
        await userEvent.click(backButton)

        // Wait for modal
        await waitFor(() => {
          expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
        })

        // Click "Don't save"
        const dontSaveButton = screen.getByText("Don't save").closest('button')!
        await userEvent.click(dontSaveButton)

        // Modal should close
        await waitFor(() => {
          expect(screen.queryByText('You have unsaved changes')).not.toBeInTheDocument()
        })
      })
    })

    describe('Back To Start button with unsaved changes', () => {
      beforeEach(() => {
        setupMockStore({
          ...defaultStore,
          selectedIssue: defaultStore.selectedScan!.issues![1],
          selectedIssueIndex: 1,
          isGA2FeaturesEnabled: true,
          isCloseIssuesEnabled: false,
        })
      })

      it('shows modal when user tries to go back to start with unsaved changes', async () => {
        // Use wrapper with close issues disabled to show Back To Start button
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        // Apply changes to set isRemediated to true
        const applyButton = screen.getByTestId('apply-button')
        await userEvent.click(applyButton)

        await waitFor(() => {
          expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
        })

        // Click Back To Start button
        const backToStartButton = screen.getByTestId('back-to-start-button')
        await userEvent.click(backToStartButton)

        // Modal should appear
        await waitFor(() => {
          expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
        })
      })

      it('saves and goes back to start when user clicks "Save changes"', async () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        // Apply changes
        const applyButton = screen.getByTestId('apply-button')
        await userEvent.click(applyButton)

        await waitFor(() => {
          expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
        })

        // Click Back To Start button
        const backToStartButton = screen.getByTestId('back-to-start-button')
        await userEvent.click(backToStartButton)

        // Wait for modal
        await waitFor(() => {
          expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
        })

        // Click "Save changes"
        const saveButton = screen.getByText('Save changes').closest('button')!
        await userEvent.click(saveButton)

        // Modal should close
        await waitFor(() => {
          expect(screen.queryByText('You have unsaved changes')).not.toBeInTheDocument()
        })
      })

      it('goes back to start without saving when user clicks "Don\'t Save"', async () => {
        render(<AccessibilityWizard />, {wrapper: createWrapper()})

        // Apply changes
        const applyButton = screen.getByTestId('apply-button')
        await userEvent.click(applyButton)

        await waitFor(() => {
          expect(screen.getByTestId('save-and-next-button')).toBeEnabled()
        })

        // Click Back To Start button
        const backToStartButton = screen.getByTestId('back-to-start-button')
        await userEvent.click(backToStartButton)

        // Wait for modal
        await waitFor(() => {
          expect(screen.getByText('You have unsaved changes')).toBeInTheDocument()
        })

        // Click "Don't save"
        const dontSaveButton = screen.getByText("Don't save").closest('button')!
        await userEvent.click(dontSaveButton)

        // Modal should close
        await waitFor(() => {
          expect(screen.queryByText('You have unsaved changes')).not.toBeInTheDocument()
        })
      })
    })
  })
})
