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
import {fireEvent, render} from '@testing-library/react'

import GradebookSelector from 'jsx/gradezilla/individual-gradebook/components/GradebookSelector'

QUnit.module('Gradezilla > Individual Gradebook > Components > GradebookSelector', suiteHooks => {
  let $container
  let $tabsContainer
  let component
  let props
  let tabsComponent
  let tabsProps

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    $tabsContainer = document.body.appendChild(document.createElement('div'))

    props = {
      courseUrl: 'https://localhost/courses/1201',
      learningMasteryEnabled: false,
      navigate: sinon.stub()
    }

    tabsProps = {
      onTab1Click: sinon.stub(),
      onTab2Click: sinon.stub()
    }

    component = null
    tabsComponent = null
  })

  suiteHooks.afterEach(() => {
    component.unmount()
    $container.remove()

    if (tabsComponent) {
      tabsComponent.unmount()
    }
    $tabsContainer.remove()
  })

  function renderComponent() {
    component = render(<GradebookSelector {...props} />, {container: $container})

    if (props.learningMasteryEnabled) {
      tabsComponent = render(
        <ic-tabs>
          <ic-tab onClick={tabsProps.onTab1Click} />
          <ic-tab onClick={tabsProps.onTab2Click} />
        </ic-tabs>,
        {container: $tabsContainer}
      )
    }
  }

  function getSelect() {
    return $container.querySelector('select')
  }

  function getOptions() {
    return [...$container.querySelectorAll('select option')]
  }

  function getOptionLabels() {
    return getOptions().map($option => $option.textContent.trim())
  }

  function getOption(optionLabel) {
    return getOptions().find($option => $option.textContent.trim() === optionLabel)
  }

  function getSelectedOptionLabel() {
    const optionId = getSelect().value
    const $selectedOption = getOptions().find($option => $option.value === optionId)
    return $selectedOption.textContent.trim()
  }

  function selectOption(optionLabel) {
    const $option = getOption(optionLabel)
    fireEvent.change(getSelect(), {target: {value: $option.value}})
  }

  test('includes options for Gradebook pages', () => {
    renderComponent()
    deepEqual(getOptionLabels(), ['Individual View', 'Gradebook…', 'Gradebook History…'])
  })

  QUnit.module('"Gradebook…" option', () => {
    test('calls the .navigate callback when clicked', () => {
      renderComponent()
      selectOption('Gradebook…')
      strictEqual(props.navigate.callCount, 1)
    })

    test('includes the default gradebook url when calling the .navigate callback', () => {
      renderComponent()
      selectOption('Gradebook…')
      const [url] = props.navigate.lastCall.args
      equal(
        url,
        'https://localhost/courses/1201/gradebook/change_gradebook_version?version=default'
      )
    })
  })

  QUnit.module('"Gradebook History…" option', () => {
    test('calls the .navigate callback when clicked', () => {
      renderComponent()
      selectOption('Gradebook History…')
      strictEqual(props.navigate.callCount, 1)
    })

    test('includes the gradebook history url when calling the .navigate callback', () => {
      renderComponent()
      selectOption('Gradebook History…')
      const [url] = props.navigate.lastCall.args
      equal(url, 'https://localhost/courses/1201/gradebook/history')
    })
  })

  QUnit.module('when learning mastery is enabled', hooks => {
    hooks.beforeEach(() => {
      props.learningMasteryEnabled = true
    })

    QUnit.module('"Individual View" option', () => {
      test('is selected by default', () => {
        renderComponent()
        equal(getSelectedOptionLabel(), 'Individual View')
      })

      test('does not call the .navigate callback when clicked', () => {
        renderComponent()
        selectOption('Individual View')
        strictEqual(props.navigate.callCount, 0)
      })

      test('clicks the first `ic-tab` when clicked', () => {
        renderComponent()
        selectOption('Individual View')
        strictEqual(tabsProps.onTab1Click.callCount, 1)
      })

      test('"Individual View" is selected when displayed', () => {
        renderComponent()
        selectOption('Learning Mastery…')
        selectOption('Individual View…')
        equal(getSelectedOptionLabel(), 'Individual View')
      })
    })

    QUnit.module('"Learning Mastery" option', () => {
      test('is included', () => {
        renderComponent()
        ok(getOptionLabels().includes('Learning Mastery…'))
      })

      test('is selected when displayed', () => {
        renderComponent()
        selectOption('Learning Mastery…')
        equal(getSelectedOptionLabel(), 'Learning Mastery')
      })

      test('option clicks the second `ic-tab` when clicked', () => {
        renderComponent()
        selectOption('Learning Mastery…')
        strictEqual(tabsProps.onTab2Click.callCount, 1)
      })

      test('does not call the .navigate callback when clicked', () => {
        renderComponent()
        selectOption('Learning Mastery…')
        strictEqual(props.navigate.callCount, 0)
      })
    })
  })
})
