/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import Animation from '../animation'

function mockManager() {
  return {}
}

function makeAnimation(ea) {
  const manager = mockManager()
  const animation = new Animation(ea, manager)
  return {animation, manager}
}

describe('#constructor', () => {
  it('requires at least one expected action', () => {
    expect(() => new Animation([], mockManager())).toThrow()
  })
})

describe('#acceptAction', () => {
  it('accepts an expected action', () => {
    const {animation} = makeAnimation(['some-action'])
    expect(animation.acceptAction({type: 'some-action'})).toBe(true)
  })

  it('does not accept an unexpected actions', () => {
    const {animation} = makeAnimation(['some-action'])
    expect(animation.acceptAction({type: 'some-other-action'})).toBe(false)
  })

  it('accepts when a shouldAccept method returns true', () => {
    const {animation} = makeAnimation(['some-action'])
    animation.shouldAcceptSomeAction = () => true
    expect(animation.acceptAction({type: 'some-action'})).toBe(true)
  })

  it('does not accept when a shouldAccept method return false', () => {
    const {animation} = makeAnimation(['some-action'])
    animation.shouldAcceptSomeAction = () => false
    expect(animation.acceptAction({type: 'some-action'})).toBe(false)
  })

  it('requires actions to happen in order', () => {
    const {animation} = makeAnimation(['first-action', 'second-action'])
    expect(animation.acceptAction({type: 'second-action'})).toBe(false)
  })
})

describe('#isReady', () => {
  it('determines when the animation is ready', () => {
    const {animation} = makeAnimation(['some-action'])
    animation.acceptAction({type: 'some-action'})
    expect(animation.isReady()).toBe(true)
  })

  it('determines when the animation is not ready', () => {
    const {animation} = makeAnimation(['first-action', 'second-action'])
    animation.acceptAction({type: 'first-action'})
    expect(animation.isReady()).toBe(false)
  })
})

describe('#acceptAction (2)', () => {
  it('returns the accepted actions', () => {
    const {animation} = makeAnimation(['first-action', 'second-action'])
    const theAction = {type: 'first-action', payload: 'some-data'}
    animation.acceptAction(theAction)
    expect(animation.acceptedAction('first-action')).toBe(theAction)
  })

  it('throws if an action has not been accepted yet', () => {
    const {animation} = makeAnimation(['first-action', 'second-action'])
    expect(() => animation.acceptedAction('first-action')).toThrow()
  })

  it('throws if an invalid action is requested', () => {
    const {animation} = makeAnimation(['first-action', 'second-action'])
    const theAction = {type: 'first-action', payload: 'some-data'}
    animation.acceptAction(theAction)
    expect(() => animation.acceptedAction('some-typo')).toThrow()
  })

  it('overwrites previously accepted actions', () => {
    const {animation} = makeAnimation(['first-action', 'second-action'])
    const theAction = {type: 'first-action', payload: 'some-data'}
    animation.acceptAction(theAction)
    const anotherAction = {type: 'first-action', payload: 'some-other-data'}
    animation.acceptAction(anotherAction)
    expect(animation.acceptedAction('first-action')).toBe(anotherAction)
  })
})

describe('lifecycle methods', () => {
  it('calls uiWillUpdate when invokeUiWillUpdate is called', () => {
    class Foo extends Animation {
      uiWillUpdate = jest.fn()
    }
    const foo = new Foo(['foo-action'], mockManager())
    foo.invokeUiWillUpdate()
    expect(foo.uiWillUpdate).toHaveBeenCalled()
  })

  it('does not allow recursive invokeUiWillUpdate calls', () => {
    class Foo extends Animation {
      uiWillUpdate = jest.fn(() => this.invokeUiWillUpdate())
    }
    const foo = new Foo(['foo-action'], mockManager())
    foo.invokeUiWillUpdate()
    expect(foo.uiWillUpdate).toHaveBeenCalledTimes(1)
  })

  it('calls uiDidUpdate when invokeUiDidUpdate is called', () => {
    class Foo extends Animation {
      uiDidUpdate = jest.fn()
    }
    const foo = new Foo(['foo-action'], mockManager())
    foo.invokeUiDidUpdate()
    expect(foo.uiDidUpdate).toHaveBeenCalled()
  })

  it('does not allow recursive invokeUiDidUpdate calls', () => {
    class Foo extends Animation {
      uiDidUpdate = jest.fn(() => this.invokeUiDidUpdate())
    }
    const foo = new Foo(['foo-action'], mockManager())
    foo.invokeUiDidUpdate()
    expect(foo.uiDidUpdate).toHaveBeenCalledTimes(1)
  })

  it('resets the animations data after uiDidUpdate', () => {
    class Foo extends Animation {
      uiDidUpdate = jest.fn()
    }
    const foo = new Foo(['foo-action'], mockManager())
    foo.acceptAction({type: 'foo-action'})
    expect(foo.isReady()).toBe(true)
    foo.invokeUiDidUpdate()
    expect(foo.isReady()).toBe(false)
  })
})

describe('complex stuff', () => {
  it('resets the accepted action data when a prior action is accepted again', () => {
    const {animation} = makeAnimation(['first', 'second', 'third', 'fourth'])
    const firstAction = {type: 'first'}
    animation.acceptAction(firstAction)
    const secondAction = {type: 'second'}
    animation.acceptAction(secondAction)
    const thirdAction = {type: 'third'}
    animation.acceptAction(thirdAction)
    const newSecondAction = {type: 'second', payload: 'new-data'}
    animation.acceptAction(newSecondAction)
    expect(animation.acceptedAction('first')).toBe(firstAction)
    expect(animation.acceptedAction('second')).toBe(newSecondAction)
    expect(() => animation.acceptedAction('third')).toThrow()
  })
})
