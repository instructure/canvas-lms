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

import {
  mapToCheckboxTreeNodes,
  generateSelectiveDataResponse,
  humanReadableSize,
  responseToItem,
} from '../utils'
import type {GenericItemResponse} from '../types'
import type {Item} from '../content_selection_modal'
import type {CheckboxTreeNode} from '@canvas/content-migrations'

describe('humanReadableSize', () => {
  it('returns Bytes', () => {
    expect(humanReadableSize(10)).toBe('10.0 Bytes')
  })

  it('returns KB', () => {
    expect(humanReadableSize(2.5 * 1024)).toBe('2.5 KB')
  })

  it('returns MB', () => {
    expect(humanReadableSize(2.5 * 1024 ** 2)).toBe('2.5 MB')
  })

  it('returns GB', () => {
    expect(humanReadableSize(3.6 * 1024 ** 3)).toBe('3.6 GB')
  })

  it('returns TB', () => {
    expect(humanReadableSize(5.5 * 1024 ** 4)).toBe('5.5 TB')
  })

  it('returns PB', () => {
    expect(humanReadableSize(7.1 * 1024 ** 5)).toBe('7.1 PB')
  })

  it('returns EB', () => {
    expect(humanReadableSize(6.2 * 1024 ** 6)).toBe('6.2 EB')
  })

  it('returns ZB', () => {
    expect(humanReadableSize(4.9 * 1024 ** 7)).toBe('4.9 ZB')
  })

  it('returns YB', () => {
    expect(humanReadableSize(1.1 * 1024 ** 8)).toBe('1.1 YB')
  })
})

describe('responseToItem', () => {
  const mockI18n = {
    t: jest.fn((key, params) => {
      if (params) {
        return key.replace(/%\{(\w+)\}/g, (_: any, k: any) => params[k])
      }
      return key
    }),
  }

  it('converts a GenericItemResponse to an Item with sub_items and linked_resource', () => {
    const subItems: GenericItemResponse[] = [
      {
        type: 'quizzes',
        title: 'Question 1',
        property: 'id_2',
        migration_id: 'mig_2',
      },
    ]
    const response: GenericItemResponse = {
      type: 'groups',
      title: 'Groups',
      property: 'id_1',
      sub_items: subItems,
      migration_id: 'mig_1',
      linked_resource: {
        migration_id: 'mig_linked_1',
        type: 'groups',
      },
    }

    const expectedItem = {
      id: 'id_1',
      label: 'Groups (1)',
      type: 'groups',
      children: [
        {
          id: 'id_2',
          label: 'Question 1',
          type: 'quizzes',
          checkboxState: 'unchecked',
          migrationId: 'mig_2',
        },
      ],
      linkedId: 'copy[groups][id_mig_linked_1]',
      checkboxState: 'unchecked',
      migrationId: 'mig_1',
    }

    expect(responseToItem(response, mockI18n)).toStrictEqual(expectedItem)
  })

  it('converts a GenericItemResponse to an Item with empty sub_items', () => {
    const response: GenericItemResponse = {
      type: 'assignments',
      title: 'Assignment 1',
      property: 'id_1',
      migration_id: 'mig_1',
      linked_resource: {
        migration_id: 'mig_linked_1',
        type: 'groups',
      },
      sub_items: [],
    }

    const expectedItem = {
      id: 'id_1',
      label: 'Assignment 1',
      type: 'assignments',
      checkboxState: 'unchecked',
      migrationId: 'mig_1',
      linkedId: 'copy[groups][id_mig_linked_1]',
    }

    expect(responseToItem(response, mockI18n)).toStrictEqual(expectedItem)
  })

  it('converts a GenericItemResponse to an Item without sub_items', () => {
    const response: GenericItemResponse = {
      type: 'assignments',
      title: 'Assignment 1',
      property: 'id_1',
      linked_resource: {
        migration_id: 'mig_linked_1',
        type: 'groups',
      },
      migration_id: 'mig_1',
    }

    const expectedItem = {
      id: 'id_1',
      label: 'Assignment 1',
      type: 'assignments',
      checkboxState: 'unchecked',
      migrationId: 'mig_1',
      linkedId: 'copy[groups][id_mig_linked_1]',
    }

    expect(responseToItem(response, mockI18n)).toStrictEqual(expectedItem)
  })

  it('converts a GenericItemResponse to an Item with empty linked_resource', () => {
    const response: GenericItemResponse = {
      type: 'assignments',
      title: 'Assignment 1',
      property: 'id_1',
      migration_id: 'mig_1',
    }

    const expectedItem = {
      id: 'id_1',
      label: 'Assignment 1',
      type: 'assignments',
      checkboxState: 'unchecked',
      migrationId: 'mig_1',
    }

    expect(responseToItem(response, mockI18n)).toStrictEqual(expectedItem)
  })
})

