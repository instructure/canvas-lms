/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import ReactDOM from 'react-dom'
import AnonymousSpeedGraderAlert from 'ui/features/gradebook/react/default_gradebook/components/AnonymousSpeedGraderAlert'
import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'

const $fixtures = document.getElementById('fixtures')

QUnit.module('Gradebook#renderAnonymousSpeedGraderAlert', hooks => {
  let gradebook
  const onClose = () => {}
  const alertProps = {
    speedGraderUrl: 'http://test.url:3000',
    onClose,
  }

  function anonymousSpeedGraderAlertProps() {
    return ReactDOM.render.firstCall.args[0].props
  }

  hooks.beforeEach(() => {
    sinon.stub(ReactDOM, 'render')
  })

  hooks.afterEach(() => {
    ReactDOM.render.restore()
  })

  test('renders the AnonymousSpeedGraderAlert component', () => {
    gradebook = createGradebook()
    gradebook.renderAnonymousSpeedGraderAlert(alertProps)
    const componentName = ReactDOM.render.firstCall.args[0].type.name
    strictEqual(componentName, 'AnonymousSpeedGraderAlert')
  })

  test('passes speedGraderUrl to the modal as a prop', () => {
    gradebook = createGradebook()
    gradebook.renderAnonymousSpeedGraderAlert(alertProps)
    strictEqual(anonymousSpeedGraderAlertProps().speedGraderUrl, 'http://test.url:3000')
  })

  test('passes onClose to the modal as a prop', () => {
    gradebook = createGradebook()

    gradebook.renderAnonymousSpeedGraderAlert(alertProps)
    strictEqual(anonymousSpeedGraderAlertProps().onClose, onClose)
  })
})

QUnit.module('Gradebook#showAnonymousSpeedGraderAlertForURL', hooks => {
  let gradebook

  function anonymousSpeedGraderAlertProps() {
    return gradebook.renderAnonymousSpeedGraderAlert.firstCall.args[0]
  }

  hooks.beforeEach(() => {
    setFixtureHtml($fixtures)
  })

  hooks.afterEach(() => {
    $fixtures.innerHTML = ''
  })

  test('renders the alert with the supplied speedGraderURL', () => {
    gradebook = createGradebook()
    sinon.stub(AnonymousSpeedGraderAlert.prototype, 'open')
    sinon.spy(gradebook, 'renderAnonymousSpeedGraderAlert')
    gradebook.showAnonymousSpeedGraderAlertForURL('http://test.url:3000')

    strictEqual(anonymousSpeedGraderAlertProps().speedGraderUrl, 'http://test.url:3000')
    gradebook.renderAnonymousSpeedGraderAlert.restore()
    AnonymousSpeedGraderAlert.prototype.open.restore()
  })
})
