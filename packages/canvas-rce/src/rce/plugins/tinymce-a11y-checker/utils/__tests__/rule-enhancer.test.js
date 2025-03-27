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

import {enhanceRule, enhanceRules} from '../rule-enhancer'
import {notifyTinyMCE} from '../dom'

jest.mock('../dom', () => ({
  notifyTinyMCE: jest.fn(),
}))

describe('enhanceRule', () => {
  let mockRule
  let mockElement
  let mockData

  beforeEach(() => {
    notifyTinyMCE.mockClear()
    mockRule = {
      id: 'test-rule',
      update: jest.fn().mockReturnValue(true),
    }
    mockElement = document.createElement('div')
    mockData = {value: 'test-data'}
  })

  test('returns the original rule if it does not have an update method', () => {
    const ruleWithoutUpdate = {id: 'no-update-rule'}
    const enhanced = enhanceRule(ruleWithoutUpdate)
    expect(enhanced).toBe(ruleWithoutUpdate)
  })

  test('returns a new rule object, not the original', () => {
    const enhanced = enhanceRule(mockRule)
    expect(enhanced).not.toBe(mockRule)
    expect(enhanced.id).toBe(mockRule.id)
  })

  test('enhanced rule has an update method', () => {
    const enhanced = enhanceRule(mockRule)
    expect(typeof enhanced.update).toBe('function')
  })

  test('enhanced update method calls the original update method with the same arguments', () => {
    const enhanced = enhanceRule(mockRule)
    enhanced.update(mockElement, mockData)
    expect(mockRule.update).toHaveBeenCalledWith(mockElement, mockData)
  })

  test('enhanced update method calls notifyTinyMCE after the original update', () => {
    const enhanced = enhanceRule(mockRule)
    enhanced.update(mockElement, mockData)
    expect(notifyTinyMCE).toHaveBeenCalled()
  })

  test('enhanced update method returns the result from the original update method', () => {
    const enhanced = enhanceRule(mockRule)
    const result = enhanced.update(mockElement, mockData)
    expect(result).toBe(true)
  })

  test('enhanced update method preserves the execution order: original update then notify', () => {
    const callOrder = []
    mockRule.update = jest.fn(() => {
      callOrder.push('original update')
      return true
    })
    notifyTinyMCE.mockImplementation(() => {
      callOrder.push('notify TinyMCE')
    })
    const enhanced = enhanceRule(mockRule)
    enhanced.update(mockElement, mockData)
    expect(callOrder).toEqual(['original update', 'notify TinyMCE'])
  })

  test('accepts a custom enhancement method instead of notifyTinyMCE', () => {
    const customEnhance = jest.fn()
    const enhanced = enhanceRule(mockRule, customEnhance)

    enhanced.update(mockElement, mockData)

    expect(customEnhance).toHaveBeenCalled()
    expect(notifyTinyMCE).not.toHaveBeenCalled()
  })

  test('uses the provided custom enhancement method when updating', () => {
    const customEnhance = jest.fn()
    const enhanced = enhanceRule(mockRule, customEnhance)

    enhanced.update(mockElement, mockData)

    expect(mockRule.update).toHaveBeenCalledWith(mockElement, mockData)
    expect(customEnhance).toHaveBeenCalled()
  })
})

describe('enhanceRules', () => {
  test('returns an array of the same length as the input', () => {
    const rules = [
      {id: 'rule1', update: jest.fn()},
      {id: 'rule2', update: jest.fn()},
      {id: 'rule3'}, // No update method
    ]
    const enhanced = enhanceRules(rules)

    expect(enhanced).toHaveLength(rules.length)
  })

  test('enhances each rule that has an update method', () => {
    const rules = [
      {id: 'rule1', update: jest.fn()},
      {id: 'rule2', update: jest.fn()},
      {id: 'rule3'}, // No update method
    ]
    const enhanced = enhanceRules(rules)

    expect(enhanced[0]).not.toBe(rules[0])
    expect(enhanced[1]).not.toBe(rules[1])
    expect(enhanced[2]).toBe(rules[2])
  })

  test('calls notifyTinyMCE when any enhanced rule is updated', () => {
    const rules = [
      {id: 'rule1', update: jest.fn()},
      {id: 'rule2', update: jest.fn()},
    ]
    const enhanced = enhanceRules(rules)
    const mockElement = document.createElement('div')
    const mockData = {value: 'test'}

    notifyTinyMCE.mockClear()
    enhanced[0].update(mockElement, mockData)
    enhanced[1].update(mockElement, mockData)
    expect(notifyTinyMCE).toHaveBeenCalledTimes(2)
  })

  test('returns empty array if input is empty', () => {
    const enhanced = enhanceRules([])
    expect(enhanced).toEqual([])
  })

  test('accepts a custom enhancement method and passes it to each rule', () => {
    const rules = [
      {id: 'rule1', update: jest.fn()},
      {id: 'rule2', update: jest.fn()},
    ]

    const customEnhance = jest.fn()
    const enhanced = enhanceRules(rules, customEnhance)

    notifyTinyMCE.mockClear()
    customEnhance.mockClear()

    const mockElement = document.createElement('div')
    const mockData = {value: 'test'}

    enhanced[0].update(mockElement, mockData)
    enhanced[1].update(mockElement, mockData)

    expect(customEnhance).toHaveBeenCalledTimes(2)
    expect(notifyTinyMCE).not.toHaveBeenCalled()
  })

  test('uses the default notifyTinyMCE when no custom method is provided', () => {
    const rules = [
      {id: 'rule1', update: jest.fn()},
      {id: 'rule2', update: jest.fn()},
    ]

    const enhanced = enhanceRules(rules)

    notifyTinyMCE.mockClear()

    const mockElement = document.createElement('div')
    const mockData = {value: 'test'}

    enhanced[0].update(mockElement, mockData)

    expect(notifyTinyMCE).toHaveBeenCalled()
  })
})
