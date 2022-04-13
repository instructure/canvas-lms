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
import ReactDOM from 'react-dom'
import SimilarityIndicator from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/editors/SimilarityIndicator'

QUnit.module('SimilarityIndicator', moduleHooks => {
  let $container
  const elementRef = () => {}

  moduleHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
  })

  moduleHooks.afterEach(() => {
    $container.remove()
  })

  function tooltipText() {
    const tooltipElementId = $container.querySelector('button').getAttribute('aria-describedby')
    return document.getElementById(tooltipElementId).innerText
  }

  function mountComponent(similarityInfo) {
    ReactDOM.render(
      <SimilarityIndicator elementRef={elementRef} similarityInfo={similarityInfo} />,
      $container
    )
  }

  QUnit.module('when the status is "scored"', () => {
    test('shows an icon commensurate with the score', () => {
      mountComponent({status: 'scored', similarityScore: 13})
      ok($container.querySelector('svg[name=IconCertified]'))
    })

    test('includes the percent score as a tooltip', () => {
      mountComponent({status: 'scored', similarityScore: 13})
      strictEqual(tooltipText(), '13.0% similarity score')
    })
  })

  QUnit.module('when the status is "pending"', () => {
    test('shows a clock icon', () => {
      mountComponent({status: 'pending'})
      ok($container.querySelector('svg[name=IconClock]'))
    })

    test('contains a tooltip indicating the pending status', () => {
      mountComponent({status: 'pending'})
      strictEqual(tooltipText(), 'Being processed by plagiarism service')
    })
  })

  QUnit.module('when the status is "error"', () => {
    test('shows a warning icon when the status is "error"', () => {
      mountComponent({status: 'error'})
      ok($container.querySelector('svg[name=IconWarning]'))
    })

    test('shows a clock icon', () => {
      mountComponent({status: 'error'})
      strictEqual(tooltipText(), 'Error submitting to plagiarism service')
    })
  })
})
