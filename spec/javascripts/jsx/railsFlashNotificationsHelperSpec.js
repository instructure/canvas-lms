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

import {useScope as useI18nScope} from '@canvas/i18n'

import $ from 'jquery'
import 'jquery-migrate'
import htmlEscape from '@instructure/html-escape'
import NotificationsHelper from '@canvas/rails-flash-notifications/jquery/helper'

const I18n = useI18nScope('shared.flash_notices')

let helper
let fixtures

QUnit.module('RailsFlashNotificationsHelper#holderReady', {
  setup() {
    fixtures = document.getElementById('fixtures')
    helper = new NotificationsHelper()
  },
  teardown() {
    fixtures.innerHTML = ''
  },
})

test('returns false if holder is initilialized without the flash message holder in the DOM', () => {
  fixtures.innerHTML = ''

  helper.initHolder()

  ok(!helper.holderReady())
})

test('returns false before the holder is initialized even with flash message holder in the DOM', () => {
  fixtures.innerHTML = '<div id="flash_message_holder"></div>'

  ok(!helper.holderReady())
})

test('returns true after the holder is initialized with flash message holder in the DOM', () => {
  fixtures.innerHTML = '<div id="flash_message_holder"></div>'

  helper.initHolder()

  ok(helper.holderReady())
})

QUnit.module('RailsFlashNotificationsHelper#getIconType', {
  setup() {
    helper = new NotificationsHelper()
  },
})

test('returns check when given success', () => {
  equal(helper.getIconType('success'), 'check')
})

test('returns warning when given warning', () => {
  equal(helper.getIconType('warning'), 'warning')
})

test('returns warning when given error', () => {
  equal(helper.getIconType('error'), 'warning')
})

test('returns info when given any other input', () => {
  equal(helper.getIconType('some input'), 'info')
})

QUnit.module('RailsFlashNotificationsHelper#generateNodeHTML', {
  setup() {
    helper = new NotificationsHelper()
  },
})

test('properly injects type, icon, and content into html', () => {
  const result = helper.generateNodeHTML('success', 'Some Data')

  notStrictEqual(result.search('ic-flash-success'), -1)
  notStrictEqual(result.search('class="icon-check"'), -1)
  notStrictEqual(result.search('Some Data'), -1)
})

QUnit.module('RailsFlashNotificationsHelper#createNode', {
  setup() {
    fixtures = document.getElementById('fixtures')
    fixtures.innerHTML = '<div id="flash_message_holder"></div>'

    helper = new NotificationsHelper()
  },
  teardown() {
    fixtures.innerHTML = ''
  },
})

test('does not create a node before the holder is initialized', () => {
  helper.createNode('success', 'Some Data')

  const holder = document.getElementById('flash_message_holder')

  equal(holder.firstChild, null)
})

test('creates a node', () => {
  helper.initHolder()
  helper.createNode('success', 'Some Other Data')

  const holder = document.getElementById('flash_message_holder')

  equal(holder.firstChild.tagName, 'DIV')
  ok(holder.firstChild.className.includes('flash-message-container'))
})

test('properly adds css options when creating a node', () => {
  helper.initHolder()

  const css = {width: '300px', direction: 'rtl'}

  helper.createNode('success', 'Some Third Data', 3000, css)

  const holder = document.getElementById('flash_message_holder')

  equal(holder.firstChild.style.zIndex, '2')
  equal(holder.firstChild.style.width, '300px')
  equal(holder.firstChild.style.direction, 'rtl')
})

test('closes when the close button is clicked', () => {
  helper.initHolder()
  helper.createNode('success', 'Closable Alert')

  const holder = document.getElementById('flash_message_holder')
  const button = holder.getElementsByClassName('close_link')

  equal(button.length, 1)

  $(button[0]).click()

  equal(holder.firstChild, null)
})

test('closes when the alert is clicked', () => {
  helper.initHolder()
  helper.createNode('success', 'Closable Alert')

  const holder = document.getElementById('flash_message_holder')
  const alert = holder.getElementsByClassName('flash-message-container')

  equal(alert.length, 1)

  $(alert[0]).click()

  equal(holder.firstChild, null)
})

QUnit.module('RailsFlashNotificationsHelper#screenreaderHolderReady', {
  setup() {
    fixtures = document.getElementById('fixtures')
    helper = new NotificationsHelper()
    // Since this div can get created on the fly as needed, which is a black-box implementation detail,
    // unreasonable to expect specs that test for screenreader messages to know that and clean up something
    // it didn't explicitly create. We have to guarantee it's gone before these specs run.
    const fsh = document.getElementById('flash_screenreader_holder')
    if (fsh) {
      fsh.parentElement.removeChild(fsh)
    }
  },
  teardown() {
    fixtures.innerHTML = ''
  },
})

test('returns false if screenreader holder is initialized without the screenreader message holder in the DOM', () => {
  fixtures.innerHTML = ''

  helper.initScreenreaderHolder()

  ok(!helper.screenreaderHolderReady())
})

test('returns false before the screenreader holder is initialized even with screenreader message holder in the DOM', () => {
  fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>'

  ok(!helper.screenreaderHolderReady())
})

