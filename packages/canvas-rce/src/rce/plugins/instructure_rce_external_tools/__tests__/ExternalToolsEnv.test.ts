// @ts-nocheck
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
  ExternalToolsEditor,
  externalToolsEnvFor,
  fallbackIframeAllowances,
} from '../ExternalToolsEnv'
import {createDeepMockProxy} from '../../../../util/__tests__/deepMockProxy'
import RCEWrapper from '../../../RCEWrapper'

describe('ExternalToolsEnv', () => {
  const ltiTools1 = [
    {id: 123, name: 'One two three'},
    {id: 'yay', name: 'Yay!'},
  ]

  const editor = createDeepMockProxy<ExternalToolsEditor>()
  const rceWrapper = createDeepMockProxy<RCEWrapper>()

  const nullEnv = () => externalToolsEnvFor(null)
  const editorEnv = () => externalToolsEnvFor(editor)

  beforeAll(() => {
    jest
      .spyOn(RCEWrapper, 'getByEditor')
      .mockImplementation(e => (e === editor ? rceWrapper : null))
  })

  beforeEach(() => {
    editor.mockClear()
    rceWrapper.mockClear()
  })

  test('availableRceLtiTools', () => {
    expect(nullEnv().availableRceLtiTools).toEqual([])

    rceWrapper.props.ltiTools = ltiTools1
    expect(editorEnv().availableRceLtiTools).toEqual(ltiTools1)
  })

  test('contextAssetInfo', () => {
    expect(editorEnv().contextAssetInfo).toEqual(null)

    rceWrapper.props.trayProps = {
      contextType: 'user',
      contextId: '4567',
    }

    expect(editorEnv().contextAssetInfo).toEqual({
      contextType: 'user',
      contextId: '4567',
    })

    // Containing context should override
    rceWrapper.props.trayProps = {
      contextType: 'user',
      contextId: '4567',
      containingContext: {
        contextType: 'course',
        contextId: '1234',
      },
    }

    expect(editorEnv().contextAssetInfo).toEqual({
      contextType: 'course',
      contextId: '1234',
    })
  })

  test('canvasOrigin', () => {
    expect(nullEnv().canvasOrigin).toEqual(window.location.origin)

    // Ensure editor override works
    rceWrapper.props.canvasOrigin = 'https://example.com'

    expect(editorEnv().canvasOrigin).toEqual('https://example.com')
  })

  test('MAX_MRU_LTI_TOOLS', () => {
    expect(nullEnv().maxMruTools).toEqual(5)

    // Ensure editor override works
    rceWrapper.props.externalToolsConfig = {
      maxMruTools: 17,
    }

    expect(editorEnv().maxMruTools).toEqual(17)
  })

  test('ENV_a2_student_view', () => {
    expect(nullEnv().isA2StudentView).toEqual(false)

    // Ensure editor override works
    rceWrapper.props.externalToolsConfig = {
      isA2StudentView: true,
    }

    expect(editorEnv().isA2StudentView).toEqual(true)
  })

  test('resourceSelectionUrlOverride', () => {
    rceWrapper.props.externalToolsConfig = {}

    // Ensure it handles null
    expect(editorEnv().resourceSelectionUrlOverride).toEqual(null)

    rceWrapper.props.externalToolsConfig = {
      resourceSelectionUrlOverride: 'https://example.com/lti/resource_selection',
    }

    expect(editorEnv().resourceSelectionUrlOverride).toEqual(
      'https://example.com/lti/resource_selection'
    )
  })

  test('ltiIframeAllowances', () => {
    expect(editorEnv().ltiIframeAllowPolicy).toEqual(fallbackIframeAllowances.join('; '))

    // Ensure editor override works
    rceWrapper.props.externalToolsConfig.ltiIframeAllowances = ['c', 'd']

    expect(editorEnv().ltiIframeAllowPolicy).toEqual('c; d')
  })
})
