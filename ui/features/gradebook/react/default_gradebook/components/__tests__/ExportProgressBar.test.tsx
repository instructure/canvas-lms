/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import $ from 'jquery'
import React from 'react'
import {ExportProgressBar, type ExportProgressBarProps} from '../ExportProgressBar'
import {render, fireEvent} from '@testing-library/react'
import GradebookExportManager from '../../../shared/GradebookExportManager'

jest.mock('../../../shared/GradebookExportManager')

describe('ExportProgressBar', () => {
  const defaultParams: ExportProgressBarProps = {
    exportState: {
      filename: 'test-download',
      completion: 10,
    },
  }

  it('renders with valid completion & filename', () => {
    const {getByText, getByTestId} = render(<ExportProgressBar {...defaultParams} />)
    const progressBarElem = getByTestId('export-progress-bar')
    expect(progressBarElem).toBeInTheDocument()
    expect(getByText('Exporting test-download')).toBeInTheDocument()
    expect(getByText('10%')).toBeInTheDocument()
  })

  it('sets div to not visible if completion is undefined', () => {
    const params = {
      exportState: {
        filename: 'test-download',
        completion: undefined,
      },
    }
    const {getByTestId} = render(<ExportProgressBar {...params} />)
    const progressBarElem = getByTestId('export-progress-bar')
    expect(progressBarElem).toBeInTheDocument()
    expect(progressBarElem).toHaveAttribute('aria-hidden', 'true')
  })

  it('sets cancelled button to disabled when completion is at 100', () => {
    const {getByText, container} = render(
      <ExportProgressBar
        exportState={{
          filename: 'test-download-complete',
          completion: 100,
        }}
      />
    )
    expect(getByText('Exporting test-download-complete')).toBeInTheDocument()
    expect(getByText('100%')).toBeInTheDocument()
    expect(container.getElementsByTagName('button')[0].hasAttribute('disabled')).toEqual(true)
  })

  it('handles cancel export on click', () => {
    $.flashWarning = jest.fn()
    const exportManager: GradebookExportManager = new GradebookExportManager('', '', '')
    const params = {...defaultParams, exportManager}
    const {container} = render(<ExportProgressBar {...params} />)
    fireEvent.click(container.getElementsByTagName('button')[0])
    expect(exportManager.cancelExport).toHaveBeenCalledTimes(1)
    expect($.flashWarning).toHaveBeenCalledWith('Your gradebook export has been cancelled')
  })
})
