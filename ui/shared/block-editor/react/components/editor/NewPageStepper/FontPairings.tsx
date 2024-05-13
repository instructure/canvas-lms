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

// TODO: what I did here was add .font0, .font1, etc to style.css for the 8 font families
//        that won't work because much of the text in the editor are within instui components
//        like Heading and Text which use the instui theme to set the font-family.
//        We need to do something else (can we modify the theme for the whole editor?)

import React, {useCallback} from 'react'

import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {RadioInput} from '@instructure/ui-radio-input'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const FONTS: Record<string, string> = {
  font0: "lato, 'Helvetica Neue', Helvetica, Arial, sans-serif",
  font1: "'Balsamiq Sans', lato, 'Helvetica Neue', Helvetica, Arial, sans-serif",
  font2: "'Architects Daughter', lato, 'Helvetica Neue', Helvetica, Arial, sans-serif",
  font4: 'georgia, palatino',
  font5: 'tahoma, arial, helvetica, sans-serif',
  font6: "'times new roman', times",
  font7: "'trebuchet ms', geneva",
  font8: 'verdana, geneva',
}

type FontPairingsProps = {
  fontName: string
  onSelectFont: (fontName: string) => void
}

const FontPairings = ({fontName, onSelectFont}: FontPairingsProps) => {
  const handleSelectFont = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>) => {
      onSelectFont(event.target.value)
    },
    [onSelectFont]
  )

  const renderFont = (fontname: string) => {
    return (
      <div className={fontname} style={{marginBlockStart: '-0.5rem'}}>
        <Text size="x-large" themeOverride={{fontFamily: FONTS[fontname]}}>
          Aa
        </Text>
        ,{' '}
        <Text size="medium" themeOverride={{fontFamily: FONTS[fontname]}}>
          Aa
        </Text>
        ,{' '}
        <Text size="small" themeOverride={{fontFamily: FONTS[fontname]}}>
          Aa
        </Text>
      </div>
    )
  }
  return (
    <Flex as="div" direction="column" alignItems="center" gap="small">
      <Heading level="h3" id="font-label">
        Select Font Pairings
      </Heading>
      <View as="div" maxWidth="400px" textAlign="center">
        <Text as="p">
          Choose complimentary font pairings for your h1, h2, and paragraph text, or choose your own
          later.
        </Text>
      </View>
      <Flex direction="row" justifyItems="space-between" alignItems="center">
        <fieldset aria-label="font-label">
          <Flex direction="row" gap="large" justifyItems="center">
            <Flex.Item textAlign="start">
              <Flex direction="column" gap="medium">
                <RadioInput
                  checked={fontName === 'font0'}
                  name="font"
                  value="font0"
                  label={renderFont('font0')}
                  id="font0"
                  onChange={handleSelectFont}
                />
                <RadioInput
                  checked={fontName === 'font1'}
                  name="font"
                  value="font1"
                  label={renderFont('font1')}
                  id="font1"
                  onChange={handleSelectFont}
                />
                <RadioInput
                  checked={fontName === 'font2'}
                  name="font"
                  value="font2"
                  label={renderFont('font2')}
                  id="font2"
                  onChange={handleSelectFont}
                />
                <RadioInput
                  checked={fontName === 'font3'}
                  name="font"
                  value="font3"
                  label={renderFont('font3')}
                  id="font3"
                  onChange={handleSelectFont}
                />
              </Flex>
            </Flex.Item>
            <Flex.Item textAlign="start">
              <Flex direction="column" gap="medium">
                <RadioInput
                  checked={fontName === 'font4'}
                  name="font"
                  value="font4"
                  label={renderFont('font4')}
                  id="font4"
                  onChange={handleSelectFont}
                />
                <RadioInput
                  checked={fontName === 'font5'}
                  name="font"
                  value="font5"
                  label={renderFont('font5')}
                  id="font5"
                  onChange={handleSelectFont}
                />
                <RadioInput
                  checked={fontName === 'font6'}
                  name="font"
                  value="font6"
                  label={renderFont('font6')}
                  id="font6"
                  onChange={handleSelectFont}
                />
                <RadioInput
                  checked={fontName === 'font7'}
                  name="font"
                  value="font7"
                  label={renderFont('font7')}
                  id="font7"
                  onChange={handleSelectFont}
                />
              </Flex>
            </Flex.Item>
          </Flex>
        </fieldset>
      </Flex>
    </Flex>
  )
}

export {FontPairings}
