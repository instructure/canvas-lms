/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {mount} from 'enzyme'
import GradebookMenu from 'jsx/gradebook/default_gradebook/components/GradebookMenu'

QUnit.module('GradebookMenu', {
  setup() {
    this.wrapper = mount(
      <GradebookMenu
        variant="DefaultGradebook"
        learningMasteryEnabled
        courseUrl="http://someUrl/"
      />
    )
  },

  teardown() {
    this.wrapper.unmount()
  }
})

test('Gradebook trigger button is present', function() {
  equal(
    this.wrapper
      .find('Button')
      .text()
      .trim(),
    'Gradebook'
  )
})

test('#handleIndividualGradebookSelect calls setLocation', function() {
  const setLocationStub = sandbox.stub(GradebookMenu.prototype, 'setLocation')
  this.wrapper.find('button').simulate('click')
  document.querySelector('[data-menu-item-id="individual-gradebook"]').click()
  const url = `${
    this.wrapper.props().courseUrl
  }/gradebook/change_gradebook_version?version=individual`
  ok(setLocationStub.withArgs(url).calledOnce)
})

test('#handleGradebookHistorySelect calls setLocation', function() {
  const setLocationStub = sandbox.stub(GradebookMenu.prototype, 'setLocation')
  this.wrapper.find('button').simulate('click')
  document.querySelector('[data-menu-item-id="gradebook-history"]').click()
  const url = `${this.wrapper.props().courseUrl}/gradebook/history`
  ok(setLocationStub.withArgs(url).calledOnce)
})

QUnit.module('Variant DefaultGradebook with Learning Mastery Enabled', {
  setup() {
    this.wrapper = mount(
      <GradebookMenu
        variant="DefaultGradebook"
        learningMasteryEnabled
        courseUrl="http://someUrl/"
      />
    )
    this.wrapper.find('button').simulate('click')
    this.menuItems = $('[role="menu"]:contains("Learning Mastery…")')[0].children
  },
  teardown() {
    this.wrapper.unmount()
  }
})

test('handleDefaultGradbookLearningMasterySelect calls setLocation', function() {
  const setLocationStub = sandbox.stub(GradebookMenu.prototype, 'setLocation')
  document.querySelector('[data-menu-item-id="learning-mastery"]').click()
  const url = `${this.wrapper.props().courseUrl}/gradebook?view=learning_mastery`
  ok(setLocationStub.withArgs(url).calledOnce)
})

test('Learning Mastery Menu Item is first in the Menu', function() {
  equal(this.menuItems[0].textContent.trim(), 'Learning Mastery…')
})

test('Individual Gradebook Menu Item is second in the Menu', function() {
  equal(this.menuItems[1].textContent.trim(), 'Individual View…')
})

test('Menu Item Separator is third in the Menu', function() {
  equal(this.menuItems[2].firstElementChild.getAttribute('role'), 'presentation')
})

test('Gradebook History Menu Item is fourth in the Menu', function() {
  equal(this.menuItems[3].textContent.trim(), 'Gradebook History…')
})

QUnit.module('Variant DefaultGradebook with Learning Mastery Disabled', {
  setup() {
    this.wrapper = mount(
      <GradebookMenu
        variant="DefaultGradebook"
        learningMasteryEnabled={false}
        courseUrl="http://someUrl/"
      />
    )
    this.wrapper.find('button').simulate('click')
    this.menuItems = $('[role="menu"]:contains("Individual View…")')[0].children
  },
  teardown() {
    this.wrapper.unmount()
  }
})

test('Individual Gradebook Menu Item is first in the Menu', function() {
  equal(this.menuItems[0].textContent.trim(), 'Individual View…')
})

test('Menu Item Separator is second in the Menu', function() {
  equal(this.menuItems[1].firstElementChild.getAttribute('role'), 'presentation')
})

test('Gradebook History Menu Item is second in the Menu', function() {
  equal(this.menuItems[2].textContent.trim(), 'Gradebook History…')
})

QUnit.module('Variant DefaultGradebookLearningMastery with Learning Mastery Enabled', {
  setup() {
    this.wrapper = mount(
      <GradebookMenu
        variant="DefaultGradebookLearningMastery"
        learningMasteryEnabled
        courseUrl="http://someUrl/"
      />
    )
    this.wrapper.find('button').simulate('click')
    this.menuItems = $('[role="menu"]:contains("Gradebook…")')[0].children
  },
  teardown() {
    this.wrapper.unmount()
  }
})

test('handleDefaultGradbookSelect calls setLocation', function() {
  const setLocationStub = sandbox.stub(GradebookMenu.prototype, 'setLocation')
  document.querySelector('[data-menu-item-id="default-gradebook"]').click()
  const url = `${this.wrapper.props().courseUrl}/gradebook?view=gradebook`
  ok(setLocationStub.withArgs(url).calledOnce)
})

test('Learning Mastery trigger button is present', function() {
  equal(
    this.wrapper
      .find('Button')
      .text()
      .trim(),
    'Learning Mastery'
  )
})

test('DefaultGradebook Menu Item is first in the Menu', function() {
  equal(this.menuItems[0].textContent.trim(), 'Gradebook…')
})

test('Individual Gradebook Menu Item is second in the Menu', function() {
  equal(this.menuItems[1].textContent.trim(), 'Individual View…')
})

test('Menu Item Separator is third in the Menu', function() {
  equal(this.menuItems[2].firstElementChild.getAttribute('role'), 'presentation')
})

test('Gradebook History Menu Item is fourth in the Menu', function() {
  equal(this.menuItems[3].textContent.trim(), 'Gradebook History…')
})
