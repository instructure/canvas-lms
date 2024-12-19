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

import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import htmlEscape from '@instructure/html-escape'
import NotificationsHelper from '../helper'

const I18n = createI18nScope('shared.flash_notices')

describe('RailsFlashNotificationsHelper', () => {
  let helper
  let fixtures

  window.ENV = window.ENV || {}

  beforeEach(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
    helper = new NotificationsHelper()
    $.fx.off = true // Disable jQuery animations
  })

  afterEach(() => {
    fixtures.remove()
    $.fx.off = false // Re-enable jQuery animations
  })

  describe('#holderReady', () => {
    it('returns false if holder is initialized without the flash message holder in the DOM', () => {
      helper.initHolder()
      expect(helper.holderReady()).toBe(false)
    })

    it('returns false before the holder is initialized even with flash message holder in the DOM', () => {
      fixtures.innerHTML = '<div id="flash_message_holder"></div>'
      expect(helper.holderReady()).toBe(false)
    })

    it('returns true after the holder is initialized with flash message holder in the DOM', () => {
      fixtures.innerHTML = '<div id="flash_message_holder"></div>'
      helper.initHolder()
      expect(helper.holderReady()).toBe(true)
    })
  })

  describe('#getIconType', () => {
    it('returns check when given success', () => {
      expect(helper.getIconType('success')).toBe('check')
    })

    it('returns warning when given warning', () => {
      expect(helper.getIconType('warning')).toBe('warning')
    })

    it('returns warning when given error', () => {
      expect(helper.getIconType('error')).toBe('warning')
    })

    it('returns info when given any other input', () => {
      expect(helper.getIconType('some input')).toBe('info')
    })
  })

  describe('#generateNodeHTML', () => {
    it('properly injects type, icon, and content into html', () => {
      const result = helper.generateNodeHTML('success', 'Some Data')
      expect(result).toContain('ic-flash-success')
      expect(result).toContain('class="icon-check"')
      expect(result).toContain('Some Data')
    })
  })

  describe('#createNode', () => {
    beforeEach(() => {
      fixtures.innerHTML = '<div id="flash_message_holder"></div>'
    })

    it('does not create a node before the holder is initialized', () => {
      helper.createNode('success', 'Some Data')
      const holder = document.getElementById('flash_message_holder')
      expect(holder.firstChild).toBeNull()
    })

    it('creates a node', () => {
      helper.initHolder()
      helper.createNode('success', 'Some Other Data')
      const holder = document.getElementById('flash_message_holder')
      expect(holder.firstChild.tagName).toBe('DIV')
      expect(holder.firstChild.className).toContain('flash-message-container')
    })

    it('properly adds css options when creating a node', () => {
      helper.initHolder()
      const css = {width: '300px', direction: 'rtl'}
      helper.createNode('success', 'Some Third Data', 3000, css)
      const holder = document.getElementById('flash_message_holder')
      expect(holder.firstChild.style.zIndex).toBe('2')
      expect(holder.firstChild.style.width).toBe('300px')
      expect(holder.firstChild.style.direction).toBe('rtl')
    })

    it('closes when the close button is clicked', () => {
      helper.initHolder()
      helper.createNode('success', 'Closable Alert')
      const holder = document.getElementById('flash_message_holder')
      const button = holder.querySelector('.close_link')
      button.click()
      expect(holder.firstChild).toBeNull()
    })

    it('closes when the alert is clicked', () => {
      helper.initHolder()
      helper.createNode('success', 'Closable Alert')
      const holder = document.getElementById('flash_message_holder')
      const alert = holder.querySelector('.flash-message-container')
      alert.click()
      expect(holder.firstChild).toBeNull()
    })
  })

  describe('#screenreaderHolder', () => {
    beforeEach(() => {
      const existingHolder = document.getElementById('flash_screenreader_holder')
      if (existingHolder) {
        existingHolder.remove()
      }
    })

    it('returns false if screenreader holder is initialized without the holder in the DOM', () => {
      helper.initScreenreaderHolder()
      expect(helper.screenreaderHolderReady()).toBe(false)
    })

    it('returns false before the screenreader holder is initialized even with holder in the DOM', () => {
      fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>'
      expect(helper.screenreaderHolderReady()).toBe(false)
    })

    it('returns true after the screenreader holder is initialized', () => {
      fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>'
      helper.initScreenreaderHolder()
      expect(helper.screenreaderHolderReady()).toBe(true)
    })
  })

  describe('#setScreenreaderAttributes', () => {
    beforeEach(() => {
      fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>'
    })

    it('does not apply attributes if screenreader holder is not initialized', () => {
      helper.setScreenreaderAttributes()
      const holder = document.getElementById('flash_screenreader_holder')
      expect(holder.getAttribute('role')).toBeNull()
      expect(holder.getAttribute('aria-live')).toBeNull()
      expect(holder.getAttribute('aria-relevant')).toBeNull()
    })

    it('applies attributes on initialization of screenreader holder', () => {
      helper.initScreenreaderHolder()
      const holder = document.getElementById('flash_screenreader_holder')
      expect(holder.getAttribute('role')).toBe('alert')
      expect(holder.getAttribute('aria-live')).toBe('assertive')
      expect(holder.getAttribute('aria-relevant')).toBe('additions')
    })

    it('does not break when attributes already exist', () => {
      helper.initScreenreaderHolder()
      helper.setScreenreaderAttributes()
      const holder = document.getElementById('flash_screenreader_holder')
      expect(holder.getAttribute('role')).toBe('alert')
      expect(holder.getAttribute('aria-live')).toBe('assertive')
      expect(holder.getAttribute('aria-relevant')).toBe('additions')
    })
  })

  describe('#resetScreenreaderAttributes', () => {
    beforeEach(() => {
      fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>'
    })

    it('does not break when the screen reader holder is not initialized', () => {
      helper.resetScreenreaderAttributes()
      const holder = document.getElementById('flash_screenreader_holder')
      expect(holder.getAttribute('role')).toBeNull()
      expect(holder.getAttribute('aria-live')).toBeNull()
      expect(holder.getAttribute('aria-relevant')).toBeNull()
    })

    it('removes attributes from the screenreader holder', () => {
      helper.initScreenreaderHolder()
      helper.resetScreenreaderAttributes()
      const holder = document.getElementById('flash_screenreader_holder')
      expect(holder.getAttribute('role')).toBeNull()
      expect(holder.getAttribute('aria-live')).toBeNull()
      expect(holder.getAttribute('aria-relevant')).toBeNull()
    })
  })

  describe('#generateScreenreaderNodeHTML', () => {
    it('properly injects content into html', () => {
      const result = helper.generateScreenreaderNodeHTML('Some Data')
      expect(result).toContain('Some Data')
    })

    it('properly includes the indication to close when given true', () => {
      const result = helper.generateScreenreaderNodeHTML('Some Data', true)
      expect(result).toContain(htmlEscape(I18n.t('close', 'Close')))
    })

    it('properly excludes the indication to close when given false', () => {
      const result = helper.generateScreenreaderNodeHTML('Some Data', false)
      expect(result).not.toContain(htmlEscape(I18n.t('close', 'Close')))
    })
  })

  describe('#createScreenreaderNode', () => {
    beforeEach(() => {
      fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>'
      helper.initScreenreaderHolder()
    })

    it('creates a screenreader node', () => {
      helper.createScreenreaderNode('Some Other Data')
      const holder = document.getElementById('flash_screenreader_holder')
      expect(holder.firstChild.tagName).toBe('SPAN')
    })
  })

  describe('#createScreenreaderNodeExclusive', () => {
    beforeEach(() => {
      fixtures.innerHTML = '<div id="flash_screenreader_holder"></div>'
      helper.initScreenreaderHolder()
    })

    it('properly clears existing screenreader nodes and creates a new one', () => {
      helper.createScreenreaderNode('Some Data')
      helper.createScreenreaderNode('Some Second Data')
      helper.createScreenreaderNode('Some Third Data')
      const holder = document.getElementById('flash_screenreader_holder')
      expect(holder.childNodes).toHaveLength(3)
      helper.createScreenreaderNodeExclusive('Some New Data')
      expect(holder.childNodes).toHaveLength(1)
    })

    it('does not toggle polite aria-live when polite is false', () => {
      helper.createScreenreaderNodeExclusive('a message', false)
      const holder = document.getElementById('flash_screenreader_holder')
      expect(holder.getAttribute('aria-live')).toBe('assertive')
    })

    it('optionally toggles polite aria-live', () => {
      helper.createScreenreaderNodeExclusive('a message', true)
      const holder = document.getElementById('flash_screenreader_holder')
      expect(holder.getAttribute('aria-live')).toBe('polite')
    })
  })

  describe('#escapeContent', () => {
    it('returns html if content has html property', () => {
      const content = {html: '<script>Some Script</script>'}
      const result = helper.escapeContent(content)
      expect(result).toBe(content.html)
    })

    it('returns html if content has string property', () => {
      const content = {string: '<script>Some String</script>'}
      const result = helper.escapeContent(content)
      expect(result).toBe(content)
    })

    it('returns escaped content if content has no string or html property', () => {
      const content = '<script>Some Data</script>'
      const result = helper.escapeContent(content)
      expect(result).toBe(htmlEscape(content))
    })
  })

  describe('flash alert tests', () => {
    beforeEach(() => {
      fixtures.innerHTML = '<div id="flash_message_holder"></div>'
      helper = new NotificationsHelper()
      window.ENV.flashAlertTimeout = undefined
    })

    it('forces ENV.flashAlertTimeout if variable is set', () => {
      const desiredTimeout = 100
      const ignoredTimeout = 500
      window.ENV.flashAlertTimeout = desiredTimeout
      helper.initHolder()
      helper.createNode('success', 'Closable Alert', ignoredTimeout)

      const holder = document.getElementById('flash_message_holder')
      expect(holder.firstChild).toBeTruthy()
      expect(holder.firstChild.classList.contains('flash-message-container')).toBe(true)
    })

    it('respects timeout parameter if ENV.flashAlertTimeout variable is not set', () => {
      const desiredTimeout = 100
      helper.initHolder()
      helper.createNode('success', 'Closable Alert', desiredTimeout)

      const holder = document.getElementById('flash_message_holder')
      expect(holder.firstChild).toBeTruthy()
      expect(holder.firstChild.classList.contains('flash-message-container')).toBe(true)
    })

    it('respects default timeout parameter of 7000 milliseconds if no timeout is set', () => {
      helper.initHolder()
      helper.createNode('success', 'Closable Alert')

      const holder = document.getElementById('flash_message_holder')
      expect(holder.firstChild).toBeTruthy()
      expect(holder.firstChild.classList.contains('flash-message-container')).toBe(true)
    })
  })
})
