/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import React from 'react'
import {render} from '@testing-library/react'
import UploadProgress from '../UploadProgress'
import FileUploader from '../../modules/FileUploader'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

function makeUploader(name) {
  const uploader = new FileUploader({file: new File(['foo'], name, {type: 'text/plain'})})
  return uploader
}

function makeFlashAlertMessage(str) {
  return {message: str, err: null, type: 'info', srOnly: true}
}

describe('UploadProgress', () => {
  it('getLabel displays file name', function() {
    const {getByText} = render(<UploadProgress uploader={makeUploader('foo.txt')} />)
    expect(getByText('foo.txt')).toBeInTheDocument()
  })

  it('announces upload progress to screen reader when queue changes', function() {
    const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
    const uploader = makeUploader('foo.txt')
    const {container, rerender} = render(<UploadProgress uploader={uploader} />)

    uploader.trackProgress({loaded: 35, total: 100})
    rerender(<UploadProgress uploader={uploader} />)
    expect(container.querySelector('[aria-valuenow="35"]')).toBeInTheDocument()

    expect(showFlashAlertSpy).toHaveBeenLastCalledWith(
      makeFlashAlertMessage('foo.txt - 35 percent uploaded')
    )

    // File upload 75% complete
    uploader.trackProgress({loaded: 75, total: 100})
    rerender(<UploadProgress uploader={uploader} />)
    expect(container.querySelector('[aria-valuenow="75"]')).toBeInTheDocument()
    expect(showFlashAlertSpy).toHaveBeenLastCalledWith(
      makeFlashAlertMessage('foo.txt - 75 percent uploaded')
    )

    // File upload complete
    uploader.trackProgress({loaded: 100, total: 100})
    rerender(<UploadProgress uploader={uploader} />)
    expect(container.querySelector('[aria-valuenow="100"]')).toBeInTheDocument()
    expect(showFlashAlertSpy).toHaveBeenLastCalledWith(
      makeFlashAlertMessage('foo.txt uploaded successfully!')
    )
  })

  it('does not announce upload progress to screen reader if progress has not changed', function() {
    const showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
    const uploader = makeUploader('foo.txt')

    const {rerender} = render(<UploadProgress uploader={uploader} />)

    uploader.trackProgress({loaded: 35, total: 100})
    rerender(<UploadProgress uploader={uploader} />)

    uploader.trackProgress({loaded: 35, total: 100})
    rerender(<UploadProgress uploader={uploader} />)

    expect(showFlashAlertSpy).toHaveBeenCalledTimes(1)
  })
})
