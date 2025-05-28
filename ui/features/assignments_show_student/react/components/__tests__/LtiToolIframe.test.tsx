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

import {render, screen} from '@testing-library/react'
import {LtiToolIframe} from '../LtiToolIframe'
import {GlobalEnv} from '@canvas/global/env/GlobalEnv'

describe('LtiToolIframe', () => {
  const ENV = {
    LTI_TOOL: 'true',
    COURSE_ID: '1',
    ASSIGNMENT_ID: '2',
    current_user_id: '3',
    LTI_TOOL_ID: '1',
    LTI_TOOL_SELECTION_HEIGHT: '500',
    LTI_TOOL_SELECTION_WIDTH: '800',
  }

  let globalEnv: GlobalEnv

  const mockSubmission = {state: 'graded'}
  const mockAssignment = {submissionTypes: ['external_tool']}

  beforeAll(() => {
    globalEnv = {...window.ENV}
  })

  beforeEach(() => {
    window.ENV = {...globalEnv, ...ENV}
  })

  it('renders the submission details link when submission is graded and includes external_tool', () => {
    render(<LtiToolIframe submission={mockSubmission} assignment={mockAssignment} />)

    const link = screen.getByTestId('view-submission-link')
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute('href', `/courses/1/assignments/2/submissions/3`)
  })

  it('renders the ToolLaunchIframe when showTool is true', () => {
    render(<LtiToolIframe submission={mockSubmission} assignment={mockAssignment} />)

    const iframe = screen.getByTestId('lti-external-tool')
    expect(iframe).toBeInTheDocument()
    expect(iframe).toHaveAttribute('src', `/courses/1/assignments/2/tool_launch`)
  })

  it('does not render anything when showTool, showSubmissionDetailsLink, and ltiConfig are all false/null', () => {
    window.ENV = {...globalEnv, ...ENV, LTI_TOOL: 'false'}
    render(<LtiToolIframe submission={{state: 'ungraded'}} assignment={{submissionTypes: []}} />)

    expect(screen.queryByTestId('view-submission-link')).not.toBeInTheDocument()
    expect(screen.queryByTestId('lti-external-tool')).not.toBeInTheDocument()
  })

  it('applies correct iframe dimensions when ltiConfig is provided', async () => {
    render(<LtiToolIframe submission={mockSubmission} assignment={mockAssignment} />)

    const iframe = await screen.findByTestId('lti-external-tool')
    expect(iframe).toHaveStyle({height: '500px', width: '800px'})
  })
})
