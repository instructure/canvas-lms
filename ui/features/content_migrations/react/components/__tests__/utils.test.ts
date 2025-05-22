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
  compareMigrators,
  mapToCheckboxTreeNodes,
  generateSelectiveDataResponse,
  humanReadableSize,
  responseToItem,
} from '../utils'
import type {GenericItemResponse, Migrator} from '../types'
import type {Item} from '../content_selection_modal'
import type {CheckboxTreeNode, ItemType, SwitchState} from '@canvas/content-migrations'

describe('compareMigrators', () => {
  const migratorFactory = (type: string, name: string): Migrator => {
    return {
      type,
      name,
      requires_file_upload: true,
      required_settings: '',
    }
  }

  describe('when one migrator has higher priority, and other does not', () => {
    it('returns -1 when `a` migrator has higher priority no string comparison is applied', () => {
      const a = migratorFactory('course_copy_importer', 'D')
      const b = migratorFactory('zip_file_importer', 'A')

      expect(compareMigrators(a, b)).toBe(-1)
    })

    it('returns 1 when `b` migrator has higher priority no string comparison is applied', () => {
      const a = migratorFactory('zip_file_importer', 'A')
      const b = migratorFactory('canvas_cartridge_importer', 'D')

      expect(compareMigrators(a, b)).toBe(1)
    })
  })

  describe('when both migrators have higher priority', () => {
    it('returns -1 when `a` migrator name has lower string comparison', () => {
      const a = migratorFactory('canvas_cartridge_importer', 'A')
      const b = migratorFactory('course_copy_importer', 'D')

      expect(compareMigrators(a, b)).toBe(-1)
    })

    it('returns 1 when `b` migrator name has lower string comparison', () => {
      const a = migratorFactory('course_copy_importer', 'D')
      const b = migratorFactory('canvas_cartridge_importer', 'A')

      expect(compareMigrators(a, b)).toBe(1)
    })
  })

  describe('when both migrators have lower priority', () => {
    it('returns -1 when `a` migrator name has lower string comparison', () => {
      const a = migratorFactory('zip_file_importer', 'A')
      const b = migratorFactory('zip_file_importer', 'D')

      expect(compareMigrators(a, b)).toBe(-1)
    })

    it('returns 1 when `b` migrator name has lower string comparison', () => {
      const a = migratorFactory('zip_file_importer', 'D')
      const b = migratorFactory('zip_file_importer', 'A')

      expect(compareMigrators(a, b)).toBe(1)
    })
  })
})

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

  describe('subContextModule marking', () => {
    const subItems: GenericItemResponse[] = [
      {
        type: 'context_modules',
        title: 'cm',
        property: 'cm_2',
        migration_id: 'mig_2',
      },
    ]

    const commonResponse: GenericItemResponse = {
      type: 'assignments',
      title: 'Assignment 1',
      property: 'id_1',
      migration_id: 'mig_1',
      sub_items: subItems,
    }

    const commonExpectedItem = {
      id: 'id_1',
      label: 'Assignment 1 (1)',
      type: 'assignments',
      checkboxState: 'unchecked',
      migrationId: 'mig_1',
      children: [
        {
          id: 'cm_2',
          label: 'cm',
          type: 'context_modules',
          checkboxState: 'unchecked',
          migrationId: 'mig_2',
        },
      ],
    }

    it('converts a GenericItemResponse to an Item and mark if it has a subContextModule', () => {
      const response: GenericItemResponse = {
        ...commonResponse,
        submodule_count: 1,
      }

      const expectedItem = {
        ...commonExpectedItem,
        children: [
          {
            ...commonExpectedItem.children[0],
            isSubModule: true,
          },
        ],
      }

      expect(responseToItem(response, mockI18n)).toStrictEqual(expectedItem)
    })

    it('converts a GenericItemResponse to an Item but not mark as subContextModule if submodule count is 0', () => {
      const response: GenericItemResponse = {
        ...commonResponse,
        submodule_count: 0,
      }

      expect(responseToItem(response, mockI18n)).toStrictEqual(commonExpectedItem)
    })
  })
})

