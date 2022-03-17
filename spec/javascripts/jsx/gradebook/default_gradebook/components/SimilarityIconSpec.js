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
import SimilarityIcon from 'ui/features/gradebook/react/default_gradebook/components/SimilarityIcon'

QUnit.module('SimilarityIcon', moduleHooks => {
  let $container

  moduleHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
  })

  moduleHooks.afterEach(() => {
    $container.remove()
  })

  function mountComponent(props = {}) {
    ReactDOM.render(<SimilarityIcon {...props} />, $container)
  }

  QUnit.module('when the status is "scored"', () => {
    test('shows a "certified" icon when the similarity score is below 20%', () => {
      mountComponent({status: 'scored', similarityScore: 10})
      ok($container.querySelector('svg[name=IconCertified]'))
    })

    test('shows a half-full circle icon when the similarity score is between 20% and 60%', () => {
      mountComponent({status: 'scored', similarityScore: 40})
      ok($container.querySelector('svg[name=IconOvalHalf]'))
    })

    test('shows a filled circle icon when the similarity score is above 60%', () => {
      mountComponent({status: 'scored', similarityScore: 70})
      ok($container.querySelector('svg[name=IconEmpty]'))
    })

    test('shows a warning icon if no similarity score is passed', () => {
      mountComponent({status: 'scored'})
      ok($container.querySelector('svg[name=IconWarning]'))
    })
  })

  test('displays a clock icon when the status is "pending"', () => {
    mountComponent({status: 'pending'})
    ok($container.querySelector('svg[name=IconClock]'))
  })

  test('displays a warning icon when the status is "error"', () => {
    mountComponent({status: 'error'})
    ok($container.querySelector('svg[name=IconWarning]'))
  })
})
