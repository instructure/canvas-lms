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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {
  type CheckboxTreeNode,
  type ItemType, SwitchState,
  TreeSelector,
  type TreeSelectorProps
} from '../TreeSelector'

const defaultProps: TreeSelectorProps = {
  checkboxTreeNodes: {
    'single-item-1': {
      id: 'single-item-1',
      label: 'My single item 1',
      type: 'assignments',
      childrenIds: [],
      checkboxState: 'unchecked',
    },
    'parent-item-1': {
      id: 'parent-item-1',
      label: 'My parent item 1',
      type: 'assignments',
      childrenIds: ['child-item-1', 'child-item-2', 'child-item-3'],
      checkboxState: 'unchecked',
    },
    'child-item-1': {
      id: 'child-item-1',
      label: 'My child item 1',
      type: 'assignments',
      parentId: 'parent-item-1',
      childrenIds: [],
      checkboxState: 'unchecked',
    },
    'child-item-2': {
      id: 'child-item-2',
      label: 'My child item 2',
      type: 'assignments',
      parentId: 'parent-item-1',
      childrenIds: [],
      checkboxState: 'unchecked',
    },
    'child-item-3': {
      id: 'child-item-3',
      label: 'My child item 3',
      type: 'assignments',
      parentId: 'parent-item-1',
      childrenIds: ['sub-child-item-1', 'sub-child-item-2', 'sub-child-item-3'],
      checkboxState: 'unchecked',
    },
    'sub-child-item-1': {
      id: 'sub-child-item-1',
      label: 'My sub-child item 1',
      type: 'assignments',
      parentId: 'child-item-3',
      childrenIds: [],
      checkboxState: 'unchecked',
    },
    'sub-child-item-2': {
      id: 'sub-child-item-2',
      label: 'My sub-child item 2',
      type: 'assignments',
      parentId: 'child-item-3',
      childrenIds: [],
      checkboxState: 'unchecked',
    },
    'sub-child-item-3': {
      id: 'sub-child-item-3',
      label: 'My sub-child item 3',
      type: 'assignments',
      parentId: 'child-item-3',
      childrenIds: [],
      checkboxState: 'unchecked',
      linkedId: 'child-item-4',
    },
    'single-item-2': {
      id: 'single-item-2',
      label: 'My single item 2',
      type: 'assignments',
      childrenIds: [],
      checkboxState: 'unchecked',
    },
    'parent-item-2': {
      id: 'parent-item-2',
      label: 'My parent item 2',
      type: 'assignments',
      childrenIds: ['child-item-4'],
      checkboxState: 'unchecked',
    },
    'child-item-4': {
      id: 'child-item-4',
      label: 'My child item 4',
      type: 'assignments',
      parentId: 'parent-item-2',
      childrenIds: [],
      checkboxState: 'unchecked',
      linkedId: 'sub-child-item-3',
    },
  },
  onChange: jest.fn(),
}

const singleItems: Record<string, CheckboxTreeNode> = {
  'single-item-1': {
    id: 'single-item-1',
    label: 'My single item 1',
    type: 'assignments',
    childrenIds: [],
    checkboxState: 'unchecked',
  },
}

const parentWith1ConnectedChild: Record<string, CheckboxTreeNode> = {
  'parent-item-1': {
    id: 'parent-item-1',
    label: 'My parent item 1',
    type: 'assignments',
    childrenIds: ['child-item-1'],
    checkboxState: 'unchecked',
  },
  'child-item-1': {
    id: 'child-item-1',
    label: 'My child item 1',
    type: 'assignments',
    parentId: 'parent-item-1',
    childrenIds: [],
    checkboxState: 'unchecked',
  },
}

const parentWith1ConnectedChildAnd1SubChild: Record<string, CheckboxTreeNode> = {
  'parent-item-1': {
    id: 'parent-item-1',
    label: 'My parent item 1',
    childrenIds: ['child-item-1'],
    checkboxState: 'unchecked',
    type: 'assignments',
  },
  'child-item-1': {
    id: 'child-item-1',
    label: 'My child item 1',
    parentId: 'parent-item-1',
    childrenIds: ['sub-child-item-1'],
    checkboxState: 'unchecked',
    type: 'assignments',
  },
  'sub-child-item-1': {
    id: 'sub-child-item-1',
    label: 'My sub-child item 1',
    parentId: 'child-item-1',
    childrenIds: [],
    checkboxState: 'unchecked',
    type: 'assignments',
  },
}

