/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {
  createAnalyticPropsGenerator,
  DATA_ANALYTICS_ATTRIBUTE,
  setAnalyticPropsOnRef,
} from '../../util/analytics'
import type {AnalyticProps} from '../../util/analytics'

const ANALYTICS_PREFIX = 'testPrefix'
const ANALYTICS_TEST_VALUE = 'testValue'

// this test suite uses plain JavaScript for demonstration purposes only
// in Canvas, you would typically use JSX and React achieve similar results
describe('analytics.ts', () => {
  let divElement: HTMLDivElement

  beforeEach(() => {
    // isolate this describe block to use a new div element
    divElement = document.createElement('div')
  })

  describe('createAnalyticPropsGenerator()', () => {
    // set attributes on an HTMLElement with values from an object
    // this mimics the spreading of analytic attributes onto a JSX element/component
    // note that this logic is functionally the same as setAnalyticPropsOnRef()
    // duplicating for the sake of isolating createAnalyticPropsGenerator() functionality
    // additionally, this logic alleviates the need to use React/JSX in this test suite
    const simulateSpread = (element: HTMLElement, attributes: AnalyticProps) => {
      for (const [key, value] of Object.entries(attributes)) {
        element.setAttribute(key, value)
      }
    }

    it('should set the data-analytics attribute correctly with prefix and default delimiter', () => {
      // generate attribute and store its value
      const analyticProps = createAnalyticPropsGenerator(ANALYTICS_PREFIX)(ANALYTICS_TEST_VALUE)

      // set the attribute on divElement
      simulateSpread(divElement, analyticProps)

      // assert that the attribute was set correctly
      expect(divElement).toHaveAttribute(
        DATA_ANALYTICS_ATTRIBUTE,
        `${ANALYTICS_PREFIX}${ANALYTICS_TEST_VALUE}`
      )
    })

    it('should set the data-analytics attribute correctly with custom delimiter', () => {
      const customDelimiter = '_'
      const analyticProps = createAnalyticPropsGenerator(
        ANALYTICS_PREFIX,
        customDelimiter
      )(ANALYTICS_TEST_VALUE)

      simulateSpread(divElement, analyticProps)

      expect(divElement).toHaveAttribute(
        DATA_ANALYTICS_ATTRIBUTE,
        `${ANALYTICS_PREFIX}${customDelimiter}${ANALYTICS_TEST_VALUE}`
      )
    })

    it('handles empty prefix and delimiter correctly', () => {
      const analyticProps = createAnalyticPropsGenerator('', '')(ANALYTICS_TEST_VALUE)

      simulateSpread(divElement, analyticProps)

      expect(divElement).toHaveAttribute(DATA_ANALYTICS_ATTRIBUTE, ANALYTICS_TEST_VALUE)
    })

    it('handles undefined prefix correctly', () => {
      const analyticProps = createAnalyticPropsGenerator()(ANALYTICS_TEST_VALUE)

      simulateSpread(divElement, analyticProps)

      expect(divElement).toHaveAttribute(DATA_ANALYTICS_ATTRIBUTE, ANALYTICS_TEST_VALUE)
    })
  })

  describe('setAnalyticPropsOnRef()', () => {
    let testProps: AnalyticProps

    beforeEach(() => {
      // generate test props for all test cases in this describe block
      testProps = createAnalyticPropsGenerator(ANALYTICS_PREFIX)(ANALYTICS_TEST_VALUE)
    })

    it('should set the analytic props correctly', () => {
      setAnalyticPropsOnRef(divElement, testProps)

      expect(divElement).toHaveAttribute(
        DATA_ANALYTICS_ATTRIBUTE,
        `${ANALYTICS_PREFIX}${ANALYTICS_TEST_VALUE}`
      )
    })

    it('does not throw an error if ref is null', () => {
      const minimalProps: AnalyticProps = {[DATA_ANALYTICS_ATTRIBUTE]: ''}

      expect(() => setAnalyticPropsOnRef(null, minimalProps)).not.toThrow()
    })

    it('works for different element types', () => {
      const spanElement = document.createElement('span')

      setAnalyticPropsOnRef(spanElement, testProps)

      expect(spanElement).toHaveAttribute(
        DATA_ANALYTICS_ATTRIBUTE,
        `${ANALYTICS_PREFIX}${ANALYTICS_TEST_VALUE}`
      )
    })

    it('overwrites existing properties', () => {
      divElement.setAttribute(DATA_ANALYTICS_ATTRIBUTE, 'oldValue')

      setAnalyticPropsOnRef(divElement, testProps)

      expect(divElement).toHaveAttribute(
        DATA_ANALYTICS_ATTRIBUTE,
        `${ANALYTICS_PREFIX}${ANALYTICS_TEST_VALUE}`
      )
    })

    it('should set multiple properties correctly', () => {
      const multipleProps = {
        [DATA_ANALYTICS_ATTRIBUTE]: 'value1',
        anotherAttribute: 'value2',
      }

      setAnalyticPropsOnRef(divElement, multipleProps)

      expect(divElement).toHaveAttribute(DATA_ANALYTICS_ATTRIBUTE, 'value1')
      expect(divElement).toHaveAttribute('anotherAttribute', 'value2')
    })

    it('works for multiple types of HTML elements', () => {
      const elementTypes = ['button', 'a', 'span']

      elementTypes.forEach(type => {
        const element = document.createElement(type)

        setAnalyticPropsOnRef(element, testProps)

        expect(element).toHaveAttribute(
          DATA_ANALYTICS_ATTRIBUTE,
          `${ANALYTICS_PREFIX}${ANALYTICS_TEST_VALUE}`
        )
      })
    })

    it('should not set attributes if analyticProps is empty', () => {
      const minimalProps: AnalyticProps = {[DATA_ANALYTICS_ATTRIBUTE]: ''}

      setAnalyticPropsOnRef(divElement, minimalProps)

      expect(divElement.getAttributeNames()).toHaveLength(1)
      expect(divElement).toHaveAttribute(DATA_ANALYTICS_ATTRIBUTE, '')
    })
  })
})
