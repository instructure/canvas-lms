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

import {ZLtiDeploymentId} from '../../../../model/LtiDeploymentId'
import {mergeDeployments} from '../mergeDeployments'
import {ZLtiContextControlId} from '../../../../model/LtiContextControl'
import {mockContextControl, mockDeployment} from './helpers'

describe('mergeDeployments', () => {
  it('adds a deployment to an empty array', () => {
    const contextControls = [mockContextControl({id: ZLtiContextControlId.parse('a')})]
    const deployment = mockDeployment({
      id: ZLtiDeploymentId.parse('1'),
      context_controls: contextControls,
    })
    const result = mergeDeployments([], deployment)
    expect(result).toEqual([deployment])
  })

  it('merges context_controls when deployment with same id exists', () => {
    const contextControlsA = [mockContextControl({id: ZLtiContextControlId.parse('a')})]
    const contextControlsB = [mockContextControl({id: ZLtiContextControlId.parse('b')})]
    const existing = mockDeployment({
      id: ZLtiDeploymentId.parse('1'),
      context_controls: contextControlsA,
    })
    const incoming = mockDeployment({
      id: ZLtiDeploymentId.parse('1'),
      context_controls: contextControlsB,
    })
    const result = mergeDeployments([existing], incoming)
    expect(result).toHaveLength(1)
    expect(result[0].id).toBe('1')
    expect(result[0].context_controls).toEqual([...contextControlsA, ...contextControlsB])
  })

  it('appends deployment if id does not exist', () => {
    const contextControlsA = [mockContextControl({id: ZLtiContextControlId.parse('a')})]
    const contextControlsB = [mockContextControl({id: ZLtiContextControlId.parse('b')})]
    const existing = mockDeployment({
      id: ZLtiDeploymentId.parse('1'),
      context_controls: contextControlsA,
    })
    const incoming = mockDeployment({
      id: ZLtiDeploymentId.parse('2'),
      context_controls: contextControlsB,
    })
    const result = mergeDeployments([existing], incoming)
    expect(result).toHaveLength(2)
    expect(result[1]).toEqual(incoming)
  })

  it('handles undefined context_controls in existing deployment', () => {
    const contextControlsB = [mockContextControl({id: ZLtiContextControlId.parse('b')})]
    const existing = mockDeployment({id: ZLtiDeploymentId.parse('1')})
    const incoming = mockDeployment({
      id: ZLtiDeploymentId.parse('1'),
      context_controls: contextControlsB,
    })
    expect(mergeDeployments([existing], incoming)[0].context_controls).toEqual(contextControlsB)
  })

  it('handles undefined context_controls in incoming deployment', () => {
    const contextControlsA = [mockContextControl({id: ZLtiContextControlId.parse('a')})]
    const existing = mockDeployment({
      id: ZLtiDeploymentId.parse('1'),
      context_controls: contextControlsA,
    })
    const incoming = mockDeployment({id: ZLtiDeploymentId.parse('1')})
    expect(mergeDeployments([existing], incoming)[0].context_controls).toEqual(contextControlsA)
  })

  it('handles both context_controls undefined', () => {
    const existing = mockDeployment({id: ZLtiDeploymentId.parse('1')})
    const incoming = mockDeployment({id: ZLtiDeploymentId.parse('1')})
    expect(mergeDeployments([existing], incoming)[0].context_controls).toEqual([])
  })

  it('does not mutate the original deployments array', () => {
    const contextControlsA = [mockContextControl({id: ZLtiContextControlId.parse('a')})]
    const contextControlsB = [mockContextControl({id: ZLtiContextControlId.parse('b')})]
    const existing = mockDeployment({
      id: ZLtiDeploymentId.parse('1'),
      context_controls: contextControlsA,
    })
    const deployments = [existing]
    const incoming = mockDeployment({
      id: ZLtiDeploymentId.parse('1'),
      context_controls: contextControlsB,
    })
    const result = mergeDeployments(deployments, incoming)
    expect(deployments).toEqual([existing])
    expect(result).not.toBe(deployments)
  })
})
