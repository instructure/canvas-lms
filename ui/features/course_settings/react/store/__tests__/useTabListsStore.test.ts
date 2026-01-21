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

import fakeENV from '@canvas/test-utils/fakeENV'
import {useTabListsStore, type NavigationTab} from '../useTabListsStore'

function createTab(
  id: number | string,
  label: string,
  props: Partial<Omit<NavigationTab, 'type' | 'externalId' | 'internalId'>> = {},
): NavigationTab {
  return {
    type: 'existing',
    externalId: id,
    internalId: id.toString(),
    label,
    ...props,
  }
}

function tabToEnvTab(tab: NavigationTab) {
  const {type: _type, externalId, internalId: _internalId, ...rest} = tab
  // For existing tabs, externalId should always be defined
  return {id: externalId!, ...rest}
}

describe('useTabListsStore', () => {
  const mockTabs: NavigationTab[] = [
    createTab(1, 'Home', {hidden: false}),
    createTab(2, 'Assignments', {hidden: false}),
    createTab(3, 'Quizzes', {hidden: false}),
    createTab('context_external_tool_1', 'External Tool', {hidden: false}),
    createTab(4, 'Grades', {hidden: true}),
    createTab(5, 'People', {hidden: true}),
    createTab('context_external_tool_2', 'Another Tool', {hidden: true}),
  ]

  beforeEach(() => {
    fakeENV.setup({
      COURSE_SETTINGS_NAVIGATION_TABS: mockTabs.map(tabToEnvTab),
    })
    // Reset the store state between tests
    useTabListsStore.setState({
      enabledTabs: mockTabs.filter(tab => !tab.hidden),
      disabledTabs: mockTabs.filter(tab => tab.hidden),
    })
  })

  describe('initial state', () => {
    it('should initialize with enabled and disabled tabs from ENV', () => {
      const state = useTabListsStore.getState()

      expect(state.enabledTabs).toHaveLength(4)
      expect(state.disabledTabs).toHaveLength(3)
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([1, 2, 3, 'context_external_tool_1'])
      expect(state.disabledTabs.map(t => t.externalId)).toEqual([4, 5, 'context_external_tool_2'])
    })

    it('should handle empty COURSE_SETTINGS_NAVIGATION_TABS', () => {
      fakeENV.setup({COURSE_SETTINGS_NAVIGATION_TABS: undefined})
      useTabListsStore.setState({
        enabledTabs: [],
        disabledTabs: [],
      })
      const state = useTabListsStore.getState()

      expect(state.enabledTabs).toHaveLength(0)
      expect(state.disabledTabs).toHaveLength(0)
    })
  })

  describe('moveTab - reordering within same list', () => {
    it('should reorder tabs within enabled list', () => {
      const {moveTab} = useTabListsStore.getState()

      moveTab({
        source: {droppableId: 'enabled-tabs', index: 0},
        destination: {droppableId: 'enabled-tabs', index: 2},
      })

      let state = useTabListsStore.getState()
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([2, 3, 1, 'context_external_tool_1'])

      moveTab({
        source: {droppableId: 'enabled-tabs', index: 2},
        destination: {droppableId: 'enabled-tabs', index: 0},
      })

      state = useTabListsStore.getState()
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([1, 2, 3, 'context_external_tool_1'])
    })

    it('should reorder tabs within disabled list', () => {
      const {moveTab} = useTabListsStore.getState()

      moveTab({
        source: {droppableId: 'disabled-tabs', index: 0},
        destination: {droppableId: 'disabled-tabs', index: 1},
      })

      const state = useTabListsStore.getState()
      expect(state.disabledTabs.map(t => t.externalId)).toEqual([5, 4, 'context_external_tool_2'])
    })

    it('should not change order if source and destination are the same', () => {
      const initialEnabledTabs = [...useTabListsStore.getState().enabledTabs]
      const {moveTab} = useTabListsStore.getState()

      moveTab({
        source: {droppableId: 'enabled-tabs', index: 1},
        destination: {droppableId: 'enabled-tabs', index: 1},
      })

      const state = useTabListsStore.getState()
      expect(state.enabledTabs).toEqual(initialEnabledTabs)
    })
  })

  describe('moveTab - moving between lists', () => {
    it('should move tab from enabled to disabled', () => {
      const {moveTab} = useTabListsStore.getState()

      moveTab({
        source: {droppableId: 'enabled-tabs', index: 1},
        destination: {droppableId: 'disabled-tabs', index: 0},
      })

      const state = useTabListsStore.getState()
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([1, 3, 'context_external_tool_1'])
      expect(state.disabledTabs.map(t => t.externalId)).toEqual([
        2,
        4,
        5,
        'context_external_tool_2',
      ])
      expect(state.disabledTabs[0].hidden).toBe(true)
    })

    it('should move tab from disabled to enabled', () => {
      const {moveTab} = useTabListsStore.getState()

      moveTab({
        source: {droppableId: 'disabled-tabs', index: 0},
        destination: {droppableId: 'enabled-tabs', index: 1},
      })

      const state = useTabListsStore.getState()
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([
        1,
        4,
        2,
        3,
        'context_external_tool_1',
      ])
      expect(state.disabledTabs.map(t => t.externalId)).toEqual([5, 'context_external_tool_2'])
      expect(state.enabledTabs[1].hidden).toBe(false)
    })

    it('should handle moving to end of destination list', () => {
      const {moveTab} = useTabListsStore.getState()

      moveTab({
        source: {droppableId: 'enabled-tabs', index: 0},
        destination: {droppableId: 'disabled-tabs', index: 3},
      })

      const state = useTabListsStore.getState()
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([2, 3, 'context_external_tool_1'])
      expect(state.disabledTabs.map(t => t.externalId)).toEqual([
        4,
        5,
        'context_external_tool_2',
        1,
      ])
    })
  })

  describe('moveTab - edge cases', () => {
    it('should do nothing when destination is null or undefined', () => {
      const initialEnabledTabs = [...useTabListsStore.getState().enabledTabs]
      const initialDisabledTabs = [...useTabListsStore.getState().disabledTabs]
      const {moveTab} = useTabListsStore.getState()

      moveTab({source: {droppableId: 'enabled-tabs', index: 0}, destination: null})
      expect(useTabListsStore.getState().enabledTabs).toEqual(initialEnabledTabs)
      expect(useTabListsStore.getState().disabledTabs).toEqual(initialDisabledTabs)

      moveTab({source: {droppableId: 'enabled-tabs', index: 0}, destination: undefined})
      expect(useTabListsStore.getState().enabledTabs).toEqual(initialEnabledTabs)
      expect(useTabListsStore.getState().disabledTabs).toEqual(initialDisabledTabs)
    })

    it('should do nothing when destination is undefined', () => {
      const initialEnabledTabs = [...useTabListsStore.getState().enabledTabs]
      const initialDisabledTabs = [...useTabListsStore.getState().disabledTabs]
      const {moveTab} = useTabListsStore.getState()

      moveTab({
        source: {droppableId: 'enabled-tabs', index: 0},
        destination: undefined,
      })

      const state = useTabListsStore.getState()
      expect(state.enabledTabs).toEqual(initialEnabledTabs)
      expect(state.disabledTabs).toEqual(initialDisabledTabs)
    })

    it('should handle invalid source index gracefully', () => {
      const initialEnabledTabs = [...useTabListsStore.getState().enabledTabs]
      const initialDisabledTabs = [...useTabListsStore.getState().disabledTabs]
      const {moveTab} = useTabListsStore.getState()

      moveTab({
        source: {droppableId: 'enabled-tabs', index: 999},
        destination: {droppableId: 'disabled-tabs', index: 0},
      })

      // Should not crash and should leave state unchanged
      const state = useTabListsStore.getState()
      expect(state.enabledTabs).toEqual(initialEnabledTabs)
      expect(state.disabledTabs).toEqual(initialDisabledTabs)
    })
  })

  describe('toggleTabEnabled', () => {
    it('should move enabled tab to disabled', () => {
      const {toggleTabEnabled} = useTabListsStore.getState()

      toggleTabEnabled('2') // Toggle "Assignments"

      const state = useTabListsStore.getState()
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([1, 3, 'context_external_tool_1'])
      expect(state.disabledTabs.map(t => t.externalId)).toEqual([
        4,
        5,
        'context_external_tool_2',
        2,
      ])
      expect(state.disabledTabs[3].hidden).toBe(true)
    })

    it('should move disabled tab to enabled', () => {
      const {toggleTabEnabled} = useTabListsStore.getState()

      toggleTabEnabled('4') // Toggle "Grades"

      const state = useTabListsStore.getState()
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([
        1,
        2,
        3,
        'context_external_tool_1',
        4,
      ])
      expect(state.disabledTabs.map(t => t.externalId)).toEqual([5, 'context_external_tool_2'])
      expect(state.enabledTabs[4].hidden).toBe(false)
    })

    it('should do nothing for non-existent tab id', () => {
      const initialEnabledTabs = [...useTabListsStore.getState().enabledTabs]
      const initialDisabledTabs = [...useTabListsStore.getState().disabledTabs]
      const {toggleTabEnabled} = useTabListsStore.getState()

      toggleTabEnabled('999')

      const state = useTabListsStore.getState()
      expect(state.enabledTabs).toEqual(initialEnabledTabs)
      expect(state.disabledTabs).toEqual(initialDisabledTabs)
    })
  })

  describe('moveUsingTrayResult', () => {
    const mockTabsWithImmovable: NavigationTab[] = [
      createTab(1, 'Immovable Home', {hidden: false, immovable: true}),
      createTab(2, 'Assignments', {hidden: false}),
      createTab(3, 'Quizzes', {hidden: false}),
      createTab(4, 'Discussions', {hidden: false}),
      createTab(5, 'Grades', {hidden: false}),
      createTab(6, 'People', {hidden: false}),
      createTab(7, 'Pages', {hidden: false}),
      createTab(8, 'Files', {hidden: true}),
    ]

    beforeEach(() => {
      fakeENV.setup({
        COURSE_SETTINGS_NAVIGATION_TABS: mockTabsWithImmovable.map(tabToEnvTab),
      })
      useTabListsStore.setState({
        enabledTabs: mockTabsWithImmovable.filter(tab => !tab.hidden),
        disabledTabs: mockTabsWithImmovable.filter(tab => tab.hidden),
      })
    })

    it('should move item to top (after immovable)', () => {
      const {moveUsingTrayResult} = useTabListsStore.getState()

      // Move Grades (id: 5) to top
      moveUsingTrayResult({
        data: ['5', '2', '3', '4', '6', '7'], // 5 moved to first position among movable
        itemIds: ['5'],
      })

      const state = useTabListsStore.getState()
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([1, 5, 2, 3, 4, 6, 7])
    })

    it('should move item to bottom', () => {
      const {moveUsingTrayResult} = useTabListsStore.getState()

      // Move Assignments (id: 2) to bottom
      moveUsingTrayResult({
        data: ['3', '4', '5', '6', '7', '2'], // 2 moved to last position
        itemIds: ['2'],
      })

      const state = useTabListsStore.getState()
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([1, 3, 4, 5, 6, 7, 2])
    })

    it('should move item to before an item before the item being moved', () => {
      const {moveUsingTrayResult} = useTabListsStore.getState()

      // Move Discussions (id: 4) to before Quizzes (id: 3)
      moveUsingTrayResult({
        data: ['2', '4', '3', '5', '6', '7'], // 4 moved before 3
        itemIds: ['4'],
      })

      const state = useTabListsStore.getState()
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([1, 2, 4, 3, 5, 6, 7])
    })

    it('should move item to before an item at least 2 after the item being moved', () => {
      const {moveUsingTrayResult} = useTabListsStore.getState()

      // Move Quizzes (id: 3) to before People (id: 6) - 6 is 3 positions after 3
      moveUsingTrayResult({
        data: ['2', '4', '5', '3', '6', '7'], // 3 moved before 6
        itemIds: ['3'],
      })

      const state = useTabListsStore.getState()
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([1, 2, 4, 5, 3, 6, 7])
    })

    it('should move item to after an item at least 2 before the one being moved', () => {
      const {moveUsingTrayResult} = useTabListsStore.getState()

      // Move People (id: 6) to after Quizzes (id: 3) - 3 is 3 positions before 6
      moveUsingTrayResult({
        data: ['2', '3', '6', '4', '5', '7'], // 6 moved after 3
        itemIds: ['6'],
      })

      const state = useTabListsStore.getState()
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([1, 2, 3, 6, 4, 5, 7])
    })

    it('should move item to after an item after the one being moved', () => {
      const {moveUsingTrayResult} = useTabListsStore.getState()

      // Move Discussions (id: 4) to after People (id: 6)
      moveUsingTrayResult({
        data: ['2', '3', '5', '6', '4', '7'], // 4 moved after 6
        itemIds: ['4'],
      })

      const state = useTabListsStore.getState()
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([1, 2, 3, 5, 6, 4, 7])
    })

    it('should work with disabled tabs', () => {
      // Add more disabled tabs for testing
      const mockTabsDisabled = [
        ...mockTabsWithImmovable.slice(0, 3), // Keep first 3 enabled (including immovable)
        ...mockTabsWithImmovable
          .slice(3)
          .map(tab => createTab(tab.externalId!, tab.label, {...tab, hidden: true})), // Rest disabled
      ]

      fakeENV.setup({
        COURSE_SETTINGS_NAVIGATION_TABS: mockTabsDisabled.map(tabToEnvTab),
      })
      useTabListsStore.setState({
        enabledTabs: mockTabsDisabled.filter(tab => !tab.hidden),
        disabledTabs: mockTabsDisabled.filter(tab => tab.hidden),
      })

      const {moveUsingTrayResult} = useTabListsStore.getState()

      // Move Pages (id: 7) to top of disabled tabs
      moveUsingTrayResult({
        data: ['7', '4', '5', '6', '8'], // 7 moved to first position among disabled
        itemIds: ['7'],
      })

      const state = useTabListsStore.getState()
      expect(state.disabledTabs.map(t => t.externalId)).toEqual([7, 4, 5, 6, 8])
    })

    it('should handle non-existent item gracefully', () => {
      const initialEnabledTabs = [...useTabListsStore.getState().enabledTabs]
      const {moveUsingTrayResult} = useTabListsStore.getState()

      moveUsingTrayResult({
        data: ['2', '3', '4', '5', '6', '7'],
        itemIds: ['999'], // Non-existent item
      })

      const state = useTabListsStore.getState()
      expect(state.enabledTabs).toEqual(initialEnabledTabs)
    })

    it('should handle empty itemIds array gracefully', () => {
      const initialEnabledTabs = [...useTabListsStore.getState().enabledTabs]
      const {moveUsingTrayResult} = useTabListsStore.getState()

      moveUsingTrayResult({
        data: ['2', '3', '4', '5', '6', '7'],
        itemIds: [],
      })

      const state = useTabListsStore.getState()
      expect(state.enabledTabs).toEqual(initialEnabledTabs)
    })

    it('should handle missing itemIds property gracefully', () => {
      const initialEnabledTabs = [...useTabListsStore.getState().enabledTabs]
      const {moveUsingTrayResult} = useTabListsStore.getState()

      moveUsingTrayResult({
        data: ['2', '3', '4', '5', '6', '7'],
        // Missing itemIds property
      })

      const state = useTabListsStore.getState()
      expect(state.enabledTabs).toEqual(initialEnabledTabs)
    })

    it('should add movable tabs to end when enabled list has only immovable tabs and destination index is 0', () => {
      useTabListsStore.setState({
        enabledTabs: [createTab(1, 'Immovable', {hidden: false, immovable: true})],
        disabledTabs: [
          createTab(3, 'Assignments', {hidden: true}), // tab to move
          createTab(4, 'Quizzes', {hidden: true}),
        ],
      })

      const {moveTab} = useTabListsStore.getState()
      moveTab({
        source: {droppableId: 'disabled-tabs', index: 0},
        destination: {droppableId: 'enabled-tabs', index: 0},
      })

      const state = useTabListsStore.getState()
      // Should be added after immovable tabs (at the end)
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([1, 3])
      expect(state.disabledTabs.map(t => t.externalId)).toEqual([4])
    })
  })

  describe('complex scenarios', () => {
    it('should handle multiple operations in sequence', () => {
      let state = useTabListsStore.getState()

      // Move Home to disabled
      state.toggleTabEnabled('1')
      state = useTabListsStore.getState()
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([2, 3, 'context_external_tool_1'])
      expect(state.disabledTabs.map(t => t.externalId)).toEqual([
        4,
        5,
        'context_external_tool_2',
        1,
      ])

      // Reorder enabled tabs
      state.moveTab({
        source: {droppableId: 'enabled-tabs', index: 0},
        destination: {droppableId: 'enabled-tabs', index: 1},
      })
      state = useTabListsStore.getState()
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([3, 2, 'context_external_tool_1'])

      // Move Grades back to enabled
      state.toggleTabEnabled('4')
      state = useTabListsStore.getState()
      expect(state.enabledTabs.map(t => t.externalId)).toEqual([3, 2, 'context_external_tool_1', 4])
      expect(state.disabledTabs.map(t => t.externalId)).toEqual([5, 'context_external_tool_2', 1])
    })

    it('should preserve tab properties when moving between lists', () => {
      const tabWithProps = createTab(1, 'Home', {
        hidden: false,
        css_class: 'home-icon',
        external: false,
        href: '/courses/1/home',
      })
      fakeENV.setup({
        COURSE_SETTINGS_NAVIGATION_TABS: [tabWithProps].map(tabToEnvTab),
      })
      useTabListsStore.setState({
        enabledTabs: [tabWithProps],
        disabledTabs: [],
      })
      const {toggleTabEnabled} = useTabListsStore.getState()

      toggleTabEnabled('1')

      const state = useTabListsStore.getState()
      const movedTab = state.disabledTabs[0]
      expect(movedTab.label).toBe('Home')
      expect(movedTab.css_class).toBe('home-icon')
      expect(movedTab.external).toBe(false)
      expect(movedTab.href).toBe('/courses/1/home')
      expect(movedTab.hidden).toBe(true)
    })
  })

  describe('tabsToSave', () => {
    it('should return existing tabs with numeric and string IDs', () => {
      const {tabsToSave} = useTabListsStore.getState()
      const result = tabsToSave()

      expect(result).toEqual([
        {id: 1},
        {id: 2},
        {id: 3},
        {id: 'context_external_tool_1'},
        {id: 4, hidden: true},
        {id: 5, hidden: true},
        {id: 'context_external_tool_2', hidden: true},
      ])
    })

    it('should handle mix of existing and new link tabs', () => {
      const {appendNewLinkItemTab, tabsToSave, toggleTabEnabled} = useTabListsStore.getState()
      appendNewLinkItemTab({text: 'Link 1', url: 'https://one.com'})
      appendNewLinkItemTab({text: 'Link 2', url: 'https://two.com'})
      // disable Link 2:
      toggleTabEnabled(useTabListsStore.getState().enabledTabs.slice(-1)[0].internalId)

      const result = tabsToSave()

      expect(result[0]).toEqual({id: 1})
      const newTabs = result.slice(1).filter(t => t.id === undefined)
      expect(newTabs).toHaveLength(2)
      expect(newTabs[0]).toMatchObject({
        id: undefined,
        label: 'Link 1',
        linkUrl: 'https://one.com',
      })
      expect(newTabs[1]).toMatchObject({
        id: undefined,
        label: 'Link 2',
        linkUrl: 'https://two.com',
        hidden: true,
      })
    })
  })

  describe('appendNewLinkItemTab', () => {
    it('should create proper newLink structure', () => {
      const {appendNewLinkItemTab} = useTabListsStore.getState()

      appendNewLinkItemTab({text: 'Test Link', url: 'https://test.com'})

      const state = useTabListsStore.getState()
      const newTab = state.enabledTabs[state.enabledTabs.length - 1]
      expect(newTab.type).toBe('newLink')
      expect(newTab.externalId).toBeUndefined()
      expect(newTab.internalId).toBeTruthy()
      expect(newTab.label).toBe('Test Link')
      expect(newTab.linkUrl).toBe('https://test.com')
    })
  })
})
