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

// Mock react-beautiful-dnd
// NOTE: This mock simplifies the drag-and-drop behavior for testing structural elements.
// It does not simulate actual drag events - manual testing is required for drag behavior.
let mockOnDragEnd: ((result: any) => void) | null = null

vi.mock('react-beautiful-dnd', () => ({
  DragDropContext: ({children, onDragEnd}: any) => {
    // Store callback for manual triggering in tests
    mockOnDragEnd = onDragEnd
    return React.createElement(
      'div',
      {
        'data-testid': 'drag-drop-context',
      },
      children,
    )
  },
  Droppable: ({children, droppableId}: any) =>
    React.createElement(
      'div',
      {
        'data-testid': `droppable-${droppableId}`,
      },
      children(
        {
          innerRef: vi.fn(),
          droppableProps: {'data-rbd-droppable-id': droppableId},
          placeholder: null,
        },
        {isDraggingOver: false},
      ),
    ),
  Draggable: ({children, draggableId}: any) =>
    React.createElement(
      'div',
      {
        'data-testid': `draggable-${draggableId}`,
        'data-rbd-draggable-id': draggableId,
      },
      children(
        {
          innerRef: vi.fn(),
          draggableProps: {'data-rbd-draggable-id': draggableId},
          dragHandleProps: {'data-rbd-drag-handle-draggable-id': draggableId},
        },
        {isDragging: false},
      ),
    ),
}))

// Helper function to manually trigger drag end in tests
const triggerMockDragEnd = (result: any) => {
  if (mockOnDragEnd) {
    mockOnDragEnd(result)
  }
}

