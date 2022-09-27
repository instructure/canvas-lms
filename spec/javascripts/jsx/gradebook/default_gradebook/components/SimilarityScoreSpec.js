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
import ReactDOM from 'react-dom'
import SimilarityScore from 'ui/features/gradebook/react/default_gradebook/components/SimilarityScore'

QUnit.module('SimilarityScore', moduleHooks => {
  let $container

  moduleHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
  })

  moduleHooks.afterEach(() => {
    $container.remove()
  })

  function mountComponent(props = {}) {
    const defaultProps = {
      hasAdditionalData: false,
      reportUrl: '/my_superlative_report',
      similarityScore: 60,
      status: 'scored',
    }

    ReactDOM.render(<SimilarityScore {...defaultProps} {...props} />, $container)
  }

  QUnit.module('when the originality report has been scored', () => {
    test('displays the similarity score', () => {
      mountComponent()
      strictEqual($container.innerText, '60.0% similarity score')
    })

    test('links to the originality report for the submission', () => {
      mountComponent()
      ok($container.querySelector('a').href.includes('/my_superlative_report'))
    })

    test('displays an icon corresponding to the passed-in similarity data', () => {
      mountComponent()
      ok($container.querySelector('svg[name=IconOvalHalf]'))
    })
  })

  QUnit.module('when the originality report is in an "error" state', () => {
    test('displays a warning icon', () => {
      mountComponent({status: 'error'})
      ok($container.querySelector('svg[name=IconWarning]'))
    })

    test('displays an error message', () => {
      mountComponent({status: 'error'})
      ok($container.innerText.includes('Error submitting to plagiarism service'))
    })
  })

  QUnit.module('when the originality data is in a "pending" state', () => {
    test('displays a clock icon', () => {
      mountComponent({status: 'pending'})
      ok($container.querySelector('svg[name=IconClock]'))
    })

    test('displays a message indicating the submission is pending', () => {
      mountComponent({status: 'pending'})
      ok($container.innerText.includes('Submission is being processed by plagiarism service'))
    })
  })

  test('displays a message indicating additional reports exist when hasAdditionalData is true', () => {
    mountComponent({hasAdditionalData: true})
    ok(
      $container.innerText.includes('This submission has plagiarism data for multiple attachments.')
    )
  })

  test('does not display a message indicating additional reports exist when hasAdditionalData is false', () => {
    mountComponent()
    notOk(
      $container.innerText.includes('This submission has plagiarism data for multiple attachments.')
    )
  })
})
