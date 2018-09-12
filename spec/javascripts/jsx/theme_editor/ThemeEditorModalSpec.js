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

import React from 'react';
import {shallow} from 'enzyme'
import ThemeEditorModal from 'jsx/theme_editor/ThemeEditorModal';

const defaultProps = {
  showProgressModal: false,
  showSubAccountProgress: false,
  progress: 0.5,
  activeSubAccountProgresses: []
}

QUnit.module('ThemeEditorModal Component')

test('modalOpen', () => {
  notOk(shallow(<ThemeEditorModal {...defaultProps} />).prop('open'), 'modal is closed')

  ok(shallow(<ThemeEditorModal {...defaultProps} showProgressModal />).prop('open'), 'modal is open')
  ok(shallow(<ThemeEditorModal {...defaultProps} showSubAccountProgress />).prop('open'), 'modal is open')
})

test('modalContent', () => {
  let wrapper = shallow(<ThemeEditorModal {...defaultProps} showProgressModal />)
  equal(wrapper.find('ProgressBar').prop('title'), '1% complete')

  wrapper = shallow(<ThemeEditorModal {...defaultProps} showSubAccountProgress />)
  equal(wrapper.find('p').text(), 'Changes will still apply if you leave this page.')
})