test('returns true after the screenreader holder is initialized', () => {
  fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>'

  helper.initScreenreaderHolder()

  ok(helper.screenreaderHolderReady())
})

QUnit.module('RailsFlashNotificationsHelper#setScreenreaderAttributes', {
  setup() {
    fixtures = document.getElementById('fixtures')
    fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>'

    helper = new NotificationsHelper()
  },
  teardown() {
    fixtures.innerHTML = ''
  },
})

test('does not apply attributes if screenreader holder is not initialized', () => {
  helper.setScreenreaderAttributes()

  const screenreaderHolder = document.getElementById('flash_screenreader_holder')

  equal(screenreaderHolder.getAttribute('role'), null)
  equal(screenreaderHolder.getAttribute('aria-live'), null)
  equal(screenreaderHolder.getAttribute('aria-relevant'), null)
})

test('applies attributes on initialization of screenreader holder', () => {
  helper.initScreenreaderHolder()

  const screenreaderHolder = document.getElementById('flash_screenreader_holder')

  equal(screenreaderHolder.getAttribute('role'), 'alert')
  equal(screenreaderHolder.getAttribute('aria-live'), 'assertive')
  equal(screenreaderHolder.getAttribute('aria-relevant'), 'additions')
})

test('does not break when attributes already exist', () => {
  helper.initScreenreaderHolder()
  helper.setScreenreaderAttributes()

  const screenreaderHolder = document.getElementById('flash_screenreader_holder')

  equal(screenreaderHolder.getAttribute('role'), 'alert')
  equal(screenreaderHolder.getAttribute('aria-live'), 'assertive')
  equal(screenreaderHolder.getAttribute('aria-relevant'), 'additions')
})

QUnit.module('RailsFlashNotificationsHelper#resetScreenreaderAttributes', {
  setup() {
    fixtures = document.getElementById('fixtures')
    fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>'

    helper = new NotificationsHelper()
  },
  teardown() {
    fixtures.innerHTML = ''
  },
})

test('does not break when the screen reader holder is not initialized', () => {
  helper.resetScreenreaderAttributes()

  const screenreaderHolder = document.getElementById('flash_screenreader_holder')

  equal(screenreaderHolder.getAttribute('role'), null)
  equal(screenreaderHolder.getAttribute('aria-live'), null)
  equal(screenreaderHolder.getAttribute('aria-relevant'), null)
})

test('removes attributes from the screenreader holder', () => {
  helper.initScreenreaderHolder()
  helper.resetScreenreaderAttributes()

  const screenreaderHolder = document.getElementById('flash_screenreader_holder')

  equal(screenreaderHolder.getAttribute('role'), null)
  equal(screenreaderHolder.getAttribute('aria-live'), null)
  equal(screenreaderHolder.getAttribute('aria-relevant'), null)
})

test('does not break when attributes do not exist', () => {
  helper.initScreenreaderHolder()
  helper.resetScreenreaderAttributes()
  helper.resetScreenreaderAttributes()

  const screenreaderHolder = document.getElementById('flash_screenreader_holder')

  equal(screenreaderHolder.getAttribute('role'), null)
  equal(screenreaderHolder.getAttribute('aria-live'), null)
  equal(screenreaderHolder.getAttribute('aria-relevant'), null)
})

QUnit.module('RailsFlashNotificationsHelper#generateScreenreaderNodeHTML', {
  setup() {
    helper = new NotificationsHelper()
  },
})

test('properly injects content into html', () => {
  const result = helper.generateScreenreaderNodeHTML('Some Data')

  notStrictEqual(result.search('Some Data'), -1)
})

test('properly includes the indication to close when given true', () => {
  const result = helper.generateScreenreaderNodeHTML('Some Data', true)

  notStrictEqual(result.search(htmlEscape(I18n.t('close', 'Close'))), -1)
})

test('properly excludes the indication to close when given false', () => {
  const result = helper.generateScreenreaderNodeHTML('Some Data', false)

  equal(result.search(htmlEscape(I18n.t('close', 'Close'))), -1)
})

QUnit.module('RailsFlashNotificationsHelper#createScreenreaderNode', {
  setup() {
    fixtures = document.getElementById('fixtures')
    fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>'

    helper = new NotificationsHelper()
    helper.initScreenreaderHolder()
  },
  teardown() {
    fixtures.innerHTML = ''
  },
})

test('creates a screenreader node', () => {
  helper.createScreenreaderNode('Some Other Data')

  const screenreaderHolder = document.getElementById('flash_screenreader_holder')

  equal(screenreaderHolder.firstChild.tagName, 'SPAN')
})

QUnit.module('RailsFlashNotificationsHelper#createScreenreaderNodeExclusive', {
  setup() {
    fixtures = document.getElementById('fixtures')
    fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>'

    helper = new NotificationsHelper()
    helper.initScreenreaderHolder()
  },
  teardown() {
    fixtures.innerHTML = ''
  },
})

