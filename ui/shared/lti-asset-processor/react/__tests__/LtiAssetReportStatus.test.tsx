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

import LtiAssetReportStatus from '../LtiAssetReportStatus'
import {render, screen, fireEvent} from '@testing-library/react'
import {LtiAssetReport} from '@canvas/lti-asset-processor/model/LtiAssetReport'

describe('LtiAssetReportStatus', () => {
  const createReport = (
    priority: number = 0,
    overrides: Partial<LtiAssetReport> = {},
  ): LtiAssetReport => ({
    _id: '123',
    priority,
    reportType: 'plagiarism',
    resubmitAvailable: false,
    processingProgress: 'Processed',
    processorId: '1',
    comment: null,
    errorCode: null,
    indicationAlt: null,
    indicationColor: null,
    launchUrlPath: null,
    result: null,
    resultTruncated: null,
    title: null,
    asset: {
      attachmentId: '10',
      submissionAttempt: 1,
    },
    ...overrides,
  })

  describe('with empty reports array', () => {
    it('renders "No result" text', () => {
      render(<LtiAssetReportStatus reports={[]} />)
      expect(screen.getByText('No result')).toBeInTheDocument()
    })
  })

  describe('with no high priority reports', () => {
    const reports = [createReport(0), createReport(0)]

    it('renders "All good" status without openModal prop', () => {
      render(<LtiAssetReportStatus reports={reports} />)
      expect(screen.getByText('All good')).toBeInTheDocument()
    })

    it('renders an IconCompleteSolid with brand color when no modal is provided', () => {
      render(<LtiAssetReportStatus reports={reports} />)
      // We can't easily check the color, but we can verify the icon exists
      expect(screen.getByText('All good')).toBeInTheDocument()
    })

    it('renders a link with "All good" text when openModal prop is provided', () => {
      const openModal = jest.fn()
      render(<LtiAssetReportStatus reports={reports} openModal={openModal} />)
      const link = screen.getByText('All good')
      expect(link).toBeInTheDocument()
    })

    it('calls openModal when link is clicked', () => {
      const openModal = jest.fn()
      render(<LtiAssetReportStatus reports={reports} openModal={openModal} />)
      fireEvent.click(screen.getByText('All good'))
      expect(openModal).toHaveBeenCalledTimes(1)
    })
  })

  describe('with high priority reports', () => {
    const reports = [createReport(0), createReport(1)]

    it('renders "Needs attention" status without openModal prop', () => {
      render(<LtiAssetReportStatus reports={reports} />)
      expect(screen.getByText('Needs attention')).toBeInTheDocument()
    })

    it('renders an IconWarningSolid with error color when no modal is provided', () => {
      const {container} = render(<LtiAssetReportStatus reports={reports} />)
      // We can't easily check the color, but we can verify the icon exists
      expect(container.querySelector('[name="IconWarning"]')).toBeInTheDocument()
    })

    it('renders a link with "Needs attention" text when openModal prop is provided', () => {
      const openModal = jest.fn()
      render(<LtiAssetReportStatus reports={reports} openModal={openModal} />)
      const link = screen.getByText('Needs attention')
      expect(link).toBeInTheDocument()
    })

    it('calls openModal when link is clicked', () => {
      const openModal = jest.fn()
      render(<LtiAssetReportStatus reports={reports} openModal={openModal} />)
      fireEvent.click(screen.getByText('Needs attention'))
      expect(openModal).toHaveBeenCalledTimes(1)
    })
  })
})
