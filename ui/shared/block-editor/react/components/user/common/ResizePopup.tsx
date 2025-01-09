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

import React, {useCallback, useEffect, useState} from 'react'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Button, IconButton} from '@instructure/ui-buttons'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {RangeInput} from '@instructure/ui-range-input'
import {Popover} from '@instructure/ui-popover'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {IconResize} from '../../../assets/internal-icons'
import {getAspectRatio} from '../../../utils'
// @ts-expect-error
import type {ImageSizeVariant} from '../blocks/ImageBlock/types'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

type ResizePopupProps = {
  width: number
  height: number
  maintainAspectRatio: boolean
  sizeVariant: ImageSizeVariant
  onChange: (width: number, height: number, szVariant: ImageSizeVariant) => void
}

const ResizePopup = ({
  width,
  height,
  maintainAspectRatio,
  sizeVariant,
  onChange,
}: ResizePopupProps) => {
  const [widthValue, setWidthValue] = useState<number>(width)
  const [heightValue, setHeightValue] = useState<number>(height)
  const [aspectRatio, setAspectRatio] = useState<number>(getAspectRatio(width, height))
  const [sizeVariantValue, setSizeVariantValue] = useState<ImageSizeVariant>(sizeVariant)
  const [isShowingContent, setIsShowingContent] = useState(false)

  useEffect(() => {
    setWidthValue(width)
    setHeightValue(height)
    setAspectRatio(getAspectRatio(width, height))
  }, [width, height])

  const handleShowContent = useCallback(() => {
    setWidthValue(width)
    setHeightValue(height)
    setIsShowingContent(true)
  }, [height, width])

  const handleHideContent = useCallback(() => {
    setIsShowingContent(false)
  }, [])

  const handleChangeWidth = useCallback(
    (value: number | string) => {
      const w = typeof value === 'number' ? value : parseInt(value, 10)
      setWidthValue(w)
      if (maintainAspectRatio) {
        const h = Math.round(w / aspectRatio)
        setHeightValue(h)
      }
    },
    [aspectRatio, maintainAspectRatio],
  )

  const handleChangeHeight = useCallback(
    (value: number | string) => {
      const h = typeof value === 'number' ? value : parseInt(value, 10)
      setHeightValue(h)
      if (maintainAspectRatio) {
        const w = Math.round(h * aspectRatio)
        setWidthValue(w)
      }
    },
    [aspectRatio, maintainAspectRatio],
  )

  const handleSizeVariantChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>, value: string) => {
      setSizeVariantValue(value as ImageSizeVariant)
    },
    [],
  )

  const setImageSize = useCallback(() => {
    onChange(widthValue, heightValue, sizeVariantValue)
    setIsShowingContent(false)
  }, [heightValue, onChange, sizeVariantValue, widthValue])

  return (
    <Popover
      renderTrigger={
        <IconButton
          size="small"
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Image Size')}
          title={I18n.t('Image Size')}
        >
          <IconResize size="x-small" />
        </IconButton>
      }
      isShowingContent={isShowingContent}
      onShowContent={handleShowContent}
      onHideContent={handleHideContent}
      on="click"
      screenReaderLabel={I18n.t('Popover Dialog Example')}
      shouldContainFocus={true}
      shouldReturnFocus={true}
      shouldCloseOnDocumentClick={true}
    >
      <View as="div" margin="small">
        <RadioInputGroup
          description={I18n.t('Size by:')}
          onChange={handleSizeVariantChange}
          name="size-variant"
          defaultValue={sizeVariant}
        >
          <RadioInput label={I18n.t('Pixel')} value="pixel" />
          <RadioInput label={I18n.t('Percent')} value="percent" />
          <RadioInput label={I18n.t('None')} value="none" />
        </RadioInputGroup>

        <FormFieldGroup
          description={<ScreenReaderContent>Image size</ScreenReaderContent>}
          rowSpacing="small"
          layout="stacked"
        >
          <RangeInput
            label={I18n.t('Width')}
            value={Math.round(widthValue)}
            width="15rem"
            min={1}
            max={sizeVariantValue === 'percent' ? 100 : window.innerWidth}
            step={10}
            size="small"
            thumbVariant="accessible"
            onChange={handleChangeWidth}
          />
          <RangeInput
            label={I18n.t('Height')}
            value={Math.round(heightValue)}
            width="15rem"
            min={1}
            max={sizeVariant === 'percent' ? 100 : window.innerWidth / aspectRatio}
            step={10}
            size="small"
            thumbVariant="accessible"
            onChange={handleChangeHeight}
          />
        </FormFieldGroup>
        <View as="div" textAlign="end" margin="x-small 0 0 0">
          <Button onClick={setImageSize}>{I18n.t('Set')}</Button>
        </View>
      </View>
    </Popover>
  )
}

export {ResizePopup}