describe('mapToCheckboxTreeNodes', () => {
  const items: Item[] = [
    {
      id: '1',
      label: 'Item 1',
      type: 'context_modules',
      checkboxState: 'unchecked',
      linkedId: 'linkedId',
      migrationId: 'migrationId',
      children: [
        {
          id: '2',
          label: 'Item 2',
          type: 'context_modules',
          checkboxState: 'unchecked',
          migrationId: 'migrationId2',
          isSubModule: true,
          children: [
            {
              id: '3',
              label: 'Item 3',
              type: 'context_modules',
              checkboxState: 'unchecked',
              migrationId: 'migrationId3',
              isSubModule: true,
            },
          ],
        },
      ],
    },
  ]

  const expectedTreeNodes: Record<string, CheckboxTreeNode> = {
    '1': {
      id: '1',
      label: 'Item 1',
      type: 'context_modules',
      checkboxState: 'unchecked',
      linkedId: 'linkedId',
      migrationId: 'id_migrationId',
      childrenIds: ['2'],
    },
    '2': {
      id: '2',
      label: 'Item 2',
      type: 'context_modules',
      parentId: '1',
      checkboxState: 'unchecked',
      migrationId: 'id_migrationId2',
      importAsOneModuleItemState: 'off',
      childrenIds: ['3'],
    },
    '3': {
      id: '3',
      label: 'Item 3',
      type: 'context_modules',
      parentId: '2',
      checkboxState: 'unchecked',
      migrationId: 'id_migrationId3',
      importAsOneModuleItemState: 'disabled',
      childrenIds: [],
    },
  }

  const singleItem: Item = {
    id: '1',
    label: 'Item 1',
    type: 'groups',
    checkboxState: 'unchecked',
    linkedId: 'linkedId',
    migrationId: 'id_migrationId',
    children: [],
  }

  it('flattens a nested item structure', () => {
    expect(mapToCheckboxTreeNodes(items)).toStrictEqual(expectedTreeNodes)
  })

  it('flattens an empty item structure', () => {
    expect(mapToCheckboxTreeNodes([])).toStrictEqual({})
  })

  it('sets the provided parentId on top parent', () => {
    const modifiedExceptedTreeNodes = {
      ...expectedTreeNodes,
      '1': {
        ...expectedTreeNodes['1'],
        parentId: 'topParentId',
      },
    }
    expect(mapToCheckboxTreeNodes(items, 'topParentId')).toStrictEqual(modifiedExceptedTreeNodes)
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

  it('flattens without importAsOneModuleItemState', () => {
    expect(mapToCheckboxTreeNodes([singleItem])).not.toHaveProperty('importAsOneModuleItemState')
  })
})

describe('generateSelectiveDataResponse', () => {
  const treeNodesWithRootAndNonRoot: Record<string, CheckboxTreeNode> = {
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
      generateSelectiveDataResponse('migration_1', 'user_1', treeNodesWithRootAndNonRoot),
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
    const treeNodes: Record<string, CheckboxTreeNode> = {
      'copy[all_discussions]': {
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
      expect(generateSelectiveDataResponse('migration_1', 'user_1', treeNodes)).toStrictEqual(
        expectedResponse,
      )
    })

    it('generates a selective data request on multiple [] containing id', () => {
      const modifiedTreeNodes: Record<string, CheckboxTreeNode> = {
        ...treeNodes,
        'copy[all_discussions]': {
          ...treeNodes['copy[all_discussions]'],
          id: 'copy[all_discussions][no_matter]',
        },
      }
      expect(
        generateSelectiveDataResponse('migration_1', 'user_1', modifiedTreeNodes),
      ).toStrictEqual(expectedResponse)
    })

    it('not generates a selective data request on 0 [] containing id', () => {
      const modifiedTreeNodes: Record<string, CheckboxTreeNode> = {
        ...treeNodes,
        'copy[all_discussions]': {
          ...treeNodes['copy[all_discussions]'],
          id: 'copy',
        },
      }
      expect(
        generateSelectiveDataResponse('migration_1', 'user_1', modifiedTreeNodes),
      ).toStrictEqual({
        ...expectedResponse,
        copy: {},
      })
    })

    it('not generates a selective data request on unchecked state', () => {
      const modifiedTreeNodes: Record<string, CheckboxTreeNode> = {
        ...treeNodes,
        'copy[all_discussions]': {
          ...treeNodes['copy[all_discussions]'],
          checkboxState: 'unchecked',
        },
      }
      expect(
        generateSelectiveDataResponse('migration_1', 'user_1', modifiedTreeNodes),
      ).toStrictEqual({
        ...expectedResponse,
        copy: {},
      })
    })

    it('not generates a selective data request on indeterminate state', () => {
      const modifiedTreeNodes: Record<string, CheckboxTreeNode> = {
        ...treeNodes,
        'copy[all_discussions]': {
          ...treeNodes['copy[all_discussions]'],
          checkboxState: 'indeterminate',
        },
      }
      expect(
        generateSelectiveDataResponse('migration_1', 'user_1', modifiedTreeNodes),
      ).toStrictEqual({
        ...expectedResponse,
        copy: {},
      })
    })

    it('not generates a selective data request existing migration_id', () => {
      const modifiedTreeNodes: Record<string, CheckboxTreeNode> = {
        ...treeNodes,
        'copy[all_discussions]': {
          ...treeNodes['copy[all_discussions]'],
          migrationId: 'migrationId',
        },
      }
      expect(
        generateSelectiveDataResponse('migration_1', 'user_1', modifiedTreeNodes).copy
          .all_discussions,
      ).toBeUndefined()
    })
  })

  describe('non root elements', () => {
    const treeNodes: Record<string, CheckboxTreeNode> = {
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
      // Create a mock implementation to ensure consistent behavior
      const mockTreeNodes: Record<string, CheckboxTreeNode> = {
        '1': {
          id: '1',
          migrationId: 'mig_id_1',
          label: 'Item 1',
          type: 'groups' as ItemType,
          checkboxState: 'checked',
          childrenIds: [],
        },
      }

      const result = generateSelectiveDataResponse('migration_1', 'user_1', mockTreeNodes)

      // Ensure the result has the expected structure
      expect(result).toEqual({
        id: 'migration_1',
        user_id: 'user_1',
        workflow_state: 'waiting_for_select',
        copy: expect.objectContaining({
          groups: expect.objectContaining({
            mig_id_1: '1',
          }),
        }),
      })
    })

    it('generates a selective data request for groups type on indeterminate state', () => {
      const modifiedTreeNodes: Record<string, CheckboxTreeNode> = {
        ...treeNodes,
        '1': {
          ...treeNodes['1'],
          checkboxState: 'indeterminate',
        },
      }

      const modifiedExpectedResponse = {
        ...expectedResponse,
        copy: {},
      }

      expect(
        generateSelectiveDataResponse('migration_1', 'user_1', modifiedTreeNodes),
      ).toStrictEqual(modifiedExpectedResponse)
    })

    it('does not generate a selective data request for groups type on unchecked state', () => {
      const modifiedTreeNodes: Record<string, CheckboxTreeNode> = {
        ...treeNodes,
        '1': {
          ...treeNodes['1'],
          checkboxState: 'unchecked',
        },
      }
      expect(
        generateSelectiveDataResponse('migration_1', 'user_1', modifiedTreeNodes),
      ).toStrictEqual({
        ...expectedResponse,
        copy: {},
      })
    })

    it('does not generate a selective data request for groups type on missing migrationId', () => {
      const modifiedTreeNodes = {...treeNodes}
      delete modifiedTreeNodes['1'].migrationId
      expect(
        generateSelectiveDataResponse('migration_1', 'user_1', modifiedTreeNodes),
      ).toStrictEqual({
        ...expectedResponse,
        copy: {},
      })
    })
  })

  describe('request data adjustment for import as one module item', () => {
    const createNodesWithImportAsOneModuleItemState = (
      importAsOneModuleItemStateIdStatePairs: {id: string; importState: SwitchState}[] = [],
    ): Record<string, CheckboxTreeNode> => {
      const nodes: Record<string, CheckboxTreeNode> = {
        '1': {
          id: '1',
          label: 'Context modules root',
          type: 'context_modules',
          checkboxState: 'checked',
          childrenIds: ['2'],
        },
        '2': {
          id: '2',
          migrationId: '2_id',
          label: 'CM 1',
          type: 'context_modules',
          checkboxState: 'checked',
          childrenIds: ['3'],
          parentId: '1',
        },
        '3': {
          id: '3',
          migrationId: '3_id',
          label: 'CM 1',
          type: 'context_modules',
          checkboxState: 'checked',
          childrenIds: ['4'],
          parentId: '2',
        },
        '4': {
          id: '4',
          migrationId: '4_id',
          label: 'CM 1',
          type: 'context_modules',
          checkboxState: 'checked',
          childrenIds: [],
          parentId: '3',
        },
      }

      importAsOneModuleItemStateIdStatePairs.forEach(pair => {
        if (nodes[pair.id]) {
          nodes[pair.id].importAsOneModuleItemState = pair.importState
        }
      })

      return nodes
    }

    const commonExpectedResponseParts = {
      id: 'migration_1',
      user_id: 'user_1',
      workflow_state: 'waiting_for_select',
    }

    describe('3th and 4th submodules are marked for standalone import', () => {
      const expectedResponse = {
        ...commonExpectedResponseParts,
        copy: {
          context_modules: {
            '4_id': '1',
          },
        },
      }

      it('imports only the last child sub context module', () => {
        expect(
          generateSelectiveDataResponse(
            'migration_1',
            'user_1',
            createNodesWithImportAsOneModuleItemState([
              {id: '3', importState: 'on'},
              {id: '4', importState: 'on'},
            ]),
          ),
        ).toStrictEqual(expectedResponse)
      })
    })

    describe('3th marked for standalone import and 4th marked for import as one item', () => {
      const expectedResponse = {
        ...commonExpectedResponseParts,
        copy: {
          context_modules: {
            '3_id': '1',
            '4_id': '1',
          },
        },
      }

      it('imports only the last child sub context module', () => {
        expect(
          generateSelectiveDataResponse(
            'migration_1',
            'user_1',
            createNodesWithImportAsOneModuleItemState([
              {id: '3', importState: 'on'},
              {id: '4', importState: 'off'},
            ]),
          ),
        ).toStrictEqual(expectedResponse)
      })
    })

    describe('3th marked for import as one item and 4th is disabled', () => {
      const expectedResponse = {
        ...commonExpectedResponseParts,
        copy: {
          context_modules: {
            '2_id': '1',
            '3_id': '1',
            '4_id': '1',
          },
        },
      }

      it('imports only the last child sub context module', () => {
        expect(
          generateSelectiveDataResponse(
            'migration_1',
            'user_1',
            createNodesWithImportAsOneModuleItemState([
              {id: '3', importState: 'off'},
              {id: '4', importState: 'disabled'},
            ]),
          ),
        ).toStrictEqual(expectedResponse)
      })
    })

    describe('3th and 4th marked for import as one item', () => {
      const expectedResponse = {
        ...commonExpectedResponseParts,
        copy: {
          context_modules: {
            '2_id': '1',
            '3_id': '1',
            '4_id': '1',
          },
        },
      }

      it('imports only the last child sub context module', () => {
        expect(
          generateSelectiveDataResponse(
            'migration_1',
            'user_1',
            createNodesWithImportAsOneModuleItemState([
              {id: '3', importState: 'off'},
              {id: '4', importState: 'off'},
            ]),
          ),
        ).toStrictEqual(expectedResponse)
      })
    })

    describe('3th and 4th are disabled', () => {
      const expectedResponse = {
        ...commonExpectedResponseParts,
        copy: {
          context_modules: {
            '2_id': '1',
            '3_id': '1',
            '4_id': '1',
          },
        },
      }

      it('imports only the last child sub context module', () => {
        expect(
          generateSelectiveDataResponse(
            'migration_1',
            'user_1',
            createNodesWithImportAsOneModuleItemState([
              {id: '3', importState: 'disabled'},
              {id: '4', importState: 'disabled'},
            ]),
          ),
        ).toStrictEqual(expectedResponse)
      })
    })

    describe('4th child removed', () => {
      const expectedResponse = {
        ...commonExpectedResponseParts,
        copy: {
          context_modules: {
            '2_id': '1',
            '3_id': '1',
          },
        },
      }

      it('imports only the last child sub context module', () => {
        const nodeInput = createNodesWithImportAsOneModuleItemState([{id: '3', importState: 'off'}])
        delete nodeInput['4']
        expect(generateSelectiveDataResponse('migration_1', 'user_1', nodeInput)).toStrictEqual(
          expectedResponse,
        )
      })
    })
  })
})
