/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useReducer, useState, useEffect} from 'react'

import {View} from '@instructure/ui-view'

import {useStoreProps} from '../../../shared/StoreContext'

import {useSvgSettings, statuses} from '../../svg/settings'
import {BTN_AND_ICON_ATTRIBUTE} from '../../registerEditToolbar'
import {buildSvg, buildStylesheet} from '../../svg'
import formatMessage from '../../../../../format-message'

import {Header} from './Header'
import {ShapeSection} from './ShapeSection'
import {ColorSection} from './ColorSection'
import {TextSection} from './TextSection'
import {ImageSection} from './ImageSection'
import {Footer} from './Footer'

export const CreateButtonForm = ({editor, onClose, editing}) => {
  const [settings, settingsStatus, dispatch] = useSvgSettings(editor, editing)
  const [status, setStatus] = useState(statuses.IDLE)
  const storeProps = useStoreProps()

  const handleSubmit = ({replaceFile = false}) => {
    setStatus(statuses.LOADING)

    const svg = buildSvg(settings, {isPreview: false})
    buildStylesheet()
      .then(stylesheet => {
        svg.appendChild(stylesheet)
        return storeProps.startButtonsAndIconsUpload(
          {
            name: `${settings.name || formatMessage('untitled')}.svg`,
            domElement: svg
          },
          {
            onDuplicate: replaceFile && 'overwrite'
          }
        )
      })
      .then(writeButtonToRCE)
      .then(onClose)
      .catch(() => setStatus(statuses.ERROR))
  }

  const writeButtonToRCE = ({url}) => {
    const img = editor.dom.createHTML('img', {
      src: url,
      alt: settings.alt,
      [BTN_AND_ICON_ATTRIBUTE]: true
    })

    editor.insertContent(img)
  }

  useEffect(() => {
    setStatus(settingsStatus)
  }, [settingsStatus])

  return (
    <View as="div">
      <Header settings={settings} onChange={dispatch} />
      <ShapeSection settings={settings} onChange={dispatch} />
      <ColorSection settings={settings} onChange={dispatch} />
      <TextSection settings={settings} onChange={dispatch} />
      <ImageSection editor={editor} settings={settings} onChange={dispatch} />
      <Footer
        disabled={status === statuses.LOADING}
        onCancel={onClose}
        onSubmit={handleSubmit}
        onReplace={() => handleSubmit({replaceFile: true})}
        editing={editing}
      />
    </View>
  )
}
