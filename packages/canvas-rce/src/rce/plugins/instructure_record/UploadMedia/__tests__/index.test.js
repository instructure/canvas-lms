/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import {UploadMedia} from '../index'
import EmbedPanel from '../EmbedPanel'

describe('UploadMedia', () => {
  it('calls onDismiss prop when closing', () => {
    const handleDismiss = jest.fn()
    const {getAllByText} = render(<UploadMedia editor={{}} onDismiss={handleDismiss} />)

    const closeBtn = getAllByText('Close')[0]
    fireEvent.click(closeBtn)
    expect(handleDismiss).toHaveBeenCalled()
  })

  it('calls setEmbedCode when the embeded code textArea changes', () => {
    const fakeSetEmbedCode = jest.fn()
    const {getByLabelText} = render(<EmbedPanel embedCode="" setEmbedCode={fakeSetEmbedCode} />)
    fireEvent.change(getByLabelText('Embed Video Code'), {target: {value: 'instructure.com'}})
    expect(fakeSetEmbedCode).toHaveBeenCalledWith('instructure.com')
  })
})
