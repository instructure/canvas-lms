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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {ColorContrast, ColorMixer} from '@instructure/ui-color-picker'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {useMemo} from 'react'

const I18n = createI18nScope('block_content_editor')

export type ColorPickerPopoverProps = {
  value: string
  valueLabel: string
  onChange: (value: string) => void
  baseColor: string
  baseColorLabel: string
  onAdd: () => void
  onClose: () => void
  maxHeight: number | string
}

export const ColorPickerPopover = (props: ColorPickerPopoverProps) => {
  const valueWithoutAlpha = useMemo(() => {
    const hexWithAlphaLength = 9
    const fullOpaque = 'FF'
    const value = props.value
    return value.length === hexWithAlphaLength && value.slice(-2).toUpperCase() === fullOpaque
      ? value.slice(0, -2)
      : value
  }, [props.value])

  return (
    <Flex direction="column">
      <View padding="small" maxHeight={props.maxHeight} overflowY="auto">
        <ColorMixer
          value={props.value}
          onChange={props.onChange}
          withAlpha={true}
          rgbRedInputScreenReaderLabel={I18n.t('Input field for red')}
          rgbGreenInputScreenReaderLabel={I18n.t('Input field for green')}
          rgbBlueInputScreenReaderLabel={I18n.t('Input field for blue')}
          rgbAlphaInputScreenReaderLabel={I18n.t('Input field for alpha')}
          colorSliderNavigationExplanationScreenReaderLabel={I18n.t(
            `You are on a color slider. To navigate the slider left or right, use the 'A' and 'D' buttons respectively`,
          )}
          alphaSliderNavigationExplanationScreenReaderLabel={I18n.t(
            `You are on an alpha slider. To navigate the slider left or right, use the 'A' and 'D' buttons respectively`,
          )}
          colorPaletteNavigationExplanationScreenReaderLabel={I18n.t(
            `You are on a color palette. To navigate on the palette up, left, down or right, use the 'W', 'A', 'S' and 'D' buttons respectively`,
          )}
        />
        <hr />
        <ColorContrast
          firstColor={props.baseColor}
          secondColor={valueWithoutAlpha}
          label={I18n.t('Contrast Ratio')}
          successLabel={I18n.t('PASS')}
          failureLabel={I18n.t('FAIL')}
          normalTextLabel={I18n.t('Normal Text')}
          largeTextLabel={I18n.t('Large Text')}
          graphicsTextLabel={I18n.t('Graphics Text')}
          firstColorLabel={props.baseColorLabel}
          secondColorLabel={props.valueLabel}
        />
      </View>
      <View background="secondary" padding="small" borderRadius="0 0 medium medium">
        <Flex justifyItems="end" gap="small">
          <Button onClick={props.onClose} color="secondary">
            {I18n.t('Close')}
          </Button>
          <Button onClick={props.onAdd} color="primary">
            {I18n.t('Apply')}
          </Button>
        </Flex>
      </View>
    </Flex>
  )
}
