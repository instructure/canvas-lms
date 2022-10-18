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

import {useState} from 'react'

import {scaleForHeight, scaleForWidth} from '../DimensionUtils'

function normalizedNumber(number) {
  if (number == null) {
    return null
  }

  return Number.isFinite(number) ? Math.round(number) : NaN
}

function parseAsInteger(inputString) {
  if (inputString.trim() === '') {
    return null
  }

  const number = Number.parseFloat(inputString, 10)
  return Number.isFinite(number) ? Math.round(number) : NaN
}

function inputValueFor(initialNumber) {
  return Number.isFinite(initialNumber) ? `${initialNumber}` : ''
}

export default function useDimensionsState(initialDimensions, constraints) {
  const {
    appliedHeight,
    appliedWidth,
    appliedPercentage,
    naturalHeight,
    naturalWidth,
    usePercentageUnits,
  } = initialDimensions
  const {minHeight, minWidth, minPercentage} = constraints

  const initialNumericValues = {
    height: usePercentageUnits ? naturalHeight : appliedHeight || naturalHeight,
    width: usePercentageUnits ? naturalWidth : appliedWidth || naturalWidth,
    percentage: appliedPercentage || 100,
  }

  const [dimensions, setDimensions] = useState({
    usePercentageUnits,
    inputHeight: inputValueFor(initialNumericValues.height),
    inputWidth: inputValueFor(initialNumericValues.width),
    inputPercentage: inputValueFor(initialNumericValues.percentage),
    numericHeight: initialNumericValues.height,
    numericWidth: initialNumericValues.width,
    numericPercentage: initialNumericValues.percentage,
  })

  const currentNumericValues = {
    height: dimensions.numericHeight,
    width: dimensions.numericWidth,
    percentage: dimensions.numericPercentage,
  }

  const dimensionMinimums = {height: minHeight, width: minWidth, percentage: minPercentage}
  const dimensionScaleFns = {
    height: scaleForHeight,
    width: scaleForWidth,
  }

  function updateDimensions(attributes) {
    setDimensions({
      ...dimensions,
      ...attributes,
      numericHeight: normalizedNumber(attributes.numericHeight),
      numericWidth: normalizedNumber(attributes.numericWidth),
      numericPercentage: normalizedNumber(attributes.numericPercentage),
    })
  }

  function scaleDimensions(dimensionName, number, scaleConstraints) {
    let width, height, percentage
    if (dimensionName === 'percentage') {
      width = naturalWidth
      height = naturalHeight
      percentage = number
    } else {
      const scaleFn = dimensionScaleFns[dimensionName]
      const scaledDimensions = scaleFn(naturalWidth, naturalHeight, number, scaleConstraints)
      width = scaledDimensions.width
      height = scaledDimensions.height
      percentage = initialNumericValues.percentage
    }
    return {width, height, percentage}
  }

  function setNumericDimension(dimensionName, number) {
    const {height, width, percentage} = scaleDimensions(dimensionName, number, constraints)

    updateDimensions({
      numericHeight: height,
      numericWidth: width,
      numericPercentage: percentage,
      inputHeight: inputValueFor(height),
      inputWidth: inputValueFor(width),
      inputPercentage: inputValueFor(percentage),
    })
  }

  function setDimensionValue(dimensionName, value) {
    const number = parseAsInteger(value)
    const {height, width, percentage} = scaleDimensions(dimensionName, number)

    updateDimensions({
      numericHeight: height,
      numericWidth: width,
      numericPercentage: percentage,
      inputHeight: dimensionName === 'height' ? value : inputValueFor(height),
      inputWidth: dimensionName === 'width' ? value : inputValueFor(width),
      inputPercentage: dimensionName === 'percentage' ? value : inputValueFor(percentage),
    })
  }

  function offsetDimension(dimensionName, offset) {
    const minValue = dimensionMinimums[dimensionName]

    const initialNumber = initialNumericValues[dimensionName]
    const numericValue = currentNumericValues[dimensionName]

    if (numericValue != null && !Number.isFinite(numericValue)) {
      return
    }

    const newNumber =
      numericValue == null
        ? initialNumber + offset
        : Math.max(minValue, Math.floor(numericValue + offset))

    setNumericDimension(dimensionName, newNumber)
  }

  const widthState = {
    inputValue: dimensions.inputWidth,

    addOffset(offset) {
      offsetDimension('width', offset)
    },

    setInputValue(value) {
      setDimensionValue('width', value)
    },
  }

  const heightState = {
    inputValue: dimensions.inputHeight,

    addOffset(offset) {
      offsetDimension('height', offset)
    },

    setInputValue(value) {
      setDimensionValue('height', value)
    },
  }

  const percentageState = {
    inputValue: dimensions.inputPercentage,

    addOffset(offset) {
      offsetDimension('percentage', offset)
    },

    setInputValue(value) {
      setDimensionValue('percentage', value)
    },
  }

  const handleUsePercentageUnitsChange = value => {
    setDimensions({...dimensions, usePercentageUnits: value})
  }

  const isNumeric = dimensions.usePercentageUnits
    ? Number.isFinite(dimensions.numericPercentage)
    : [dimensions.numericHeight, dimensions.numericWidth].every(Number.isFinite)
  const isAtLeastMinimums = dimensions.usePercentageUnits
    ? dimensions.numericPercentage >= minPercentage
    : dimensions.numericHeight >= minHeight && dimensions.numericWidth >= minWidth

  return {
    widthState,
    heightState,
    percentageState,
    isAtLeastMinimums,
    isNumeric,
    width: dimensions.numericWidth,
    height: dimensions.numericHeight,
    percentage: dimensions.numericPercentage,
    usePercentageUnits: dimensions.usePercentageUnits,
    setUsePercentageUnits: handleUsePercentageUnitsChange,
    isValid: isAtLeastMinimums && isNumeric,
  }
}
