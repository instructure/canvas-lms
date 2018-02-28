/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import { shallow } from 'enzyme'
import { merge } from 'lodash'
import OutcomesImporter from '../OutcomesImporter'

const defaultProps = (props = {}) => (
  merge({
    mount: null,
    disableOutcomeViews: () => {},
    resetOutcomeViews: () => {},
    file: {}
  }, props)
)

it('renders the OutcomesImporter component', () => {
  const modal = shallow(<OutcomesImporter {...defaultProps}/>)
  expect(modal.exists()).toBe(true)
})

it('disables the Outcome Views when upload starts', () => {
  const disableOutcomeViews = jest.fn()
  const modal = shallow(<OutcomesImporter {...defaultProps({ disableOutcomeViews })}/>)
  modal.instance().beginUpload()
  expect(disableOutcomeViews).toBeCalled()
})

it('resets the Outcome Views when upload is complete', () => {
  const resetOutcomeViews = jest.fn()
  const modal = shallow(<OutcomesImporter {...defaultProps({ resetOutcomeViews })}/>)
  modal.instance().completeUpload()
  expect(resetOutcomeViews).toBeCalled()
})