/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {scrollToHighlight} from '../ScrollToHighlight'

class MockElement {
    constructor(){
        this.offsetTop = 0
    }
}

class MockWindow {
    constructor(){
        this._eventListeners = {}
        this._animationFrameCallback = () => {}
        this._now = 0
        this.scrollY = 0
        this.Date = { now: () => this._now }
        this.addEventListener = jest.fn().mockImplementation(
            (event, callback) =>
                this._eventListeners[event] = (injectedEventObject =>
                callback(injectedEventObject)
            )
        )
        this.removeEventListener = jest.fn().mockImplementation(
            event => delete this._eventListeners[event])
        this.scrollTo = jest.fn().mockImplementation((x, y) => this.scrollY = y)
        this.document = {
            activeElement: 5,
            createElement: () => new MockElement(),
            getElementById: (id) => {
                if (id === 'drawer-layout-content') {
                    return {
                        scrollTop: this.scrollY,
                        scrollTo: (x, y) => this.scrollY = y
                    }
                }
                return null
            },
        }
        this.requestAnimationFrame = async callback => this._animationFrameCallback = callback
    }
    async offestTimeMS(ms = 10) {
        if (ms === 0) return
        this._now += ms
        await new Promise(resolve => setTimeout(resolve, ms))
        this._animationFrameCallback()
    }
}

describe ('ScrollToHighlight', () => {

    it('is noop if element is falsy, returns early', async () => {
        const mockWindow = new MockWindow()
        mockWindow.offestTimeMS(1)
        expect(await scrollToHighlight(undefined, mockWindow)).toBe('NO_ELEMENT_TO_SCROLL_TO')
        expect(mockWindow.removeEventListener).toHaveBeenCalledTimes(0)
    })

    it('finishes and cleans up event listeners', async () => {
        const element = document.createElement('div')
        const mockWindow = new MockWindow()
        scrollToHighlight(element, mockWindow).then(_result => {
            expect(mockWindow.removeEventListener).toHaveBeenCalledTimes(3)
        })
    })

    it('scrolls to element', async () => {
        const mockWindow = new MockWindow()
        const element = mockWindow.document.createElement('div')
        element.offsetTop = 10000
        scrollToHighlight(element, mockWindow)
        await mockWindow.offestTimeMS(1)
        const scrollYAtThisPointInTime = mockWindow.scrollY
        expect(scrollYAtThisPointInTime).toBeGreaterThan(0)
        expect(scrollYAtThisPointInTime).toBeLessThan(element.offsetTop)
        await mockWindow.offestTimeMS(10)
        expect(mockWindow.scrollY).toBeGreaterThan(scrollYAtThisPointInTime)
    })

    it('scrolls UP to element', async () => {
        const mockWindow = new MockWindow()
        const element = mockWindow.document.createElement('div')
        mockWindow.scrollTo(0, 10000)
        scrollToHighlight(element, mockWindow)
        await mockWindow.offestTimeMS(1)
        const scrollYAtThisPointInTime = mockWindow.scrollY
        expect(scrollYAtThisPointInTime).toBeGreaterThan(-100)
        expect(scrollYAtThisPointInTime).toBeLessThan(10000)
        await mockWindow.offestTimeMS(10)
    })

    describe ('Aborting', () => {
        [
            {eventName: 'wheel'},
            {eventName: 'mousedown'},
            {eventName: 'keydown', eventData: {key: 'Home'}},
            {eventName: 'keydown', eventData: {key: 'End'}},
            {eventName: 'keydown', eventData: {key: 'PageUp'}},
            {eventName: 'keydown', eventData: {key: 'PageDown'}},
            {eventName: 'keydown', eventData: {key: 'ArrowUp'}},
            {eventName: 'keydown', eventData: {key: 'ArrowDown'}},
        ].forEach(async (userInput) => {
            it(`aborts behavior on ${userInput.eventName}
                ${userInput.eventData ? JSON.stringify(userInput.eventData) : ''}`,
                async () => {
                    const mockWindow = new MockWindow()
                    const element = mockWindow.document.createElement('div')
                    element.offsetTop = 10000
                    let result = null
                    scrollToHighlight(element, mockWindow).then(_result => {
                        result = _result
                    })
                    mockWindow._eventListeners[userInput.eventName](userInput.eventData)
                    await mockWindow.offestTimeMS(1)
                    await new Promise(resolve => setTimeout(resolve, 0))
                    expect(result).toBe('SCROLL_ABORTED')
                })
        })
    })
})