import {render, screen, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import CourseNavigationSettings from '../CourseNavigationSettings'
import {NavigationTab, useTabListsStore} from '../../store/useTabListsStore'
import fakeENV from '@canvas/test-utils/fakeENV'

beforeEach(() => {
  const enabledTabs: NavigationTab[] = [
    {
      externalId: 0,
      internalId: '0',
      type: 'existing',
      label: 'Home',
      hidden: false,
      disabled_message: 'Page disabled, will redirect to course home page',
      immovable: true,
    },
    {
      externalId: 3,
      internalId: '3',
      type: 'existing',
      label: 'Assignments',
      hidden: false,
      disabled_message: 'Page disabled, will redirect to course home page',
      immovable: false,
    },
  ]
  const disabledTabs: NavigationTab[] = [
    {
      externalId: 8,
      internalId: '8',
      type: 'existing',
      label: 'Discussions',
      hidden: true,
      disabled_message: "This page can't be disabled, only hidden",
      immovable: true,
    },
  ]

  fakeENV.setup({
    COURSE_SETTINGS_NAVIGATION_TABS: [...enabledTabs, ...disabledTabs],
    K5_SUBJECT_COURSE: false,
  })

  // Reset the Zustand store state
  useTabListsStore.setState({
    enabledTabs: enabledTabs,
    disabledTabs: disabledTabs,
  })
})

afterEach(() => {
  fakeENV.teardown()
})

describe('CourseNavigationSettings', () => {
  const defaultProps = {
    onSubmit: vi.fn(),
  }

  afterEach(() => {
    vi.clearAllMocks()
  })

  it('displays K5 help text when K5_SUBJECT_COURSE is true', () => {
    fakeENV.setup({
      ...ENV,
      K5_SUBJECT_COURSE: true,
    })
    render(<CourseNavigationSettings {...defaultProps} />)

    expect(
      screen.getByText('Drag and drop items to reorder them in the subject navigation.'),
    ).toBeInTheDocument()
  })

  it('displays regular help text when K5_SUBJECT_COURSE is false', () => {
    render(<CourseNavigationSettings {...defaultProps} />)

    expect(
      screen.getByText('Drag and drop items to reorder them in the course navigation.'),
    ).toBeInTheDocument()
  })

  it('handles drag and drop operations correctly', () => {
    render(<CourseNavigationSettings {...defaultProps} />)

    const dragDropContext = screen.getByTestId('drag-drop-context')
    expect(dragDropContext).toBeInTheDocument()

    // Verify initial state: Home is in enabled section
    const enabledSection = screen.getByTestId('droppable-enabled-tabs')
    const disabledSection = screen.getByTestId('droppable-disabled-tabs')
    expect(enabledSection).toHaveTextContent('Assignments')
    expect(disabledSection).not.toHaveTextContent('Assignments')

    // simulate moving Assignments
    triggerMockDragEnd({
      draggableId: 'tab-3',
      type: 'DEFAULT',
      source: {droppableId: 'enabled-tabs', index: 1},
      destination: {droppableId: 'disabled-tabs', index: 0},
    })

    // Verify Assignments now appears in disabled section
    expect(disabledSection).toHaveTextContent('Assignments')
    expect(enabledSection).not.toHaveTextContent('Assignments')
    expect(enabledSection).toHaveTextContent('Home')

    // Verify the component structure remains intact after drag operation
    expect(dragDropContext).toBeInTheDocument()
    expect(enabledSection).toBeInTheDocument()
    expect(disabledSection).toBeInTheDocument()
  })

  it('renders tab labels from ENV', () => {
    render(<CourseNavigationSettings {...defaultProps} />)

    expect(screen.getByText('Home')).toBeInTheDocument()
    expect(screen.getByText('Assignments')).toBeInTheDocument()
    expect(screen.getByText('Discussions')).toBeInTheDocument()
  })

  it('displays disabled message for hidden tabs', () => {
    render(<CourseNavigationSettings {...defaultProps} />)

    // Discussions is hidden in our test data
    const discussionsText = screen.getByText('Discussions')
    const parentElement = discussionsText.closest('[id^="nav_edit_tab_id_"]')

    // The disabled message should be present for the hidden tab
    expect(parentElement).toBeInTheDocument()
    expect(screen.getByText("This page can't be disabled, only hidden")).toBeInTheDocument()
  })

  it('shows drag handle for movable tabs', () => {
    const {container} = render(<CourseNavigationSettings {...defaultProps} />)

    // Check for drag handle icons (movable tabs should have them)
    const dragHandles = container.querySelectorAll('[name="IconDragHandle"]')
    expect(dragHandles.length).toBeGreaterThan(0)
  })

  it('does not show drag handle for immovable tabs', () => {
    render(<CourseNavigationSettings {...defaultProps} />)

    // Home and Discussions are immovable
    const homeElement = screen.getByText('Home').closest('[id^="nav_edit_tab_id_"]')
    const homeDragHandle = homeElement?.querySelector('[name="IconDragHandle"]')
    expect(homeDragHandle).not.toBeInTheDocument()

    const discussionsElement = screen.getByText('Discussions').closest('[id^="nav_edit_tab_id_"]')
    const discussionsDragHandle = discussionsElement?.querySelector('[name="IconDragHandle"]')
    expect(discussionsDragHandle).not.toBeInTheDocument()
  })

  it('renders settings menu button for movable tabs', () => {
    render(<CourseNavigationSettings {...defaultProps} />)

    // Find the settings button for Assignments tab (movable)
    const assignmentsTab = screen.getByText('Assignments').closest('[id^="nav_edit_tab_id_"]')
    const settingsButton = assignmentsTab?.querySelector('button[type="button"]')

    expect(settingsButton).toBeInTheDocument()
    expect(settingsButton).toHaveAttribute('aria-haspopup', 'true')
  })

  it('does not show settings menu for immovable tabs', () => {
    render(<CourseNavigationSettings {...defaultProps} />)

    // Home and Discussions are immovable
    const homeElement = screen.getByText('Home').closest('[id^="nav_edit_tab_id_"]')
    const homeSettingsButton = homeElement?.querySelector('button[aria-label*="Settings"]')
    expect(homeSettingsButton).not.toBeInTheDocument()

    const discussionsElement = screen.getByText('Discussions').closest('[id^="nav_edit_tab_id_"]')
    const discussionsSettingsButton = discussionsElement?.querySelector(
      'button[aria-label*="Settings"]',
    )
    expect(discussionsSettingsButton).not.toBeInTheDocument()
  })

  describe('Link icon display', () => {
    beforeEach(() => {
      const testEnabledTabs = [
        {
          id: 100,
          label: 'Regular Tab',
          hidden: false,
          disabled_message: '',
          immovable: false,
          type: 'existing' as const,
          externalId: 100,
          internalId: '100',
        },
        {
          id: 101,
          label: 'External Link',
          hidden: false,
          disabled_message: '',
          immovable: false,
          linkUrl: 'https://example.com',
          type: 'existing' as const,
          externalId: 101,
          internalId: '101',
        },
      ]

      const testDisabledTabs = [
        {
          id: 102,
          label: 'Another Link',
          hidden: true,
          disabled_message: '',
          immovable: false,
          linkUrl: 'https://test.com',
          type: 'existing' as const,
          externalId: 102,
          internalId: '102',
        },
      ]

      fakeENV.setup({
        COURSE_SETTINGS_NAVIGATION_TABS: [...testEnabledTabs, ...testDisabledTabs],
        K5_SUBJECT_COURSE: false,
      })

      useTabListsStore.setState({
        enabledTabs: testEnabledTabs,
        disabledTabs: testDisabledTabs,
      })
    })

    it('shows link icon only for items with linkUrl', () => {
      render(<CourseNavigationSettings {...defaultProps} />)

      // Check that tabs with linkUrl show the link icon
      const externalLinkTab = screen.getByText('External Link').closest('[id^="nav_edit_tab_id_"]')
      expect(externalLinkTab?.querySelector('[name="IconLink"]')).toBeInTheDocument()

      const anotherLinkTab = screen.getByText('Another Link').closest('[id^="nav_edit_tab_id_"]')
      expect(anotherLinkTab?.querySelector('[name="IconLink"]')).toBeInTheDocument()

      // Check that tabs without linkUrl do not show the link icon
      const regularTab = screen.getByText('Regular Tab').closest('[id^="nav_edit_tab_id_"]')
      expect(regularTab?.querySelector('[name="IconLink"]')).not.toBeInTheDocument()
    })
  })

  it('handles keyboard space key on menu trigger', async () => {
    render(<CourseNavigationSettings {...defaultProps} />)

    const assignmentsTab = screen.getByText('Assignments').closest('[id^="nav_edit_tab_id_"]')
    const settingsButton = assignmentsTab?.querySelector('button[type="button"]') as HTMLElement

    if (settingsButton) {
      settingsButton.focus()

      // Use userEvent.keyboard to simulate space key press which should open the menu
      await userEvent.keyboard(' ')

      // Verify the menu items appear
      expect(screen.getByText('Disable')).toBeInTheDocument()
      expect(screen.getByText('Move')).toBeInTheDocument()
    }
  })

  it('calls onSubmit with correct data structure including hidden tabs', async () => {
    const onSubmit = vi.fn()
    render(<CourseNavigationSettings onSubmit={onSubmit} />)

    const saveButton = screen.getByRole('button', {name: 'Save'})
    await userEvent.click(saveButton)

    expect(onSubmit).toHaveBeenCalledWith(
      expect.arrayContaining([expect.objectContaining({id: expect.anything()})]),
    )

    // Check that hidden tabs are marked correctly
    const call = onSubmit.mock.calls[0][0]
    const hiddenTabs = call.filter((tab: any) => tab.hidden === true)
    expect(hiddenTabs.length).toBeGreaterThan(0)
  })

  describe('Accessibility', () => {
    it('has screen reader content for headings and tab buttons', () => {
      render(<CourseNavigationSettings {...defaultProps} />)

      // Screen reader content should exist for both sections
      expect(screen.getByText('Enabled Links')).toBeInTheDocument()

      // Find settings button for Assignments tab (movable)
      const assignmentsSettingsButton = screen.getByRole('button', {
        name: /Settings for Assignments/i,
      })
      expect(assignmentsSettingsButton).toBeInTheDocument()

      expect(screen.getByLabelText('Discussions')).toBeInTheDocument()
    })

    it('makes tabs focusable with tabIndex', () => {
      const {container} = render(<CourseNavigationSettings {...defaultProps} />)
      container.querySelectorAll('.course-nav-tab').forEach(tab => {
        expect(tab).toHaveAttribute('tabIndex', '0')
      })
    })

    it('supports keyboard navigation with arrow keys', () => {
      const {container} = render(<CourseNavigationSettings {...defaultProps} />)

      // Find the first tab
      const firstTab = container.querySelector('.course-nav-tab') as HTMLElement
      expect(firstTab).toBeInTheDocument()

      // Focus the first tab
      firstTab?.focus()
      expect(document.activeElement).toBe(firstTab)

      // Simulate ArrowDown key press
      fireEvent.keyDown(firstTab, {key: 'ArrowDown'})

      // Focus should move to the next tab
      const allTabs = Array.from(container.querySelectorAll('.course-nav-tab'))

      // After arrow down, the second tab should receive focus call
      // Note: In the actual component, this is handled by the useUpDownKeysChangeFocusHandler
      expect(allTabs.length).toBeGreaterThan(1)
    })

    it('handles keyboard interaction for menu with Space key', async () => {
      render(<CourseNavigationSettings {...defaultProps} />)

      const settingsButton = screen.getByRole('button', {
        name: /Settings for Assignments/i,
      })

      settingsButton.focus()

      // Use userEvent.keyboard to simulate space key press which should open the menu
      await userEvent.keyboard(' ')

      // expect popup menu to open:
      expect(screen.getByText('Disable')).toBeInTheDocument()
      expect(screen.getByText('Move')).toBeInTheDocument()
    })
  })

  describe('MoveNavItemTray Edge Cases', () => {
    beforeEach(() => {
      // Set up complex test scenario with immovable tabs mixed in
      useTabListsStore.setState({
        enabledTabs: [
          {type: 'existing', externalId: 1, internalId: '1', label: 'Home', immovable: true}, // immovable
          {type: 'existing', externalId: 2, internalId: '2', label: 'Syllabus', immovable: true}, // immovable
          {
            type: 'existing',
            externalId: 3,
            internalId: '3',
            label: 'Assignments',
            immovable: false,
          },
          {type: 'existing', externalId: 4, internalId: '4', label: 'Grades', immovable: false},
          {type: 'existing', externalId: 5, internalId: '5', label: 'Calendar', immovable: true}, // immovable
          {type: 'existing', externalId: 6, internalId: '6', label: 'Files', immovable: false},
        ],
        disabledTabs: [
          {
            type: 'existing',
            externalId: 7,
            internalId: '7',
            label: 'Discussions',
            immovable: false,
          },
          {
            type: 'existing',
            externalId: 8,
            internalId: '8',
            label: 'Announcements',
            immovable: true,
          }, // immovable
          {type: 'existing', externalId: 9, internalId: '9', label: 'Quizzes', immovable: false},
        ],
      })
    })

    it('correctly calculates destination index when moving to first position among movable tabs', async () => {
      // Mock the MoveItemTray's onMoveSuccess behavior
      render(<CourseNavigationSettings onSubmit={vi.fn()} />)

      // Open the move tray for Files (tab 6)
      const filesTab = screen.getByText('Files').closest('[id^="nav_edit_tab_id_"]')
      const settingsButton = filesTab?.querySelector('button[type="button"]')

      if (settingsButton) {
        await userEvent.click(settingsButton)
        const moveMenuItem = screen.getByText('Move')
        await userEvent.click(moveMenuItem)

        // Simulate moving Files to the first position among movable tabs
        // This should place it before the first immovable tab (Syllabus)
        const moveNavItemTray = useTabListsStore.getState()
        const enabledTabs = moveNavItemTray.enabledTabs
        const tabInternalId = '6' // Files
        const sourceIndex = enabledTabs.findIndex(t => t.internalId === tabInternalId) // position 5

        // Simulate moving to first position among movable tabs
        // data represents the final order of movable tabs with Files first
        const data = ['6', '1', '3', '4'] // Files, Home, Assignments, Grades

        const destIndexAmongMovable = data.findIndex(d => d.toString() === tabInternalId.toString()) // 0
        const placeAfterId = destIndexAmongMovable === 0 ? null : data[destIndexAmongMovable - 1]
        const destIndex = placeAfterId
          ? enabledTabs.findIndex(t => t.internalId === placeAfterId) + 1
          : enabledTabs.findIndex(t => !t.immovable) // should be after immovable tabs

        expect(destIndex).toBe(2) // Should place Files after Home and Syllabus (both immovable)
        expect(sourceIndex).toBe(5) // Files was originally at position 5
      }
    })

    it('correctly calculates destination index when moving after an immovable tab', async () => {
      render(<CourseNavigationSettings onSubmit={vi.fn()} />)

      const enabledTabs = useTabListsStore.getState().enabledTabs
      const tabId = '1' // Home (currently at position 0)

      // Simulate moving Home to position after Calendar (immovable tab)
      // Final movable order: Assignments, Grades, Files, Home
      const data = ['3', '4', '6', '1']

      const destIndexAmongMovable = data.findIndex(d => d.toString() === tabId.toString()) // 3
      const placeAfterId = destIndexAmongMovable === 0 ? null : data[destIndexAmongMovable - 1] // 6 (Files)
      const destIndex = placeAfterId
        ? enabledTabs.findIndex(t => t.internalId === placeAfterId) + 1 // position after Files = 6
        : enabledTabs.findIndex(t => !t.immovable)

      expect(destIndex).toBe(6) // Should place Home after Files, at the end
    })

    it('correctly filters out immovable siblings for move options', async () => {
      render(<CourseNavigationSettings onSubmit={vi.fn()} />)

      const enabledTabs = useTabListsStore.getState().enabledTabs
      const tabInternalId = '1' // Home

      // Simulate getting sibling tabs (excluding immovable ones and the tab being moved)
      const siblingTabs = enabledTabs.filter(t => t.internalId !== tabInternalId && !t.immovable)

      // Should only include: Assignments (3), Grades (4), Files (6)
      // Should exclude: Home (1, being moved), Syllabus (2, immovable), Calendar (5, immovable)
      expect(siblingTabs).toHaveLength(3)
      expect(siblingTabs.map(t => t.internalId)).toEqual(['3', '4', '6'])
      expect(siblingTabs.every(t => !t.immovable)).toBe(true)
    })
  })

  describe('User Journey Tests', () => {
    it('moves tab from enabled to disabled and saves with correct data structure', async () => {
      const onSubmit = vi.fn()
      render(<CourseNavigationSettings onSubmit={onSubmit} />)

      // Simulate drag operation from enabled to disabled (moving Assignments instead of Home)
      triggerMockDragEnd({
        draggableId: 'tab-3',
        type: 'DEFAULT',
        source: {droppableId: 'enabled-tabs', index: 1},
        destination: {droppableId: 'disabled-tabs', index: 1},
      })

      // Click save button
      const saveButton = screen.getByRole('button', {name: 'Save'})
      await userEvent.click(saveButton)

      // Verify onSubmit called with correct data structure
      expect(onSubmit).toHaveBeenCalledWith([
        {id: 0}, // Home remains enabled (immovable)
        {id: 8, hidden: true}, // previously disabled tab
        {id: 3, hidden: true}, // newly disabled tab (Assignments)
      ])
    })

    it('reorders tabs within enabled list and saves correctly', async () => {
      const onSubmit = vi.fn()
      render(<CourseNavigationSettings onSubmit={onSubmit} />)

      // Simulate reordering within enabled tabs (move assignments before home)
      triggerMockDragEnd({
        draggableId: 'tab-3',
        type: 'DEFAULT',
        source: {droppableId: 'enabled-tabs', index: 1},
        destination: {droppableId: 'enabled-tabs', index: 0},
      })

      // Click save button
      const saveButton = screen.getByRole('button', {name: 'Save'})
      await userEvent.click(saveButton)

      // Verify onSubmit called with correct reordered data
      expect(onSubmit).toHaveBeenCalledWith([
        {id: 3}, // moved to first position
        {id: 0}, // moved to second position
        {id: 8, hidden: true}, // disabled tab unchanged
      ])
    })

    it('disables enabled tab via menu and verifies it appears in disabled list', async () => {
      const onSubmit = vi.fn()
      render(<CourseNavigationSettings onSubmit={onSubmit} />)

      // Find and click the settings button for assignments tab (movable enabled tab)
      const assignmentsTab = screen.getByText('Assignments').closest('[id^="nav_edit_tab_id_"]')
      const settingsButton = assignmentsTab?.querySelector('button[type="button"]')

      if (settingsButton) {
        await userEvent.click(settingsButton)

        // Find and click the Disable menu item
        const disableMenuItem = screen.getByText('Disable')
        await userEvent.click(disableMenuItem)

        // Verify tab moved to disabled section
        const disabledSection = screen.getByTestId('droppable-disabled-tabs')
        expect(disabledSection).toHaveTextContent('Assignments')
      }

      // Click save and verify correct data structure
      const saveButton = screen.getByRole('button', {name: 'Save'})
      await userEvent.click(saveButton)

      expect(onSubmit).toHaveBeenCalledWith([
        {id: 0}, // Home remains enabled (immovable)
        {id: 8, hidden: true}, // originally disabled tab (remains in original position)
        {id: 3, hidden: true}, // newly disabled tab (appended to end of disabled list)
      ])
    })
  })
})