describe('mapToCheckboxTreeNodes', () => {
  const items: Item[] = [
    {
      id: '1',
      label: 'Item 1',
      type: 'groups',
      checkboxState: 'unchecked',
      linkedId: 'linkedId',
      migrationId: 'migrationId',
      children: [
        {
          id: '2',
          label: 'Item 2',
          type: 'assignments',
          checkboxState: 'unchecked',
        },
      ],
    },
  ]

  const expectedFlatItems: Record<string, CheckboxTreeNode> = {
    '1': {
      id: '1',
      label: 'Item 1',
      type: 'groups',
      checkboxState: 'unchecked',
      linkedId: 'linkedId',
      migrationId: 'migrationId',
      childrenIds: ['2'],
    },
    '2': {
      id: '2',
      label: 'Item 2',
      type: 'assignments',
      parentId: '1',
      checkboxState: 'unchecked',
      childrenIds: [],
    },
  }

  const singleItem: Item = {
    id: '1',
    label: 'Item 1',
    type: 'groups',
    checkboxState: 'unchecked',
    linkedId: 'linkedId',
    migrationId: 'migrationId',
    children: [],
  }

  it('flattens a nested item structure', () => {
    expect(mapToCheckboxTreeNodes(items)).toStrictEqual(expectedFlatItems)
  })

  it('flattens an empty item structure', () => {
    expect(mapToCheckboxTreeNodes([])).toStrictEqual({})
  })

  it('sets the provided parentId on top parent', () => {
    const modifiedExceptedFlatItems = {
      ...expectedFlatItems,
      '1': {
        ...expectedFlatItems['1'],
        parentId: 'topParentId',
      },
    }
    expect(mapToCheckboxTreeNodes(items, 'topParentId')).toStrictEqual(modifiedExceptedFlatItems)
  })

  it('flattens without linkedId', () => {
    const modifiedItem = {...singleItem}
    delete modifiedItem.linkedId
    expect(mapToCheckboxTreeNodes([modifiedItem])).not.toHaveProperty('linkedId')
  })

  it('flattens without migrationId', () => {
    const modifiedItem = {...singleItem}
    delete modifiedItem.migrationId
    expect(mapToCheckboxTreeNodes([modifiedItem])).not.toHaveProperty('migrationId')
  })

  it('flattens without parentId', () => {
    expect(mapToCheckboxTreeNodes([singleItem])).not.toHaveProperty('parentId')
  })
})

