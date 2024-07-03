/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import kalturaAnalytics from '../kalturaAnalytics'
import mejs from '@canvas/mediaelement'
import 'jquery.cookie'
import sinon from 'sinon'

const sandbox = sinon.createSandbox()

const ok = x => expect(x).toBeTruthy()
const equal = (x, y) => expect(x).toEqual(y)

let player
let pluginSettings

describe('kaltura analytics helper', () => {
  beforeEach(() => {
    player = new mejs.PluginMediaElement()
    pluginSettings = {
      partner_id: 'ster',
      kcw_ui_conf: 'cobb',
      domain: 'example.com',
      do_analytics: true,
      parallel_api_calls: 1,
    }
  })

  afterEach(() => {
    $('.kaltura-analytics').remove()
    $.cookie('kaltura_analytic_tracker', null, {path: '/'})
  })

  test('adds event listeners', function () {
    sandbox.mock(player).expects('addEventListener').atLeast(6)
    kalturaAnalytics('1', player, pluginSettings)
  })

  test('generate api url', function () {
    const ka = kalturaAnalytics('1', player, pluginSettings)
    if (window.location.protocol === 'http:') {
      equal(ka.generateApiUrl(), 'http://example.com/api_v3/index.php?', 'generated bad url')
    } else {
      equal(ka.generateApiUrl(), 'https://example.com/api_v3/index.php?', 'generated bad url')
    }
  })

  test('queue new analytics call', function () {
    const ka = kalturaAnalytics('1', player, pluginSettings)
    const exp = sinon.expectation.create([]).once()
    ka.iframes[0].pinger = exp
    ka.queueAnalyticEvent('oioi')
    if (window.location.protocol === 'http:') {
      equal(
        ka.iframes[0].queue[0].indexOf(
          'http://example.com/api_v3/index.php?service=stats&action=collect&event%3AentryId=1&event'
        ),
        0
      )
    } else {
      equal(
        ka.iframes[0].queue[0].indexOf(
          'https://example.com/api_v3/index.php?service=stats&action=collect&event%3AentryId=1&event'
        ),
        0
      )
    }
    ok(ka.iframes[0].queue[0].match(/eventType=oioi/))
    exp.verify()
  })

  test("don't load if disabled", function () {
    equal(kalturaAnalytics('1', player, {do_analytics: false}), undefined)
    equal(kalturaAnalytics('1', player, {}), undefined)
    equal(kalturaAnalytics('1', player, null), undefined)
  })

  test('iframe created', function () {
    const ka = kalturaAnalytics('1', player, pluginSettings)
    const iframe = $('.kaltura-analytics')
    equal(iframe.length, ka.iframes.length)
    ok(iframe.hasClass('hidden'))
  })
})
