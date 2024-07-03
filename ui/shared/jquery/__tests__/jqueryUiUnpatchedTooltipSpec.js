/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import $ from 'jquery'
import 'jqueryui/tooltip'

QUnit.module('tooltip widget', {
  beforeEach() {
    $('#fixtures').append('<div id="test-tooltip" title="tooltip text">hover over me</div>')
    $('#test-tooltip').tooltip()
  },
  afterEach() {
    const $tooltipTarget = $('#test-tooltip')
    // prevents garbage collection test from breaking
    if ($tooltipTarget.data('ui-tooltip')) {
      $tooltipTarget.tooltip('destroy')
    }
    $('#fixtures').empty()
  },
})

QUnit.test('tooltip shows on mouseenter', function (assert) {
  const done = assert.async()
  const $tooltipTarget = $('#test-tooltip')
  $tooltipTarget.on('tooltipopen', function () {
    assert.ok(true, 'tooltip is shown on mouseenter')
    done()
  })
  $tooltipTarget.trigger('mouseenter')
})

QUnit.test('tooltip hides on mouseleave', function (assert) {
  const done = assert.async()
  const $tooltipTarget = $('#test-tooltip')
  $tooltipTarget.tooltip('open')
  let tooltipClosed = false
  $tooltipTarget.on('tooltipclose', function () {
    assert.ok(true, 'tooltip is hidden on mouseleave')
    // this flag prevents “Too many calls to the `assert.async` callback” error
    if (!tooltipClosed) {
      tooltipClosed = true
      done()
    }
  })
  $tooltipTarget.trigger('mouseleave')
})

QUnit.test('Custom content is displayed', function (assert) {
  const customContent = 'Custom tooltip content'
  const $tooltipTarget = $('#test-tooltip')
  $tooltipTarget.tooltip('option', 'content', function () {
    return customContent
  })
  $tooltipTarget.tooltip('open')
  const tooltipContent = $('.ui-tooltip-content').text()
  assert.equal(tooltipContent, customContent, 'tooltip displays custom content')
})

QUnit.test('tooltip can be disabled and re-enabled', function (assert) {
  const done = assert.async()
  const $tooltipTarget = $('#test-tooltip')
  $tooltipTarget.tooltip('disable')
  $tooltipTarget.tooltip('open')
  assert.strictEqual($('.ui-tooltip').length, 0, 'tooltip does not open when disabled')
  $tooltipTarget.tooltip('enable')
  // wait for the UI to update before checking the tooltip’s presence
  setTimeout(() => {
    $('#test-tooltip').tooltip('open')
    setTimeout(() => {
      // check that at least one tooltip is present
      assert.ok($('.ui-tooltip').length > 0, 'tooltip opens after being re-enabled')
      // signal QUnit that the asynchronous operations are complete
      done()
    }, 100)
  }, 100)
})

QUnit.test('tooltip is fully cleaned up after destruction (garbage collection)', function (assert) {
  const $tooltipTarget = $('#test-tooltip')
  $tooltipTarget.tooltip('destroy')
  assert.strictEqual($('.ui-tooltip').length, 0, 'no tooltip elements remain after destruction')
  assert.strictEqual(
    $tooltipTarget.attr('title'),
    'tooltip text',
    'title attribute is restored after tooltip destruction'
  )
})
