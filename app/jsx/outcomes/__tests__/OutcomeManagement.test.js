/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {mount, shallow} from 'enzyme'
import OutcomeManagement, {OutcomePanel} from '../OutcomeManagement'

describe('OutcomeManagement', () => {
  const sharedExamples = () => {
    it('renders the OutcomeManagement and shows the "outcomes" div', () => {
      const wrapper = shallow(<OutcomeManagement />)
      expect(wrapper.find('OutcomePanel').exists()).toBe(true)
    })
  }

  describe('account', () => {
    beforeEach(() => {
      window.ENV = {
        context_asset_string: 'account_1'
      }
    })

    afterEach(() => {
      window.ENV = null
    })

    sharedExamples()

    it('passes accountId to the ProficiencyTable component', () => {
      const wrapper = shallow(<OutcomeManagement />)
      expect(wrapper.find('MasteryScale').prop('contextType')).toBe('Account')
      expect(wrapper.find('MasteryScale').prop('contextId')).toBe('1')
    })
  })

  describe('course', () => {
    beforeEach(() => {
      window.ENV = {
        context_asset_string: 'course_2'
      }
    })

    afterEach(() => {
      window.ENV = null
    })

    sharedExamples()

    it('passes courseId to the ProficiencyTable component', () => {
      const wrapper = shallow(<OutcomeManagement />)
      expect(wrapper.find('MasteryScale').prop('contextType')).toBe('Course')
      expect(wrapper.find('MasteryScale').prop('contextId')).toBe('2')
    })
  })
})

describe('OutcomePanel', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="outcomes" style="display:none">Outcomes Tab</div>'
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('sets style on mount', () => {
    mount(<OutcomePanel />)
    expect(document.getElementById('outcomes').style.display).toBe('block')
  })

  it('sets style on unmount', () => {
    const wrapper = mount(<OutcomePanel />)
    wrapper.unmount()
    expect(document.getElementById('outcomes').style.display).toBe('none')
  })
})
