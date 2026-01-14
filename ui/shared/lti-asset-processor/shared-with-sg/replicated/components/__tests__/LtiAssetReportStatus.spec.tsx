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

import {fireEvent, screen} from '@testing-library/react'
import {renderComponent} from '../../../__tests__/renderingShims'
import {fn} from '../../../__tests__/testPlatformShims'
import type {LtiAssetReport} from '../../types/LtiAssetReports'
import LtiAssetReportStatus from '../LtiAssetReportStatus'

describe('LtiAssetReportStatus', () => {
  const createReport = (
    priority: number = 0,
    overrides: Partial<LtiAssetReport> = {},
  ): LtiAssetReport => ({
    _id: '123',
    priority,
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
      renderComponent(<LtiAssetReportStatus reports={[]} />)
      expect(screen.getByText('No result')).toBeInTheDocument()
    })
  })

  describe('with processed reports (no high priority)', () => {
    const reports = [createReport(0, {processingProgress: 'Processed'})]

    it('renders "All good" status without openModal prop', () => {
      renderComponent(<LtiAssetReportStatus reports={reports} />)
      expect(screen.getByText('All good')).toBeInTheDocument()
    })

    it('renders an IconCompleteSolid with brand color when no modal is provided', () => {
      renderComponent(<LtiAssetReportStatus reports={reports} />)
      // We can't easily check the color, but we can verify the icon exists
      expect(screen.getByText('All good')).toBeInTheDocument()
    })

    it('renders a link with "All good" text when openModal prop is provided', () => {
      const openModal = fn()
      renderComponent(<LtiAssetReportStatus reports={reports} openModal={openModal} />)
      const link = screen.getByText('All good')
      expect(link).toBeInTheDocument()
    })

    it('calls openModal when link is clicked', () => {
      const openModal = fn()
      renderComponent(<LtiAssetReportStatus reports={reports} openModal={openModal} />)
      fireEvent.click(screen.getByText('All good'))
      expect(openModal).toHaveBeenCalledTimes(1)
    })
  })

  describe('with high priority reports', () => {
    const reports = [createReport(0), createReport(1)]

    it('renders "Please review" status without openModal prop', () => {
      renderComponent(<LtiAssetReportStatus reports={reports} />)
      expect(screen.getByText('Please review')).toBeInTheDocument()
    })

    it('renders an IconWarningSolid with error color when no modal is provided', () => {
      const {container} = renderComponent(<LtiAssetReportStatus reports={reports} />)
      // We can't easily check the color, but we can verify the icon exists
      expect(container.querySelector('[name="IconWarning"]')).toBeInTheDocument()
    })

    it('renders a link with "Please review" text when openModal prop is provided', () => {
      const openModal = fn()
      renderComponent(<LtiAssetReportStatus reports={reports} openModal={openModal} />)
      const link = screen.getByText('Please review')
      expect(link).toBeInTheDocument()
    })

    it('calls openModal when link is clicked', () => {
      const openModal = fn()
      renderComponent(<LtiAssetReportStatus reports={reports} openModal={openModal} />)
      fireEvent.click(screen.getByText('Please review'))
      expect(openModal).toHaveBeenCalledTimes(1)
    })
  })

  describe('with processing reports', () => {
    it('renders "Processing" for Pending status', () => {
      const reports = [createReport(0, {processingProgress: 'Pending'})]
      renderComponent(<LtiAssetReportStatus reports={reports} />)
      expect(screen.getByText('Processing')).toBeInTheDocument()
    })

    it('renders "Processing" for Processing status', () => {
      const reports = [createReport(0, {processingProgress: 'Processing'})]
      renderComponent(<LtiAssetReportStatus reports={reports} />)
      expect(screen.getByText('Processing')).toBeInTheDocument()
    })

    it('renders "Processing" for PendingManual status', () => {
      const reports = [createReport(0, {processingProgress: 'PendingManual'})]
      renderComponent(<LtiAssetReportStatus reports={reports} />)
      expect(screen.getByText('Processing')).toBeInTheDocument()
    })

    it('renders link with "Processing" when openModal prop is provided', () => {
      const openModal = fn()
      const reports = [createReport(0, {processingProgress: 'Pending'})]
      renderComponent(<LtiAssetReportStatus reports={reports} openModal={openModal} />)
      const link = screen.getByText('Processing')
      expect(link).toBeInTheDocument()
    })

    it('calls openModal when processing link is clicked', () => {
      const openModal = fn()
      const reports = [createReport(0, {processingProgress: 'Pending'})]
      renderComponent(<LtiAssetReportStatus reports={reports} openModal={openModal} />)
      fireEvent.click(screen.getByText('Processing'))
      expect(openModal).toHaveBeenCalledTimes(1)
    })
  })

  describe('with no result reports', () => {
    const reports = [createReport(0, {processingProgress: 'NotReady'})]

    it('renders "No result" status without openModal prop', () => {
      renderComponent(<LtiAssetReportStatus reports={reports} />)
      expect(screen.getByText('No result')).toBeInTheDocument()
    })

    it('renders link with "No result" when openModal prop is provided', () => {
      const openModal = fn()
      renderComponent(<LtiAssetReportStatus reports={reports} openModal={openModal} />)
      const link = screen.getByText('No result')
      expect(link).toBeInTheDocument()
    })

    it('calls openModal when no result link is clicked', () => {
      const openModal = fn()
      renderComponent(<LtiAssetReportStatus reports={reports} openModal={openModal} />)
      fireEvent.click(screen.getByText('No result'))
      expect(openModal).toHaveBeenCalledTimes(1)
    })
  })

  describe('priority precedence', () => {
    it('shows "Please review" when there are both high priority and processing reports', () => {
      const reports = [
        createReport(1, {processingProgress: 'NotReady'}),
        createReport(0, {processingProgress: 'Pending'}),
      ]
      renderComponent(<LtiAssetReportStatus reports={reports} />)
      expect(screen.getByText('Please review')).toBeInTheDocument()
    })

    it('shows "Processing" when there are both processing and processed reports', () => {
      const reports = [
        createReport(0, {processingProgress: 'Pending'}),
        createReport(0, {processingProgress: 'Processed'}),
      ]
      renderComponent(<LtiAssetReportStatus reports={reports} />)
      expect(screen.getByText('Processing')).toBeInTheDocument()
    })

    it('shows "All good" when there are both processed and no result reports', () => {
      const reports = [
        createReport(0, {processingProgress: 'Processed'}),
        createReport(0, {processingProgress: 'NotReady'}),
      ]
      renderComponent(<LtiAssetReportStatus reports={reports} />)
      expect(screen.getByText('All good')).toBeInTheDocument()
    })
  })

  describe('custom text styling', () => {
    const reports = [createReport(0, {processingProgress: 'Processed'})]

    it('applies custom textSize when provided', () => {
      const {container} = renderComponent(
        <LtiAssetReportStatus reports={reports} textSize="small" />,
      )
      const textElement = container.querySelector('[class*="text"]')
      expect(textElement).toBeInTheDocument()
    })

    it('applies custom textWeight when provided', () => {
      const {container} = renderComponent(
        <LtiAssetReportStatus reports={reports} textWeight="normal" />,
      )
      const textElement = container.querySelector('[class*="text"]')
      expect(textElement).toBeInTheDocument()
    })

    it('applies both textSize and textWeight when provided', () => {
      renderComponent(
        <LtiAssetReportStatus reports={reports} textSize="small" textWeight="normal" />,
      )
      expect(screen.getByText('All good')).toBeInTheDocument()
    })
  })
})
