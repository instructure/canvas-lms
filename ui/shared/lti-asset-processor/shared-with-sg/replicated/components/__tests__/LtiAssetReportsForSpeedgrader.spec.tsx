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

// This import needs to be first to ensure that the mocked dependencies are set up before any other imports.
import {
  mockUseLtiAssetProcessors,
  mockUseLtiAssetReports,
} from '../../../__tests__/mockedDependenciesShims'
import {renderComponent} from '../../../__tests__/renderingShims'
import {describe, expect, it} from '../../../__tests__/testPlatformShims'
import {useLtiAssetProcessors, useLtiAssetReports} from '../../../dependenciesShims'
import {defaultGetLtiAssetProcessorsResult} from '../../__fixtures__/default/ltiAssetProcessors'
import {defaultGetLtiAssetReportsResult} from '../../__fixtures__/default/ltiAssetReports'
import {LtiAssetReportsForSpeedgrader} from '../LtiAssetReportsForSpeedgrader'

describe('LtiAssetReportsForSpeedgrader', () => {
  it('renders without crashing', () => {
    mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)
    mockUseLtiAssetReports(
      defaultGetLtiAssetReportsResult({
        attachmentId: '1234',
      }),
    )

    const component = (
      <LtiAssetReportsForSpeedgrader
        assignmentId="123"
        attempt={1}
        submissionType="online_upload"
        attachments={[{_id: '1234', displayName: 'test.txt'}]}
        studentUserId="456"
        studentAnonymousId={null}
      />
    )
    const {queryByText} = renderComponent(component)

    expect(queryByText('My OK Report')).toBeInTheDocument()

    expect(useLtiAssetProcessors).toHaveBeenCalledWith({
      assignmentId: '123',
    })
    expect(useLtiAssetReports).toHaveBeenCalledWith(
      {
        assignmentId: '123',
        studentUserId: '456',
        studentAnonymousId: null,
      },
      {cancel: false},
    )

    expect(queryByText('Resubmit All Files')).toBeInTheDocument()
  })
})
