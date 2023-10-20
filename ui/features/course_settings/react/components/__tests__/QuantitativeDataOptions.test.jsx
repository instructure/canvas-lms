/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import QuantitativeDataOptions from '../QuantitativeDataOptions'

function createFormField(wrapper, id, value) {
  const field = document.createElement('input')
  field.setAttribute('type', 'hidden')
  field.setAttribute('id', id)
  field.setAttribute('name', id)
  field.setAttribute('value', value)
  wrapper.appendChild(field)
}

function setupWindowEnv() {
  window.ENV.STUDENTS_ENROLLMENT_DATES = {
    start_at: '2021-02-10T00:00:00-07:00',
    end_at: '2021-07-10T00:00:00-07:00',
  }
  window.ENV.TIMEZONE = 'America/Halifax'
  window.ENV.CONTEXT_TIMEZONE = 'America/Denver'
}

function renderComponent(wrapper, overrides = {}) {
  const options = {
    canManage: true,
    ...overrides,
  }

  createFormField(
    wrapper,
    'course_restrict_quantitative_data',
    options.course_restrict_quantitative_data
  )

  return render(<QuantitativeDataOptions {...options} />, wrapper)
}

describe('QuantitativeDataOptions', () => {
  let wrapper
  setupWindowEnv()
  beforeEach(() => {
    wrapper = document.createElement('div')
    document.body.appendChild(wrapper)
  })

  afterEach(() => {
    document.body.removeChild(wrapper)
  })

  describe('can manage', () => {
    it('renders restrict quantitative data checkbox', () => {
      const {getByLabelText} = renderComponent(wrapper)
      expect(getByLabelText('Restrict view of quantitative data')).toBeInTheDocument()
    })

    it('restrict quantitative data checkbox is disabled when can manage is false', () => {
      const {getByLabelText, getByTestId} = renderComponent(wrapper, {
        canManage: false,
      })
      expect(getByLabelText('Restrict view of quantitative data')).toBeInTheDocument()
      expect(getByTestId('restrict-quantitative-data-checkbox')).toHaveAttribute('disabled')
    })
  })
})
