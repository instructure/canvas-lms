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
import ThemeCard from 'ui/features/brand_configs/react/ThemeCard'
import {shallow} from 'enzyme'

let props

QUnit.module('ThemeCard Component', {
  setup() {
    props = {
      name: 'Test Theme',
      isActiveBrandConfig: false,
      isDeleteable: true,
      isBeingDeleted: false,
      open: sinon.stub(),
      startDeleting: sinon.stub(),
      cancelDelete: sinon.stub(),
      onDelete: sinon.stub(),
      getVariable: sinon.stub(),
    }
  },
})

test('Renders the name', () => {
  const wrapper = shallow(<ThemeCard {...props} />)
  equal(
    wrapper.find('.ic-ThemeCard-name-button').text(),
    `Edit this theme in Theme Editor${props.name}`,
    'renders the name'
  )
})

test('Renders preview of colors', () => {
  shallow(<ThemeCard {...props} />)
  const getVar = props.getVariable
  ok(getVar.calledWith('ic-brand-primary'), 'prview ic-brand-primary')
  ok(getVar.calledWith('ic-brand-button--primary-bgd'), 'prview ic-brand-button--primary-bgd')
  ok(getVar.calledWith('ic-brand-button--secondary-bgd'), 'prview ic-brand-button--secondary-bgd')
  ok(getVar.calledWith('ic-brand-global-nav-bgd'), 'prview ic-brand-global-nav-bgd')
  ok(
    getVar.calledWith('ic-brand-global-nav-ic-icon-svg-fill'),
    'prview ic-brand-global-nav-ic-icon-svg-fill'
  )
  ok(
    getVar.calledWith('ic-brand-global-nav-menu-item__text-color'),
    'prview ic-brand-nav-menu-item__text-color'
  )
})

test('Indicates if it is the current theme', () => {
  let wrapper = shallow(<ThemeCard {...props} />)
  notOk(
    wrapper.find('.ic-ThemeCard-status__text').exists(),
    'status text elment not found when isActiveBrandConfig is false'
  )

  props.isActiveBrandConfig = true
  wrapper = shallow(<ThemeCard {...props} />)
  equal(
    wrapper.find('.ic-ThemeCard-status__text').text(),
    'Current theme',
    '"Current theme" status text found when isActiveBrandConfig is true'
  )
})

test('Shows delete modal if isBeingDeleted is true', () => {
  let wrapper = shallow(<ThemeCard {...props} />)
  notOk(wrapper.find('ModalBody').exists())

  props.isBeingDeleted = true
  wrapper = shallow(<ThemeCard {...props} />)
  equal(wrapper.find('ModalBody').prop('children'), 'Delete Test Theme?')
})

test('Shows tooltip if there are multiple cards of the same theme', () => {
  const wrapperWithoutDuplicates = shallow(<ThemeCard {...props} />)
  notOk(wrapperWithoutDuplicates.find('.Button--icon-active-rev').exists())

  props.showMultipleCurrentThemesMessage = true
  props.isActiveBrandConfig = true
  const wrapper = shallow(<ThemeCard {...props} />)
  ok(wrapper.find('.Button--icon-action-rev[data-tooltip][title]').exists())
})
