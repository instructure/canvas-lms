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
import userEvent from '@testing-library/user-event'
import DocumentProcessorsSection from '../DocumentProcessorsSection'
import {Submission} from '../../../assignments_show_student'

function setupEnv(overrides = {}) {
  // @ts-expect-error
  global.ENV = {
    ASSET_PROCESSORS: [{id: 'processor1', tool_name: 'Processor 1'}],
    ASSET_REPORTS: [{asset: {_id: '1', attachment_id: '1'}, priority: 0}],
    ASSIGNMENT_NAME: 'Test Assignment',
    ...overrides,
  }
}

describe('DocumentProcessorsSection', () => {
  it('renders AssetReportStatus and StudentAssetReportModal for single attachment', async () => {
    setupEnv()
    const user = userEvent.setup()
    const submission = {
      _id: 's1',
      submissionType: 'online_upload',
      attachments: [
        {
          _id: '1',
          id: '1',
          display_name: '',
        },
      ],
    } as Submission

    render(<DocumentProcessorsSection submission={submission} />)

    expect(screen.getByText('Document processors')).toBeInTheDocument()
    expect(screen.getByText('All good')).toBeInTheDocument()

    await user.click(screen.getByText('All good'))

    await screen.findByText('Document Processors for Test Assignment')
  })

  it('renders AssetReportStatus and StudentAssetReportModal for online_text_entry', async () => {
    setupEnv({
      ASSET_REPORTS: [{asset: {_id: '1', submission_attempt: 4}, priority: 0}],
    })
    const user = userEvent.setup()
    const submission = {
      _id: 's1',
      submissionType: 'online_text_entry',
      attachments: [],
      attempt: 4,
    } as Partial<Submission> as Submission

    render(<DocumentProcessorsSection submission={submission} />)

    expect(screen.getByText('Document processors')).toBeInTheDocument()
    expect(screen.getByText('All good')).toBeInTheDocument()

    await user.click(screen.getByText('All good'))

    await screen.findByText('Document Processors for Test Assignment')
    await screen.findByText('Text submitted to Canvas')
  })

  it('does not render AssetReportStatus if asset processor data is not available', async () => {
    setupEnv({ASSET_PROCESSORS: [], ASSET_REPORTS: []})
    const submission = {
      _id: 's1',
      submissionType: 'online_upload',
      attachments: [
        {
          _id: '1',
          id: '1',
          display_name: '',
        },
      ],
    } as Submission

    render(<DocumentProcessorsSection submission={submission} />)

    expect(screen.queryByText('Document processors')).not.toBeInTheDocument()
    expect(screen.queryByText('All good')).not.toBeInTheDocument()
  })

  it('does not render AssetReportStatus if there is not exactly one attachment', async () => {
    setupEnv()
    const submission = {
      _id: 's1',
      submissionType: 'online_upload',
      attachments: [
        {
          _id: '1',
          id: '1',
          display_name: '',
        },
        {
          _id: '2',
          id: '2',
          display_name: '',
        },
      ],
    } as Submission

    render(<DocumentProcessorsSection submission={submission} />)

    expect(screen.queryByText('Document processors')).not.toBeInTheDocument()
  })

  it('does not render StudentAssetReportModal without clicking on the status', async () => {
    setupEnv()
    const submission = {
      _id: 's1',
      submissionType: 'online_upload',
      attachments: [
        {
          _id: '1',
          id: '1',
          display_name: '',
        },
      ],
    } as Submission

    render(<DocumentProcessorsSection submission={submission} />)

    expect(screen.queryByText('Document Processors for Test Assignment')).not.toBeInTheDocument()
  })
})
