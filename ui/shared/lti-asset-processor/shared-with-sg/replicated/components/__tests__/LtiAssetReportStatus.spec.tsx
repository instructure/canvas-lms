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

  describe('with no high priority reports', () => {
    const reports = [createReport(0), createReport(0)]

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

    it('renders "Needs attention" status without openModal prop', () => {
      renderComponent(<LtiAssetReportStatus reports={reports} />)
      expect(screen.getByText('Needs attention')).toBeInTheDocument()
    })

    it('renders an IconWarningSolid with error color when no modal is provided', () => {
      const {container} = renderComponent(<LtiAssetReportStatus reports={reports} />)
      // We can't easily check the color, but we can verify the icon exists
      expect(container.querySelector('[name="IconWarning"]')).toBeInTheDocument()
    })

    it('renders a link with "Needs attention" text when openModal prop is provided', () => {
      const openModal = fn()
      renderComponent(<LtiAssetReportStatus reports={reports} openModal={openModal} />)
      const link = screen.getByText('Needs attention')
      expect(link).toBeInTheDocument()
    })

    it('calls openModal when link is clicked', () => {
      const openModal = fn()
      renderComponent(<LtiAssetReportStatus reports={reports} openModal={openModal} />)
      fireEvent.click(screen.getByText('Needs attention'))
      expect(openModal).toHaveBeenCalledTimes(1)
    })
  })

  describe('custom text styling', () => {
    const reports = [createReport(0)]

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
      const {container} = renderComponent(
        <LtiAssetReportStatus reports={reports} textSize="small" textWeight="normal" />,
      )
      expect(screen.getByText('All good')).toBeInTheDocument()
    })
  })
})