describe('generateSelectiveDataResponse', () => {
  const flatItemsWithRootAndNonRoot: Record<string, CheckboxTreeNode> = {
    '1': {
      id: 'copy[all_discussions]',
      label: 'Item 1',
      type: 'groups',
      checkboxState: 'checked',
      childrenIds: ['2'],
    },
    '2': {
      id: '2',
      migrationId: '2_id',
      label: 'Item 1',
      type: 'groups',
      checkboxState: 'checked',
      childrenIds: [],
      parentId: '1',
    },
  }

  const expectedResponseWithRootAndNonRoot = {
    id: 'migration_1',
    user_id: 'user_1',
    workflow_state: 'waiting_for_select',
    copy: {
      all_discussions: '1',
      groups: {
        '2_id': '1',
      },
    },
  }

  it('generates a selective data request on root and non root element', () => {
    expect(
      generateSelectiveDataResponse('migration_1', 'user_1', flatItemsWithRootAndNonRoot),
    ).toStrictEqual(expectedResponseWithRootAndNonRoot)
  })

  it('assigns the waiting_for_select workflow_state', () => {
    expect(generateSelectiveDataResponse('migration_1', 'user_1', {}).workflow_state).toBe(
      'waiting_for_select',
    )
  })

  it('assigns the user_id', () => {
    expect(generateSelectiveDataResponse('migration_1', 'user_1', {}).user_id).toBe('user_1')
  })

  it('assigns the migration_id', () => {
    expect(generateSelectiveDataResponse('migration_1', 'user_1', {}).id).toBe('migration_1')
  })

  describe('root elements', () => {
    const flatItems: Record<string, CheckboxTreeNode> = {
      '1': {
        id: 'copy[all_discussions]',
        label: 'Item 1',
        type: 'groups',
        checkboxState: 'checked',
        childrenIds: [],
      },
    }

    const expectedResponse = {
      id: 'migration_1',
      user_id: 'user_1',
      workflow_state: 'waiting_for_select',
      copy: {
        all_discussions: '1',
      },
    }

    it('generates a selective data request on 1 [] containing id', () => {
      expect(generateSelectiveDataResponse('migration_1', 'user_1', flatItems)).toStrictEqual(
        expectedResponse,
      )
    })

    it('generates a selective data request on multiple [] containing id', () => {
      const modifiedFlatItems: Record<string, CheckboxTreeNode> = {
        ...flatItems,
        '1': {
          ...flatItems['1'],
          id: 'copy[all_discussions][no_matter]',
        },
      }
      expect(
        generateSelectiveDataResponse('migration_1', 'user_1', modifiedFlatItems),
      ).toStrictEqual(expectedResponse)
    })

    it('not generates a selective data request on 0 [] containing id', () => {
      const modifiedFlatItems: Record<string, CheckboxTreeNode> = {
        ...flatItems,
        '1': {
          ...flatItems['1'],
          id: 'copy',
        },
      }
      expect(
        generateSelectiveDataResponse('migration_1', 'user_1', modifiedFlatItems),
      ).toStrictEqual({
        ...expectedResponse,
        copy: {},
      })
    })

    it('not generates a selective data request on unchecked state', () => {
      const modifiedFlatItems: Record<string, CheckboxTreeNode> = {
        ...flatItems,
        '1': {
          ...flatItems['1'],
          checkboxState: 'unchecked',
        },
      }
      expect(
        generateSelectiveDataResponse('migration_1', 'user_1', modifiedFlatItems),
      ).toStrictEqual({
        ...expectedResponse,
        copy: {},
      })
    })

    it('not generates a selective data request on indeterminate state', () => {
      const modifiedFlatItems: Record<string, CheckboxTreeNode> = {
        ...flatItems,
        '1': {
          ...flatItems['1'],
          checkboxState: 'indeterminate',
        },
      }
      expect(
        generateSelectiveDataResponse('migration_1', 'user_1', modifiedFlatItems),
      ).toStrictEqual({
        ...expectedResponse,
        copy: {},
      })
    })

    it('not generates a selective data request existing migration_id', () => {
      const modifiedFlatItems: Record<string, CheckboxTreeNode> = {
        ...flatItems,
        '1': {
          ...flatItems['1'],
          migrationId: 'migrationId',
        },
      }
      expect(
        generateSelectiveDataResponse('migration_1', 'user_1', modifiedFlatItems).copy
          .all_discussions,
      ).toBeUndefined()
    })
  })

  describe('non root elements', () => {
    const flatItems: Record<string, CheckboxTreeNode> = {
      '1': {
        id: '1',
        migrationId: 'mig_id_1',
        label: 'Item 1',
        type: 'groups',
        checkboxState: 'checked',
        childrenIds: [],
      },
    }

    const expectedResponse = {
      id: 'migration_1',
      user_id: 'user_1',
      workflow_state: 'waiting_for_select',
      copy: {
        groups: {
          mig_id_1: '1',
        },
      },
    }

    it('generates a selective data request for groups type on checked state', () => {
      expect(generateSelectiveDataResponse('migration_1', 'user_1', flatItems)).toStrictEqual(
        expectedResponse,
      )
    })

    it('generates a selective data request for groups type on indeterminate state', () => {
      const modifiedFlatItems: Record<string, CheckboxTreeNode> = {
        ...flatItems,
        '1': {
          ...flatItems['1'],
          checkboxState: 'indeterminate',
        },
      }
      expect(
        generateSelectiveDataResponse('migration_1', 'user_1', modifiedFlatItems),
      ).toStrictEqual(expectedResponse)
    })

    it('does not generate a selective data request for groups type on unchecked state', () => {
      const modifiedFlatItems: Record<string, CheckboxTreeNode> = {
        ...flatItems,
        '1': {
          ...flatItems['1'],
          checkboxState: 'unchecked',
        },
      }
      expect(
        generateSelectiveDataResponse('migration_1', 'user_1', modifiedFlatItems),
      ).toStrictEqual({
        ...expectedResponse,
        copy: {},
      })
    })

    it('does not generate a selective data request for groups type on missing migrationId', () => {
      const modifiedFlatItems = {...flatItems}
      delete modifiedFlatItems['1'].migrationId
      expect(
        generateSelectiveDataResponse('migration_1', 'user_1', modifiedFlatItems),
      ).toStrictEqual({
        ...expectedResponse,
        copy: {},
      })
    })
  })
})
