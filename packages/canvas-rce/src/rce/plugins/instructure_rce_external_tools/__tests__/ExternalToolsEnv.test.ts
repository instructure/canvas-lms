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

import RCEWrapper from '../../../RCEWrapper'
import type {RCEWrapperInterface} from '../../../types'
import {externalToolsEnvFor, ExternalToolsEditor} from '../ExternalToolsEnv'
import {fallbackIframeAllowances} from '../constants'

describe('ExternalToolsEnv', () => {
  const ltiTools1 = [
    {id: 123, name: 'One two three'},
    {id: 'yay', name: 'Yay!'},
  ]

  const editor = {
    id: 'editor1',
    selection: {
      getContent: jest.fn(),
    },
    editorContainer: document.createElement('div'),
    $: jest.fn(),
    ui: {
      registry: {
        getAll: jest.fn(),
      },
    },
    getContent: jest.fn(),
    focus: jest.fn(),
  } as unknown as jest.Mocked<ExternalToolsEditor>

  const mockRceWrapper = {
    id: 'rce1',
    props: {
      ltiTools: ltiTools1,
      trayProps: {
        contextType: 'course',
        contextId: '17',
      },
      resourceSelectionUrlOverride: null,
      containingCanvasLtiToolId: null,
      externalToolsConfig: {
        ltiIframeAllowances: null as string[] | null,
      },
    },
    insertCode: jest.fn(),
    replaceCode: jest.fn(),
  }

  const nullEnv = () => externalToolsEnvFor(null)
  const editorEnv = () => externalToolsEnvFor(editor)

  beforeAll(() => {
    const rceInstance = mockRceWrapper as unknown as RCEWrapperInterface
    jest
      .spyOn(RCEWrapper, 'getByEditor')
      .mockImplementation(e => (e === editor ? rceInstance : null))
  })

  beforeEach(() => {
    jest.clearAllMocks()
  })

  test('availableRceLtiTools', () => {
    expect(nullEnv().availableRceLtiTools).toEqual([])
    expect(editorEnv().availableRceLtiTools).toEqual(ltiTools1)
  })

  test('contextAssetInfo', () => {
    expect(nullEnv().contextAssetInfo).toBeNull()
    expect(editorEnv().contextAssetInfo).toEqual({
      contextType: 'course',
      contextId: '17',
    })
  })

  test('resourceSelectionUrlOverride', () => {
    expect(nullEnv().resourceSelectionUrlOverride).toBeNull()
    expect(editorEnv().resourceSelectionUrlOverride).toBeNull()
  })

  test('ltiIframeAllowPolicy uses fallback when not provided', () => {
    expect(editorEnv().ltiIframeAllowPolicy).toEqual(fallbackIframeAllowances.join('; '))
  })

  test('ltiIframeAllowPolicy uses provided allowances', () => {
    mockRceWrapper.props.externalToolsConfig.ltiIframeAllowances = ['c', 'd']
    expect(editorEnv().ltiIframeAllowPolicy).toEqual('c; d')
  })
})
