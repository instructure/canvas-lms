/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2018 @bokuweb
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

// The bulk of his code was copied from craft.js.

export const isPercentage = (val: string) => typeof val === 'string' && val.indexOf('%') > -1

export const percentToPx = (value: any, comparativeValue: number) => {
  if (value.indexOf('px') > -1 || value === 'auto' || !comparativeValue) return value
  const percent = parseInt(value, 10)
  return (percent / 100) * comparativeValue + 'px'
}
export const pxToPercent = (value: any, comparativeValue: number) => {
  const val = (Math.abs(value) / comparativeValue) * 100
  if (value < 0) return -1 * val
  else return Math.round(val)
}
export const getElementDimensions = (element: HTMLElement): SizeType => {
  const computedStyle = getComputedStyle(element)

  let height = element.clientHeight,
    width = element.clientWidth // width with padding

  height -= parseFloat(computedStyle.paddingTop) + parseFloat(computedStyle.paddingBottom)
  width -= parseFloat(computedStyle.paddingLeft) + parseFloat(computedStyle.paddingRight)

  return {
    width,
    height,
  }
}

export type SizeType = {
  width: number
  height: number
}
