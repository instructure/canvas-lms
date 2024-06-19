/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {shallow} from 'enzyme'
import ThemeEditorModal from '../ThemeEditorModal'

describe('ThemeEditorModal Component', () => {
  const defaultProps = {
    showProgressModal: false,
    showSubAccountProgress: false,
    progress: 0.5,
    activeSubAccountProgresses: [],
  }

  test('modalOpen', () => {
    // Test when modal is closed
    expect(shallow(<ThemeEditorModal {...defaultProps} />).prop('open')).toBeFalsy()

    // Test when modal is open due to `showProgressModal`
    expect(
      shallow(<ThemeEditorModal {...defaultProps} showProgressModal />).prop('open')
    ).toBeTruthy()

    // Test when modal is open due to `showSubAccountProgress`
    expect(
      shallow(<ThemeEditorModal {...defaultProps} showSubAccountProgress />).prop('open')
    ).toBeTruthy()
  })

  test('modalContent', () => {
    // Test for ProgressBar when `showProgressModal` is true
    let wrapper = shallow(<ThemeEditorModal {...defaultProps} showProgressModal />)
    expect(wrapper.find('ProgressBar').prop('title')).toBe('1% complete')

    // Test for text content when `showSubAccountProgress` is true
    wrapper = shallow(<ThemeEditorModal {...defaultProps} showSubAccountProgress />)
    expect(wrapper.find('p').text()).toBe('Changes will still apply if you leave this page.')
  })
})
