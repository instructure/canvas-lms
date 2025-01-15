/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import * as actions from '../filter'

describe('Filter actions', () => {
  it('change context type returns CHANGE_CONTEXT_TYPE with the new type', () => {
    expect(actions.changeContextType('new context')).toEqual({
      type: actions.CHANGE_CONTEXT_TYPE,
      payload: 'new context',
    })
  })

  it('change context id returns CHANGE_CONTEXT_ID with the new id', () => {
    expect(actions.changeContextId('19')).toEqual({
      type: actions.CHANGE_CONTEXT_ID,
      payload: '19',
    })
  })

  it('change context dispatches change type', () => {
    const dispatchSpy = jest.fn()
    const getState = () => ({
      contextType: 'user',
      contextId: '17',
    })
    actions.changeContext({
      contextType: 'course',
      contextId: '27',
    })(dispatchSpy, getState)
    expect(dispatchSpy).toHaveBeenCalledWith({type: actions.CHANGE_CONTEXT_TYPE, payload: 'course'})
  })

  it('change context dispatches change id', () => {
    const dispatchSpy = jest.fn()
    const getState = () => ({
      contextType: 'user',
      contextId: '17',
    })
    actions.changeContext({
      contextType: 'course',
      contextId: '27',
    })(dispatchSpy, getState)
    expect(dispatchSpy).toHaveBeenCalledWith({type: actions.CHANGE_CONTEXT_ID, payload: '27'})
  })

  it('change context dispatches change context', () => {
    const dispatchSpy = jest.fn()
    const getState = () => ({
      contextType: 'user',
      contextId: '17',
    })
    actions.changeContext({
      contextType: 'course',
      contextId: '27',
    })(dispatchSpy, getState)
    expect(dispatchSpy).toHaveBeenCalledWith({
      type: actions.CHANGE_CONTEXT,
      payload: {contextType: 'course', contextId: '27'},
    })
  })

  it('changeSearchString return CHANGE_SEARCH_STRING with the new string', () => {
    expect(actions.changeSearchString('new-search')).toEqual({
      type: actions.CHANGE_SEARCH_STRING,
      payload: 'new-search',
    })
  })
})
