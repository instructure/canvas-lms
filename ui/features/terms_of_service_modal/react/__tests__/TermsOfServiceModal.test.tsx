/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import $ from 'jquery'
import {render, screen} from '@testing-library/react'
import TermsOfServiceModal from '../TermsOfServiceModal'
import fakeENV from '@canvas/test-utils/fakeENV'

interface TermsOfServiceModalProps {
  preview?: boolean
}

const renderTermsOfServiceModal = (props: TermsOfServiceModalProps = {}) =>
  render(<TermsOfServiceModal {...props} />)

describe('TermsOfServiceModal', () => {
  beforeEach(() => {
    fakeENV.setup({
      TERMS_OF_SERVICE_CUSTOM_CONTENT: 'Hello World',
    })
    $('#fixtures').html('<div id="main">')
  })

  afterEach(() => {
    $('#fixtures').empty()
    fakeENV.teardown()
  })

  it('renders correct link when preview is provided', () => {
    renderTermsOfServiceModal({preview: true})

    expect(screen.getByText('Preview')).toBeInTheDocument()
  })

  it('renders correct link when preview is not provided', () => {
    renderTermsOfServiceModal()

    expect(screen.getByText('Acceptable Use Policy')).toBeInTheDocument()
  })
})