const parentWith1ConnectedChildAnd2SubChild: Record<string, CheckboxTreeNode> = {
  'parent-item-1': {
    id: 'parent-item-1',
    label: 'My parent item 1',
    childrenIds: ['child-item-1'],
    checkboxState: 'unchecked',
    type: 'assignments',
  },
  'child-item-1': {
    id: 'child-item-1',
    label: 'My child item 1',
    parentId: 'parent-item-1',
    childrenIds: ['sub-child-item-1', 'sub-child-item-2'],
    checkboxState: 'unchecked',
    type: 'assignments',
  },
  'sub-child-item-1': {
    id: 'sub-child-item-1',
    label: 'My sub-child item 1',
    parentId: 'child-item-1',
    childrenIds: [],
    checkboxState: 'unchecked',
    type: 'assignments',
  },
  'sub-child-item-2': {
    id: 'sub-child-item-2',
    label: 'My sub-child item 2',
    parentId: 'child-item-1',
    childrenIds: [],
    checkboxState: 'unchecked',
    type: 'assignments',
  },
}

const assertFlatItemsCheckBoxStates = (
  mock: any,
  checkedList: string[],
  indeterminateList: string[],
) => {
  const lastState = mock.mock.calls[mock.mock.calls.length - 1][0] as Record<
    string,
    CheckboxTreeNode
  >
  Object.values(lastState).forEach(item => {
    if (checkedList.includes(item.id)) {
      expect(item.checkboxState).toBe('checked')
    } else if (indeterminateList.includes(item.id)) {
      expect(item.checkboxState).toBe('indeterminate')
    } else {
      expect(item.checkboxState).toBe('unchecked')
    }
  })
}

const findCheckedBoxById = (component: any, id: string) => {
  const inputElement = component.getByTestId(id)
  const parentElement = inputElement.parentElement
  return parentElement?.querySelector('svg')
}

const findToggleButtonById = (component: any, id: string) => {
  const toggleWrapper = component.getByTestId(id)
  return toggleWrapper.querySelector('button')
}

const findIndeterminateStateCheckboxById = (component: any, id: string) => {
  return component.getByTestId(id).getAttribute('aria-checked')
}

const isElementInIndeterminateState = (component: any, id: string) => {
  expect(findIndeterminateStateCheckboxById(component, id)).toBe('mixed')
}

const renderComponent = (overrides: TreeSelectorProps) =>
  render(<TreeSelector {...defaultProps} {...(overrides || {})} />)

