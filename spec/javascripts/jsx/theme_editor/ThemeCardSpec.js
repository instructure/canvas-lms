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

define([
  'react',
  'react-dom',
  'jsx/theme_editor/ThemeCard'
], (React, ReactDOM, ThemeCard) => {

  let elem, props

  QUnit.module('ThemeCard Component', {
    setup () {
      elem = document.createElement('div')
      props = {
        name: 'Theme Name',
        isActiveBrandConfig: false,
        isDeleteable: true,
        isBeingDeleted: false,
        startDeleting: sinon.stub(),
        cancelDelete: sinon.stub(),
        onDelete: sinon.stub(),
        getVariable: sinon.stub()
      }
    }
  })

  test('Renders the name', () => {
    const component = ReactDOM.render(<ThemeCard {...props} />, elem)
    const node = component.getDOMNode()
    const button = node.querySelector('.ic-ThemeCard-name-button')
    button.removeChild(button.querySelector('.screenreader-only'))
    equal(button.textContent, props.name, 'renders the name')
  })

  test('Renders preview of colors', () => {
    const component = ReactDOM.render(<ThemeCard {...props} />, elem)
    const getVar = props.getVariable
    ok(getVar.calledWith('ic-brand-primary'), 'prview ic-brand-primary')
    ok(getVar.calledWith('ic-brand-button--primary-bgd'), 'prview ic-brand-button--primary-bgd')
    ok(getVar.calledWith('ic-brand-button--secondary-bgd'), 'prview ic-brand-button--secondary-bgd')
    ok(getVar.calledWith('ic-brand-global-nav-bgd'), 'prview ic-brand-global-nav-bgd')
    ok(getVar.calledWith('ic-brand-global-nav-ic-icon-svg-fill'), 'prview ic-brand-global-nav-ic-icon-svg-fill')
    ok(getVar.calledWith('ic-brand-global-nav-menu-item__text-color'), 'prview ic-brand-nav-menu-item__text-color')
  })

  test('Incicates if it is the current theme', () => {
    let component = ReactDOM.render(<ThemeCard {...props} />, elem)
    equal(
      component.getDOMNode().querySelector('.ic-ThemeCard-status__text'),
      null,
      'status text elment not found when isActiveBrandConfig is false'
    )

    props.isActiveBrandConfig = true
    component = ReactDOM.render(<ThemeCard {...props} />, elem)
    equal(
      component.getDOMNode().querySelector('.ic-ThemeCard-status__text').textContent,
      'Current theme',
      '"Current theme" status text found when isActiveBrandConfig is true'
    )
  })

  test('Shows delete overlay if isBeingDeleted is true', () => {
    let component = ReactDOM.render(<ThemeCard {...props} />, elem)
    equal(
      component.getDOMNode().querySelector('.ic-ThemeCard-overlay__heading'),
      null,
      'does not show delete overlay heading'
    )

    props.isBeingDeleted = true
    component = ReactDOM.render(<ThemeCard {...props} />, elem)
    equal(
      component.getDOMNode().querySelector('.ic-ThemeCard-overlay__heading').textContent,
      'Delete this theme?',
      'shows delete overlay heading'
    )
  })
})

