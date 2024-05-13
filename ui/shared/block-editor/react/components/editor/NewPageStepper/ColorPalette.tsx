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

import React, {useCallback} from 'react'

import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {RadioInput} from '@instructure/ui-radio-input'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const PALETTES0 = [
  ['#083B64', '#0E5F8C', '#066B65', '#FFFFFF'],
  ['#1A2729', '#0ACC94', '#E5E9F3', '#FFFBF7'],
  ['#2D3B45', '#C45E44', '#F19069', '#FBD1C4'],
  ['#611442', '#8C2C69', '#60740B', '#FFFFFF'],
  ['#2D3B45', '#F19069', '#E39DCF', '#EFB458'],
]
const PALETTES1 = [
  ['#712011', '#849EB8', '#849EB9', '#FFFFFF'],
  ['#3C4F08', '#60740B', '#611442', '#FFFFFF'],
  ['#066B65', '#274996', '#342893', '#FFFFFF'],
  ['#2D3B45', '#4097B7', '#6CC2E3', '#F8BCA9'],
  ['#2D3B45', '#6B7780', '#C7CDD1', '#FFFFFF'],
]

type ColorPaletteProps = {
  paletteId: string
  onSelectPalette: (paletteId: string) => void
}

const ColorPalette = ({paletteId, onSelectPalette}: ColorPaletteProps) => {
  const handleSelectPalette = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>) => {
      onSelectPalette(event.target.value)
    },
    [onSelectPalette]
  )

  const renderPalette = (palette: string[], paletteName: string) => {
    return (
      <div className="colorPalette">
        {palette.map((color: string) => {
          return (
            <div
              key={`${paletteName}-${color}`}
              className="colorPalette__color"
              style={{
                backgroundColor: color,
              }}
            />
          )
        })}
      </div>
    )
  }
  return (
    <Flex as="div" direction="column" alignItems="center" gap="small">
      <Heading level="h3" id="palette-label">
        Select a Color Palette
      </Heading>
      <View as="div" maxWidth="400px" textAlign="center">
        <Text as="p">
          Theme your page with a preselected, accessibility compliant color palette.
        </Text>
      </View>
      <Flex direction="row" justifyItems="space-between" alignItems="center">
        <fieldset aria-label="palette-label">
          <Flex direction="row" gap="large" justifyItems="center">
            <Flex.Item textAlign="start">
              <Flex direction="column" gap="small">
                {PALETTES0.map((palette, index) => {
                  const paletteX = `palette${index}`
                  return (
                    <RadioInput
                      key={paletteX}
                      checked={paletteId === paletteX}
                      name="palette"
                      value={paletteX}
                      label={renderPalette(palette, paletteX)}
                      id={paletteX}
                      onChange={handleSelectPalette}
                    />
                  )
                })}
              </Flex>
            </Flex.Item>
            <Flex.Item textAlign="start">
              <Flex direction="column" gap="small">
                {PALETTES1.map((palette, index) => {
                  const paletteX = `palette${index + 5}`
                  return (
                    <RadioInput
                      key={paletteX}
                      checked={paletteId === paletteX}
                      name="palette"
                      value={paletteX}
                      label={renderPalette(palette, paletteX)}
                      id={paletteX}
                      onChange={handleSelectPalette}
                    />
                  )
                })}
              </Flex>
            </Flex.Item>
          </Flex>
        </fieldset>
      </Flex>
    </Flex>
  )
}

export {ColorPalette}
