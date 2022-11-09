//
// Copyright (C) 2021 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import BrandableCSS from '..'
import stubEnv from '@canvas/stub-env'

describe('@canvas/brandable-css#loadStylesheet', () => {
  stubEnv({
    ASSET_HOST: 'http://cdn.example.com',
  })

  it('loads', () => {
    const bundleId = 'bundles/foo'
    const fingerprint = 'asdf1234'

    BrandableCSS.loadStylesheet(bundleId, {combinedChecksum: fingerprint})

    expect(document.head.querySelector('link[rel="stylesheet"]:last-of-type').href).toEqual(
      `http://cdn.example.com/dist/brandable_css/new_styles_normal_contrast/${bundleId}-${fingerprint}.css`
    )
  })
})

describe('@canvas/brandable-css#loadStylesheetForJST', () => {
  const subject = BrandableCSS.loadStylesheetForJST

  let loadStylesheet

  beforeEach(() => {
    loadStylesheet = jest.spyOn(BrandableCSS, 'loadStylesheet').mockImplementation(() => null)
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('works', () => {
    jest.spyOn(BrandableCSS, 'getHandlebarsIndex').mockImplementation(() => [
      ['first_variant', 'second_variant'],
      {
        fa0: ['xxx'],
      },
    ])

    subject({id: 'fa0', bundle: 'asdfasdf'})

    expect(loadStylesheet).toHaveBeenCalled()
    expect(loadStylesheet).toHaveBeenCalledWith('asdfasdf', {
      combinedChecksum: 'xxx',
      includesNoVariables: true,
    })
  })

  it('resolves references', () => {
    jest.spyOn(BrandableCSS, 'getCssVariant').mockImplementation(() => 'second_variant')
    jest
      .spyOn(BrandableCSS, 'getHandlebarsIndex')
      .mockImplementation(() => [['first_variant', 'second_variant'], {fa0: ['xxx', 0]}])

    subject({id: 'fa0', bundle: 'asdfasdf'})

    expect(loadStylesheet).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({
        combinedChecksum: 'xxx',
      })
    )
  })

  it('marks as "includesNoVariables" if only one checksum is provided', () => {
    jest.spyOn(BrandableCSS, 'getCssVariant').mockImplementation(() => 'second_variant')
    jest
      .spyOn(BrandableCSS, 'getHandlebarsIndex')
      .mockImplementation(() => [['first_variant', 'second_variant'], {fa0: ['xxx']}])

    subject({id: 'fa0', bundle: 'asdfasdf'})

    expect(loadStylesheet).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({
        includesNoVariables: true,
      })
    )
  })

  it('throws if bundle has no mapping', () => {
    expect(() => subject({id: 'asdfasdf', bundle: 'asdfasdf'})).toThrow(
      /requested to load stylesheet for template.*but no mapping is available/
    )
  })
})

describe('@canvas/brandable-css#urlFor', () => {
  const subject = BrandableCSS.urlFor
  const bundleId = 'bundles/foo'
  const fingerprint = 'asdf1234'
  const env = stubEnv({})

  test('should have right default', () => {
    expect(subject(bundleId, {combinedChecksum: fingerprint})).toEqual(
      `/dist/brandable_css/new_styles_normal_contrast/${bundleId}-${fingerprint}.css`
    )
  })

  test('should handle no_variables correctly', () => {
    expect(
      subject(bundleId, {
        combinedChecksum: fingerprint,
        includesNoVariables: true,
      })
    ).toEqual(`/dist/brandable_css/no_variables/${bundleId}-${fingerprint}.css`)
  })

  test('should pick up ENV settings', () => {
    env.ASSET_HOST = 'http://cdn.example.com'
    env.use_high_contrast = false

    expect(subject(bundleId, {combinedChecksum: fingerprint})).toEqual(
      `http://cdn.example.com/dist/brandable_css/new_styles_normal_contrast/${bundleId}-${fingerprint}.css`
    )
  })

  test('should pick up ENV settings & high contrast feature flag', () => {
    env.ASSET_HOST = 'http://cdn.example.com'
    env.use_high_contrast = true

    expect(subject(bundleId, {combinedChecksum: fingerprint})).toEqual(
      `http://cdn.example.com/dist/brandable_css/new_styles_high_contrast/${bundleId}-${fingerprint}.css`
    )
  })
})
