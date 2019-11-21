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
import {render} from '@testing-library/react'
import React from 'react'

import ClosedCaptionHeader from '../ClosedCaptionHeader'

function makeProps() {
  return {
    CLOSED_CAPTIONS_LANGUAGE_HEADER: 'language',
    CLOSED_CAPTIONS_FILE_NAME_HEADER: 'file name',
    CLOSED_CAPTIONS_ACTIONS_HEADER: 'actions header'
  }
}

describe('ClosedCaptionHeader', () => {
  it('renders normally', () => {
    const {getByText} = render(<ClosedCaptionHeader {...makeProps()} />)
    expect(getByText('language')).toBeInTheDocument()
    expect(getByText('file name')).toBeInTheDocument()
    expect(getByText('actions header')).toBeInTheDocument()
  })
})