describe('TreeSelector', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders child root items', () => {
    const component = renderComponent(defaultProps)
    expect(component.getByTestId('checkbox-single-item-1')).toBeInTheDocument()
    expect(component.getByTestId('checkbox-single-item-2')).toBeInTheDocument()
    // Labels are used for text and screen-reader
    expect(component.getAllByText('My single item 1')[1]).toBeInTheDocument()
    expect(component.getAllByText('My single item 2')[1]).toBeInTheDocument()
  })

  it('renders parent root items', () => {
    const component = renderComponent(defaultProps)
    expect(component.getByTestId('checkbox-parent-item-1')).toBeInTheDocument()
    expect(component.getByTestId('checkbox-parent-item-2')).toBeInTheDocument()
    // Labels are used for text and screen-reader
    expect(component.getAllByText('My parent item 1')[1]).toBeInTheDocument()
    expect(component.getAllByText('My parent item 2')[1]).toBeInTheDocument()
  })

  it('renders children items on open parent', async () => {
    const component = renderComponent(defaultProps)
    await userEvent.click(findToggleButtonById(component, 'toggle-parent-item-1'))
    await userEvent.click(findToggleButtonById(component, 'toggle-parent-item-2'))
    expect(component.getByTestId('checkbox-child-item-1')).toBeInTheDocument()
    expect(component.getByTestId('checkbox-child-item-2')).toBeInTheDocument()
    expect(component.getByTestId('checkbox-child-item-3')).toBeInTheDocument()
    expect(component.getByTestId('checkbox-child-item-4')).toBeInTheDocument()
    expect(component.getAllByText('My child item 1')[1]).toBeInTheDocument()
    expect(component.getAllByText('My child item 2')[1]).toBeInTheDocument()
    expect(component.getAllByText('My child item 3')[1]).toBeInTheDocument()
    expect(component.getAllByText('My child item 4')[1]).toBeInTheDocument()
  })

  it('renders sub child items on open parent', async () => {
    const component = renderComponent(defaultProps)
    await userEvent.click(findToggleButtonById(component, 'toggle-parent-item-1'))
    await userEvent.click(findToggleButtonById(component, 'toggle-child-item-3'))
    expect(component.getByTestId('checkbox-sub-child-item-1')).toBeInTheDocument()
    expect(component.getByTestId('checkbox-sub-child-item-2')).toBeInTheDocument()
    expect(component.getByTestId('checkbox-sub-child-item-3')).toBeInTheDocument()
    expect(component.getAllByText('My sub-child item 1')[1]).toBeInTheDocument()
    expect(component.getAllByText('My sub-child item 2')[1]).toBeInTheDocument()
    expect(component.getAllByText('My sub-child item 3')[1]).toBeInTheDocument()
  })

  describe('expand screen reader', () => {
    it('find first screen reader texts of first level nodes', () => {
      const component = renderComponent(defaultProps)
      expect(component.getByText('My parent item 1, View All')).toBeInTheDocument()
      expect(component.getByText('My parent item 2, View All')).toBeInTheDocument()
    })
  })

  describe('checked, unchecked state', () => {
    it('checks/un-checks for single child item', async () => {
      const onChangeMock = jest.fn()
      const component = renderComponent({
        checkboxTreeNodes: singleItems,
        onChange: onChangeMock,
      })
      await userEvent.click(component.getByTestId('checkbox-single-item-1'))
      expect(findCheckedBoxById(component, 'checkbox-single-item-1')).toBeInTheDocument()
      assertFlatItemsCheckBoxStates(onChangeMock, ['single-item-1'], [])
      await userEvent.click(component.getByTestId('checkbox-single-item-1'))
      expect(findCheckedBoxById(component, 'checkbox-single-item-1')).not.toBeInTheDocument()
      assertFlatItemsCheckBoxStates(onChangeMock, [], [])
    })

    it('checks/un-checks for parent and connected child', async () => {
      const onChangeMock = jest.fn()
      const component = renderComponent({
        checkboxTreeNodes: parentWith1ConnectedChild,
        onChange: onChangeMock,
      })
      await userEvent.click(findToggleButtonById(component, 'toggle-parent-item-1'))

      await userEvent.click(component.getByTestId('checkbox-parent-item-1'))
      expect(findCheckedBoxById(component, 'checkbox-parent-item-1')).toBeInTheDocument()
      expect(findCheckedBoxById(component, 'checkbox-child-item-1')).toBeInTheDocument()
      assertFlatItemsCheckBoxStates(onChangeMock, ['parent-item-1', 'child-item-1'], [])

      await userEvent.click(component.getByTestId('checkbox-parent-item-1'))
      expect(findCheckedBoxById(component, 'checkbox-parent-item-1')).not.toBeInTheDocument()
      expect(findCheckedBoxById(component, 'checkbox-child-item-1')).not.toBeInTheDocument()
      assertFlatItemsCheckBoxStates(onChangeMock, [], [])
    })

    it('checks/un-checks box for child of child item', async () => {
      const onChangeMock = jest.fn()
      const component = renderComponent({
        checkboxTreeNodes: parentWith1ConnectedChildAnd1SubChild,
        onChange: onChangeMock,
      })
      await userEvent.click(findToggleButtonById(component, 'toggle-parent-item-1'))
      await userEvent.click(findToggleButtonById(component, 'toggle-child-item-1'))
      await userEvent.click(component.getByTestId('checkbox-sub-child-item-1'))
      expect(findCheckedBoxById(component, 'checkbox-parent-item-1')).toBeInTheDocument()
      expect(findCheckedBoxById(component, 'checkbox-child-item-1')).toBeInTheDocument()
      expect(findCheckedBoxById(component, 'checkbox-sub-child-item-1')).toBeInTheDocument()
      assertFlatItemsCheckBoxStates(
        onChangeMock,
        ['parent-item-1', 'child-item-1', 'sub-child-item-1'],
        [],
      )

      await userEvent.click(component.getByTestId('checkbox-sub-child-item-1'))
      expect(findCheckedBoxById(component, 'checkbox-parent-item-1')).not.toBeInTheDocument()
      expect(findCheckedBoxById(component, 'checkbox-child-item-1')).not.toBeInTheDocument()
      expect(findCheckedBoxById(component, 'checkbox-sub-child-item-1')).not.toBeInTheDocument()
      assertFlatItemsCheckBoxStates(onChangeMock, [], [])
    })
  })

  describe('indeterminate state', () => {
    it('puts all parents into indeterminate state on not every children checked', async () => {
      const onChangeMock = jest.fn()
      const component = renderComponent({
        checkboxTreeNodes: parentWith1ConnectedChildAnd2SubChild,
        onChange: onChangeMock,
      })
      await userEvent.click(findToggleButtonById(component, 'toggle-parent-item-1'))
      await userEvent.click(findToggleButtonById(component, 'toggle-child-item-1'))
      await userEvent.click(component.getByTestId('checkbox-sub-child-item-1'))
      isElementInIndeterminateState(component, 'checkbox-parent-item-1')
      isElementInIndeterminateState(component, 'checkbox-child-item-1')
      expect(findCheckedBoxById(component, 'checkbox-sub-child-item-1')).toBeInTheDocument()
      assertFlatItemsCheckBoxStates(
        onChangeMock,
        ['sub-child-item-1'],
        ['parent-item-1', 'child-item-1'],
      )
    })

    it('unchecks everything on indeterminate parents click', async () => {
      const onChangeMock = jest.fn()
      const component = renderComponent({
        checkboxTreeNodes: parentWith1ConnectedChildAnd2SubChild,
        onChange: onChangeMock,
      })
      await userEvent.click(findToggleButtonById(component, 'toggle-parent-item-1'))
      await userEvent.click(findToggleButtonById(component, 'toggle-child-item-1'))
      // Turn on everything from parent-item-1
      await userEvent.click(component.getByTestId('checkbox-parent-item-1'))
      assertFlatItemsCheckBoxStates(
        onChangeMock,
        ['parent-item-1', 'child-item-1', 'sub-child-item-1', 'sub-child-item-2'],
        [],
      )
      // Turn off 1 element in the graph
      await userEvent.click(component.getByTestId('checkbox-sub-child-item-1'))
      // Parents should be indeterminate
      isElementInIndeterminateState(component, 'checkbox-parent-item-1')
      isElementInIndeterminateState(component, 'checkbox-child-item-1')
      // sub-child-item-2 still in checked state
      expect(findCheckedBoxById(component, 'checkbox-sub-child-item-2')).toBeInTheDocument()
      assertFlatItemsCheckBoxStates(
        onChangeMock,
        ['sub-child-item-2'],
        ['child-item-1', 'parent-item-1'],
      )

      // Click indeterminate top parent
      await userEvent.click(component.getByTestId('checkbox-parent-item-1'))
      // Everything should be unchecked
      expect(findCheckedBoxById(component, 'checkbox-parent-item-1')).not.toBeInTheDocument()
      expect(findCheckedBoxById(component, 'checkbox-child-item-1')).not.toBeInTheDocument()
      expect(findCheckedBoxById(component, 'checkbox-sub-child-item-1')).not.toBeInTheDocument()
      expect(findCheckedBoxById(component, 'checkbox-sub-child-item-2')).not.toBeInTheDocument()
      assertFlatItemsCheckBoxStates(onChangeMock, [], [])
    })
  })

  describe('linked items', () => {
    it('checks/un-checks linked item', async () => {
      const component = renderComponent(defaultProps)
      // Open necessary toggles
      await userEvent.click(findToggleButtonById(component, 'toggle-parent-item-1'))
      await userEvent.click(findToggleButtonById(component, 'toggle-child-item-3'))
      await userEvent.click(findToggleButtonById(component, 'toggle-parent-item-2'))
      // Click linked checkboxes
      await userEvent.click(component.getByTestId('checkbox-sub-child-item-3'))

      // Both linked items should be checked
      expect(findCheckedBoxById(component, 'checkbox-child-item-4')).toBeInTheDocument()
      expect(findCheckedBoxById(component, 'checkbox-sub-child-item-3')).toBeInTheDocument()
      // Parents should be indeterminate
      isElementInIndeterminateState(component, 'checkbox-child-item-3')
      isElementInIndeterminateState(component, 'checkbox-parent-item-1')
      assertFlatItemsCheckBoxStates(
        defaultProps.onChange,
        ['child-item-4', 'sub-child-item-3', 'parent-item-2'],
        ['parent-item-1', 'child-item-3'],
      )

      // Click linked checkbox other side
      await userEvent.click(component.getByTestId('checkbox-sub-child-item-3'))
      // Both linked items should be unchecked
      expect(findCheckedBoxById(component, 'checkbox-child-item-4')).not.toBeInTheDocument()
      expect(findCheckedBoxById(component, 'checkbox-sub-child-item-3')).not.toBeInTheDocument()
      // Parents should be unchecked
      expect(findCheckedBoxById(component, 'checkbox-child-item-3')).not.toBeInTheDocument()
      expect(findCheckedBoxById(component, 'checkbox-parent-item-1')).not.toBeInTheDocument()

      // Everything should be unchecked state wise
      assertFlatItemsCheckBoxStates(defaultProps.onChange, [], [])
    })

    it('indeterminate action uncheck children, and with that the linked element', async () => {
      const component = renderComponent(defaultProps)
      // Open necessary toggles
      await userEvent.click(findToggleButtonById(component, 'toggle-parent-item-1'))
      await userEvent.click(findToggleButtonById(component, 'toggle-child-item-3'))
      await userEvent.click(findToggleButtonById(component, 'toggle-parent-item-2'))

      // Check everything in parent-item-1
      await userEvent.click(component.getByTestId('checkbox-parent-item-1'))
      assertFlatItemsCheckBoxStates(
        defaultProps.onChange,
        [
          'parent-item-1',
          'parent-item-2',
          'child-item-1',
          'child-item-2',
          'child-item-3',
          'child-item-4',
          'sub-child-item-1',
          'sub-child-item-2',
          'sub-child-item-3',
        ],
        [],
      )
      // Uncheck 1 element in parent-item-1 graph
      await userEvent.click(component.getByTestId('checkbox-child-item-1'))

      // Top parent element in indeterminate state
      isElementInIndeterminateState(component, 'checkbox-parent-item-1')
      // Linked element should be checked
      expect(findCheckedBoxById(component, 'checkbox-child-item-4')).toBeInTheDocument()
      assertFlatItemsCheckBoxStates(
        defaultProps.onChange,
        [
          'parent-item-2',
          'child-item-2',
          'child-item-3',
          'child-item-4',
          'sub-child-item-1',
          'sub-child-item-2',
          'sub-child-item-3',
        ],
        ['parent-item-1'],
      )

      // Click on the top parent element with indeterminate state
      await userEvent.click(component.getByTestId('checkbox-parent-item-1'))

      // Linked item also should be unchecked
      expect(findCheckedBoxById(component, 'checkbox-child-item-4')).not.toBeInTheDocument()

      // Everything should be unchecked state wise
      assertFlatItemsCheckBoxStates(defaultProps.onChange, [], [])
    })
  })

  describe('switch state handling', () => {
    const contextModulesProps: TreeSelectorProps = {
      checkboxTreeNodes: {
        'parent-item-1': {
          id: 'parent-item-1',
          label: 'Context module parent',
          type: 'context_modules',
          childrenIds: ['child-item-1'],
          checkboxState: 'unchecked',
        },
        'child-item-1': {
          id: 'child-item-1',
          label: 'Context module child',
          type: 'context_modules',
          parentId: 'parent-item-1',
          childrenIds: ['sub-child-item-1'],
          checkboxState: 'unchecked',
        },
        'sub-child-item-1': {
          id: 'sub-child-item-1',
          label: 'Context module sub-child',
          type: 'context_modules',
          parentId: 'child-item-1',
          childrenIds: ['grand-sub-child-item-1'],
          checkboxState: 'unchecked',
          importAsOneModuleItemState: 'off',
        },
        'grand-sub-child-item-1': {
          id: 'grand-sub-child-item-1',
          label: 'Context module grand-sub-child',
          type: 'context_modules',
          parentId: 'sub-child-item-1',
          childrenIds: [],
          checkboxState: 'unchecked',
          importAsOneModuleItemState: 'disabled',
        },
        'parent-item-2': {
          id: 'parent-item-2',
          label: 'Context module parent 2',
          type: 'context_modules',
          childrenIds: ['child-item-2'],
          checkboxState: 'unchecked',
        },
        'child-item-2': {
          id: 'child-item-2',
          label: 'Context module child 2',
          type: 'context_modules',
          parentId: 'parent-item-2',
          childrenIds: ['sub-child-item-2'],
          checkboxState: 'unchecked',
        },
        'sub-child-item-2': {
          id: 'sub-child-item-2',
          label: 'Context module sub-child 2',
          type: 'context_modules',
          parentId: 'child-item-2',
          childrenIds: [],
          checkboxState: 'unchecked',
          importAsOneModuleItemState: 'off',
        },
      },
      onChange: jest.fn(),
    }

    const showSwitches = async (component: any) => {
      // Open necessary toggles
      await userEvent.click(findToggleButtonById(component, 'toggle-parent-item-1'))
      await userEvent.click(findToggleButtonById(component, 'toggle-child-item-1'))
      await userEvent.click(findToggleButtonById(component, 'toggle-sub-child-item-1'))
      await userEvent.click(findToggleButtonById(component, 'toggle-parent-item-2'))
      await userEvent.click(findToggleButtonById(component, 'toggle-child-item-2'))

      // Click on the top parent element to check all
      await userEvent.click(component.getByTestId('checkbox-parent-item-1'))
      await userEvent.click(component.getByTestId('checkbox-parent-item-2'))
    }

    it('should show switches for submodules', async () => {
      const component = renderComponent(contextModulesProps)
      await showSwitches(component)
      expect(component.getByTestId('switch-sub-child-item-1')).not.toBeChecked()
      expect(component.getByTestId('switch-grand-sub-child-item-1')).not.toBeChecked()
      expect(component.getByTestId('switch-grand-sub-child-item-1')).toBeDisabled()
    })

    it('should switcher change the state and get rendered', async () => {
      const component = renderComponent(contextModulesProps)
      await showSwitches(component)
      await userEvent.click(component.getByTestId('switch-sub-child-item-1'))
      expect(component.getByTestId('switch-sub-child-item-1')).toBeChecked()
      await userEvent.click(component.getByTestId('switch-grand-sub-child-item-1'))
      expect(component.getByTestId('switch-grand-sub-child-item-1')).toBeChecked()

      // Parent element switch off should off all the children and make them disabled
      await userEvent.click(component.getByTestId('switch-sub-child-item-1'))
      expect(component.getByTestId('switch-sub-child-item-1')).not.toBeChecked()
      expect(component.getByTestId('switch-grand-sub-child-item-1')).not.toBeChecked()
      expect(component.getByTestId('switch-grand-sub-child-item-1')).toBeDisabled()
    })

    describe('calling onChange', () => {
      it('should send importAsOneModuleItemState with ui represented states', async () => {
        const component = renderComponent(contextModulesProps)
        await showSwitches(component)

        // Only turn on sub-child-item-2, others remain in the default state
        await userEvent.click(component.getByTestId('switch-sub-child-item-2'))

        const mock: any = contextModulesProps.onChange
        const lastState = mock.mock.calls[mock.mock.calls.length - 1][0] as Record<
          string,
          CheckboxTreeNode
        >

        expect(lastState['sub-child-item-1'].importAsOneModuleItemState).toBe('off')
        expect(lastState['grand-sub-child-item-1'].importAsOneModuleItemState).toBe('disabled')
        expect(lastState['sub-child-item-2'].importAsOneModuleItemState).toBe('on')
      })
    })

    describe('switch text', () => {
      const getProps = (importAsOneModuleItemState: SwitchState) => {
        return {
          checkboxTreeNodes: {
            'parent-item-1': {
              ...contextModulesProps.checkboxTreeNodes['parent-item-1'],
              childrenIds: [],
              importAsOneModuleItemState
            },
          },
          onChange: jest.fn(),
        }
      }

      it('should render disabled text for switch disabled', async () => {
        const component = renderComponent(getProps('disabled'))
        await userEvent.click(component.getByTestId('checkbox-parent-item-1'))
        expect(component.getByText('Import as a standalone module')).toBeInTheDocument()
        expect(component.getByText('Selection is disabled, as the parent is not selected as a standalone module import item.')).toBeInTheDocument()
      })

      it('should render normal text for switch on', async () => {
        const component = renderComponent(getProps('on'))
        await userEvent.click(component.getByTestId('checkbox-parent-item-1'))
        expect(component.getByText('Import as a standalone module')).toBeInTheDocument()
        expect(component.getByText('If not selected, this item will be imported as one module item.')).toBeInTheDocument()
      })

      it('should render normal text for switch off', async () => {
        const component = renderComponent(getProps('off'))
        await userEvent.click(component.getByTestId('checkbox-parent-item-1'))
        expect(component.getByText('Import as a standalone module')).toBeInTheDocument()
        expect(component.getByText('If not selected, this item will be imported as one module item.')).toBeInTheDocument()
      })
    })
  })

  describe('icon rendering', () => {
    const generateByType = (type: ItemType): TreeSelectorProps => {
      return {
        checkboxTreeNodes: {'single-item-1': {...singleItems['single-item-1'], type}},
        onChange: jest.fn(),
      }
    }

    const typeIconPair = [
      {type: 'course_settings', iconName: 'IconSettings'},
      {type: 'syllabus_body', iconName: 'IconSyllabus'},
      {type: 'course_paces', iconName: 'IconHourGlass'},
      {type: 'context_modules', iconName: 'IconModule'},
      {type: 'assignments', iconName: 'IconAssignment'},
      {type: 'quizzes', iconName: 'IconQuiz'},
      {type: 'assessment_question_banks', iconName: 'IconCollection'},
      {type: 'discussion_topics', iconName: 'IconDiscussion'},
      {type: 'wiki_pages', iconName: 'IconNote'},
      {type: 'context_external_tools', iconName: 'IconLti'},
      {type: 'tool_profiles', iconName: 'IconLti'},
      {type: 'announcements', iconName: 'IconAnnouncement'},
      {type: 'calendar_events', iconName: 'IconCalendarDays'},
      {type: 'rubrics', iconName: 'IconRubric'},
      {type: 'groups', iconName: 'IconGroup'},
      {type: 'learning_outcomes', iconName: 'IconOutcomes'},
      {type: 'learning_outcome_groups', iconName: 'IconFolder'},
      {type: 'attachments', iconName: 'IconDocument'},
      {type: 'assignment_groups', iconName: 'IconFolder'},
      {type: 'folders', iconName: 'IconFolder'},
      {type: 'blueprint_settings', iconName: 'IconSettings'},
      {type: 'unknown', iconName: 'IconFolder'},
    ]

    typeIconPair.forEach(({type, iconName}) => {
      it(`renders ${iconName} icons for item ${type}`, () => {
        const component = renderComponent(generateByType(type as ItemType))
        expect(component.container.querySelectorAll(`svg[name="${iconName}"]`)).toHaveLength(1)
      })
    })
  })
})
