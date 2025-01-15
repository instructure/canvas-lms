/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import FilePreviewInfoPanel from '../FilePreviewInfoPanel'
import File from '../../../backbone/models/File'

describe('FilePreviewInfoPanel', () => {
  let file
  let defaultProps

  beforeEach(() => {
    file = new File({
      'content-type': 'text/plain',
      size: '1232',
      updated_at: new Date(1431724289),
      user: {
        html_url: 'http://fun.com',
        display_name: 'Jim Bob',
      },
      created_at: new Date(1431724289),
      name: 'some file',
      usage_rights: {
        legal_copyright: 'copycat',
        license_name: 'best license ever',
      },
    })

    defaultProps = {
      displayedItem: file,
      usageRightsRequiredForContext: true,
    }
  })

  const renderComponent = (props = {}) => {
    return render(<FilePreviewInfoPanel {...defaultProps} {...props} />)
  }

  it('displays item name', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('display-name')).toHaveTextContent('some file')
  })

  it('displays status', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('status')).toHaveTextContent('Published')
  })

  it('displays content type', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('content-type')).toHaveTextContent('Plain text')
  })

  it('displays size', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('size')).toHaveTextContent('1 KB')
  })

  it('displays date modified', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('date-modified')).toHaveTextContent('Jan 17, 1970')
  })

  it('displays date created', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('date-created')).toHaveTextContent('Jan 17, 1970')
  })

  it('displays modified by name with link', () => {
    const {getByTestId} = renderComponent()
    const modifiedByElement = getByTestId('modified-by')
    const link = modifiedByElement.querySelector('a')
    expect(link).toHaveAttribute('href', 'http://fun.com')
    expect(modifiedByElement).toHaveTextContent('Jim Bob')
  })

  it('displays license name', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('license-name')).toHaveTextContent('best license ever')
  })

  it('displays legal copyright', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('legal-copyright')).toHaveTextContent('copycat')
  })
})