test('properly clears existing screenreader nodes and creates a new one', () => {
  helper.createScreenreaderNode('Some Data')
  helper.createScreenreaderNode('Some Second Data')
  helper.createScreenreaderNode('Some Third Data')

  const screenreaderHolder = document.getElementById('flash_screenreader_holder')

  equal(screenreaderHolder.childNodes.length, 3)

  helper.createScreenreaderNodeExclusive('Some New Data')

  equal(screenreaderHolder.childNodes.length, 1)
})

test('does not toggles polite aria-live when polite is false', () => {
  const polite = false
  helper.createScreenreaderNodeExclusive('a message', polite)
  const screenreaderHolder = document.getElementById('flash_screenreader_holder')
  equal(screenreaderHolder.getAttribute('aria-live'), 'assertive')
})

test('optionally toggles polite aria-live', () => {
  const polite = true
  helper.createScreenreaderNodeExclusive('a message', polite)
  const screenreaderHolder = document.getElementById('flash_screenreader_holder')
  equal(screenreaderHolder.getAttribute('aria-live'), 'polite')
})

QUnit.module('RailsFlashNotificationsHelper#escapeContent', {
  setup() {
    helper = new NotificationsHelper()
  },
})

test('returns html if content has html property', () => {
  const content = {}
  content.html = '<script>Some Script</script>'

  const result = helper.escapeContent(content)

  equal(result, content.html)
})

test('returns html if content has string property', () => {
  const content = {}
  content.string = '<script>Some String</script>'

  const result = helper.escapeContent(content)

  equal(result, content)
})

test('returns escaped content if content has no string or html property', () => {
  const content = '<script>Some Data</script>'

  const result = helper.escapeContent(content)

  equal(result, htmlEscape(content))
})

QUnit.module('flash alert tests', function (hooks) {
  let initialFxOff
  let clock

  hooks.beforeEach(function () {
    fixtures = document.getElementById('fixtures')
    fixtures.innerHTML = '<div id="flash_message_holder"></div>'
    helper = new NotificationsHelper()
    // disable jQuery animations as the Sinon clock was breaking fadeOut() callback
    // by disabling animations/FX, we can more precisely control the clock and ensure
    // the node is removed after the specified delay/timeout duration
    initialFxOff = $.fx.off
    $.fx.off = true
    clock = sinon.useFakeTimers()
    // we must reset the ENV.flashAlertTimeout variable after each test
    ENV.flashAlertTimeout = undefined
  })

  hooks.afterEach(function () {
    fixtures.innerHTML = ''
    $.fx.off = initialFxOff
    clock.restore()
  })

  test('forces ENV.flashAlertTimeout if variable is set', () => {
    const desiredTimeout = 100
    const ignoredTimeout = 500
    // set the global which will override parameter and the default delay durations
    ENV.flashAlertTimeout = desiredTimeout
    helper.initHolder()
    helper.createNode('success', 'Closable Alert', ignoredTimeout)
    // check that the node is present before advancing the clock
    let holder = document.getElementById('flash_message_holder')
    ok(holder.firstChild, 'node should be present when delay duration starts')
    // advance the clock slightly before the delay duration
    clock.tick(desiredTimeout - 1)
    // ensure the node is still present before the delay duration completes
    holder = document.getElementById('flash_message_holder')
    ok(holder.firstChild, 'node should still be present before delay duration ends')
    // advance the clock to exactly the delay duration
    clock.tick(1)
    // ensure the node is removed after the default delay duration completes
    holder = document.getElementById('flash_message_holder')
    equal(holder.firstChild, null, 'node should be removed when delay duration is completed')
  })

  test('respects timeout parameter if ENV.flashAlertTimeout variable is not set', () => {
    const desiredTimeout = 100
    helper.initHolder()
    // use parameter instead of ENV.flashAlertTimeout or createNode()’s 7000 default
    helper.createNode('success', 'Closable Alert', desiredTimeout)
    let holder = document.getElementById('flash_message_holder')
    ok(holder.firstChild, 'node should be present when delay duration starts')
    clock.tick(desiredTimeout - 1)
    holder = document.getElementById('flash_message_holder')
    ok(holder.firstChild, 'node should still be present before delay duration ends')
    clock.tick(1)
    holder = document.getElementById('flash_message_holder')
    equal(holder.firstChild, null, 'node should be removed when delay duration is completed')
  })

  test('respects default timeout parameter of 7000 milliseconds if ENV.flashAlertTimeout OR parameter variables are not set', () => {
    const defaultTimeout = 7000
    // force createNode() to use the default of 7000 milliseconds
    const desiredTimeout = undefined
    helper.initHolder()
    helper.createNode('success', 'Closable Alert', desiredTimeout)
    let holder = document.getElementById('flash_message_holder')
    ok(holder.firstChild, 'node should be present when delay duration starts')
    clock.tick(defaultTimeout - 1)
    holder = document.getElementById('flash_message_holder')
    ok(holder.firstChild, 'node should still be present before delay duration ends')
    clock.tick(1)
    holder = document.getElementById('flash_message_holder')
    equal(holder.firstChild, null, 'node should be removed when delay duration is completed')
  })
})
