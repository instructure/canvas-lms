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
import ReactDOM from 'react-dom'
import {shallow} from 'enzyme'
import jQuery from 'jquery'
import SaveThemeButton from 'jsx/theme_editor/SaveThemeButton'
import 'jquery.ajaxJSON'

let elem, props

const isType = type => child => child.type === type

QUnit.module('SaveThemeButton Component', {
  setup() {
    elem = document.createElement('div')
    props = {
      accountID: 'account123',
      brandConfigMd5: '00112233445566778899aabbccddeeff',
      sharedBrandConfigBeingEdited: {
        id: 321,
        account_id: 123,
        brand_config: {
          md5: '00112233445566778899aabbccddeeff',
          variables: {
            'some-var': '#123'
          }
        }
      },
      onSave: sinon.stub()
    }
  }
})

test('save', function(assert) {
  const done = assert.async()
  let component = ReactDOM.render(<SaveThemeButton {...props} />, elem)
  const updatedBrandConfig = {}
  sandbox.stub(jQuery, 'ajaxJSON').callsArgOnWith(3, component, updatedBrandConfig)
  sandbox.spy(component, 'setState')
  component.save()
  ok(
    jQuery.ajaxJSON.calledWithMatch(props.accountID, 'PUT'),
    'makes a put request with the correct account id'
  )
  ok(component.setState.calledWithMatch({modalIsOpen: false}), 'closes modal')
  ok(props.onSave.calledWith(updatedBrandConfig), 'calls onSave with updated config')

  delete props.sharedBrandConfigBeingEdited
  component = ReactDOM.render(<SaveThemeButton {...props} />, elem)
  jQuery.ajaxJSON.reset()
  component.save()
  ok(component.setState.calledWithMatch({modalIsOpen: true}), 'opens modal')
  notOk(jQuery.ajaxJSON.called, 'does not make a request')

  component.setState({newThemeName: 'theme name'}, () => {
    component.save()
    ok(
      jQuery.ajaxJSON.calledWithMatch(props.accountID, 'POST'),
      'makes a post request with the correct account id'
    )
    ReactDOM.unmountComponentAtNode(elem)
    done()
  })
})

test('modal visibility', function() {
  const wrapper = shallow(<SaveThemeButton {...props} />)

  let modal = wrapper.find('CanvasInstUIModal')
  ok(modal.exists(), 'renders a modal')
  notOk(modal.props().open, 'modal is closed')

  wrapper.setState({
    modalIsOpen: true
  })

  modal = wrapper.find('CanvasInstUIModal')
  ok(modal.props().open, 'modal is open')
  wrapper.unmount()
})

test('disabling button', () => {
  const wrapper = shallow(<SaveThemeButton {...props} />)
  notOk(
    wrapper
      .find('.Button--primary')
      .first()
      .prop('disabled'),
    'not disabled by default'
  )
  wrapper.unmount()
})

test('disabling button: disabled if userNeedsToPreviewFirst', () => {
  const wrapper = shallow(<SaveThemeButton {...props} userNeedsToPreviewFirst />)
  ok(
    wrapper
      .find('.Button--primary')
      .first()
      .prop('disabled')
  )
  wrapper.unmount()
})

test('disabling button: disabled if there are no unsaved changes', () => {
  const wrapper = shallow(
    <SaveThemeButton
      {...props}
      brandConfigMd5={props.sharedBrandConfigBeingEdited.brand_config_md5}
    />
  )
  ok(
    wrapper
      .find('.Button--primary')
      .first()
      .prop('disabled')
  )
  wrapper.unmount()
})

test('disabling button: disabled if everything is default', () => {
  const wrapper = shallow(<SaveThemeButton {...props} brandConfigMd5={null} />)
  ok(
    wrapper
      .find('.Button--primary')
      .first()
      .prop('disabled')
  )
  wrapper.unmount()
})
