/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {AttachmentDisplay} from '../AttachmentDisplay'
import {responsiveQuerySizes} from '../../../utils'

jest.mock('../../../utils')

beforeAll(() => {
  window.matchMedia = jest.fn().mockImplementation(() => {
    return {
      matches: ['mobile'],
      media: '',
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
    }
  })
})

const setup = props => {
  return render(
    <AttachmentDisplay
      setAttachment={() => {}}
      setAttachmentToUpload={() => {}}
      responsiveQuerySizes={responsiveQuerySizes}
      {...props}
    />
  )
}

describe('RemovableItem', () => {
  describe('mobile', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        mobile: {maxWidth: '767px'},
      }))
    })

    it('AttachmentButton renders the close button', () => {
      const {queryByTestId} = setup({
        attachment: {
          _id: 1,
          displayName: 'file_name.file',
          url: 'file_download_example.com',
        },
      })

      expect(queryByTestId('remove-button')).toBeTruthy()
    })
  })
})
