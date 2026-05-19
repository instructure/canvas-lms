/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import fetchWindowSize from '../lti.fetchWindowSize'

describe('lti.fetchWindowSize handler', () => {
  let responseMessages: {sendResponse: ReturnType<typeof vi.fn>}

  beforeEach(() => {
    responseMessages = {sendResponse: vi.fn()}
    vi.spyOn($.fn, 'height').mockReturnValue(0)
  })

  afterEach(() => {
    vi.restoreAllMocks()
    document.body.innerHTML = ''
  })

  it('returns footer: 0 and assignment_footer: 0 when no footer elements are present', () => {
    fetchWindowSize({responseMessages} as any)
    expect(responseMessages.sendResponse).toHaveBeenCalledWith(
      expect.objectContaining({footer: 0, assignment_footer: 0}),
    )
  })

  it('includes only #fixed_bottom height in footer', () => {
    document.body.innerHTML = '<div id="fixed_bottom"></div>'
    vi.spyOn($.fn, 'height').mockImplementation(function (this: JQuery) {
      if (this.attr('id') === 'fixed_bottom') return 40
      return 0
    })

    fetchWindowSize({responseMessages} as any)
    expect(responseMessages.sendResponse).toHaveBeenCalledWith(
      expect.objectContaining({footer: 40, assignment_footer: 0}),
    )
  })

  it('includes #sequence_footer height in assignment_footer', () => {
    document.body.innerHTML = '<div id="sequence_footer"></div>'
    vi.spyOn($.fn, 'height').mockImplementation(function (this: JQuery) {
      if (this.attr('id') === 'sequence_footer') return 60
      return 0
    })

    fetchWindowSize({responseMessages} as any)
    expect(responseMessages.sendResponse).toHaveBeenCalledWith(
      expect.objectContaining({footer: 0, assignment_footer: 60}),
    )
  })

  it('includes #module_sequence_footer height in assignment_footer', () => {
    document.body.innerHTML = '<div id="module_sequence_footer"></div>'
    vi.spyOn($.fn, 'height').mockImplementation(function (this: JQuery) {
      if (this.attr('id') === 'module_sequence_footer') return 50
      return 0
    })

    fetchWindowSize({responseMessages} as any)
    expect(responseMessages.sendResponse).toHaveBeenCalledWith(
      expect.objectContaining({footer: 0, assignment_footer: 50}),
    )
  })

  it('includes #enhanced-rubric-assignment-edit-mount-point height in assignment_footer', () => {
    document.body.innerHTML = '<div id="enhanced-rubric-assignment-edit-mount-point"></div>'
    vi.spyOn($.fn, 'height').mockImplementation(function (this: JQuery) {
      if (this.attr('id') === 'enhanced-rubric-assignment-edit-mount-point') return 80
      return 0
    })

    fetchWindowSize({responseMessages} as any)
    expect(responseMessages.sendResponse).toHaveBeenCalledWith(
      expect.objectContaining({footer: 0, assignment_footer: 80}),
    )
  })

  it('includes #assignment-rubric-section height in assignment_footer', () => {
    document.body.innerHTML = '<div id="assignment-rubric-section"></div>'
    vi.spyOn($.fn, 'height').mockImplementation(function (this: JQuery) {
      if (this.attr('id') === 'assignment-rubric-section') return 70
      return 0
    })

    fetchWindowSize({responseMessages} as any)
    expect(responseMessages.sendResponse).toHaveBeenCalledWith(
      expect.objectContaining({footer: 0, assignment_footer: 70}),
    )
  })

  it('includes #peer-review-assignment-widget-mount-point height in assignment_footer', () => {
    document.body.innerHTML = '<div id="peer-review-assignment-widget-mount-point"></div>'
    vi.spyOn($.fn, 'height').mockImplementation(function (this: JQuery) {
      if (this.attr('id') === 'peer-review-assignment-widget-mount-point') return 90
      return 0
    })

    fetchWindowSize({responseMessages} as any)
    expect(responseMessages.sendResponse).toHaveBeenCalledWith(
      expect.objectContaining({footer: 0, assignment_footer: 90}),
    )
  })

  it('includes #enhanced-rubric-self-assessment-edit height in assignment_footer', () => {
    document.body.innerHTML = '<div id="enhanced-rubric-self-assessment-edit"></div>'
    vi.spyOn($.fn, 'height').mockImplementation(function (this: JQuery) {
      if (this.attr('id') === 'enhanced-rubric-self-assessment-edit') return 100
      return 0
    })

    fetchWindowSize({responseMessages} as any)
    expect(responseMessages.sendResponse).toHaveBeenCalledWith(
      expect.objectContaining({footer: 0, assignment_footer: 100}),
    )
  })

  it('keeps footer and assignment_footer independent on assignment pages', () => {
    document.body.innerHTML = `
      <div id="fixed_bottom"></div>
      <div id="sequence_footer"></div>
      <div id="module_sequence_footer"></div>
      <div id="enhanced-rubric-assignment-edit-mount-point"></div>
      <div id="assignment-rubric-section"></div>
      <div id="peer-review-assignment-widget-mount-point"></div>
      <div id="enhanced-rubric-self-assessment-edit"></div>
    `
    vi.spyOn($.fn, 'height').mockImplementation(function (this: JQuery) {
      const id = this.attr('id')
      if (id === 'fixed_bottom') return 40
      if (id === 'sequence_footer') return 60
      if (id === 'module_sequence_footer') return 50
      if (id === 'enhanced-rubric-assignment-edit-mount-point') return 80
      if (id === 'assignment-rubric-section') return 70
      if (id === 'peer-review-assignment-widget-mount-point') return 90
      if (id === 'enhanced-rubric-self-assessment-edit') return 100
      return 0
    })

    fetchWindowSize({responseMessages} as any)
    expect(responseMessages.sendResponse).toHaveBeenCalledWith(
      expect.objectContaining({footer: 40, assignment_footer: 450}),
    )
  })
})
