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

import React, {useState, useEffect, useRef} from 'react'
import PropTypes from 'prop-types'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Alert} from '@instructure/ui-alerts'
import {Spinner} from '@instructure/ui-spinner'
import {Preview} from './CreateIconMakerForm/Preview'
import {CreateIconMakerForm} from './CreateIconMakerForm'
import {Footer} from './CreateIconMakerForm/Footer'
import {buildStylesheet, buildSvg} from '../svg'
import {statuses, useSvgSettings} from '../svg/settings'
import {defaultState} from '../reducers/svgSettings'
import {ICON_MAKER_ATTRIBUTE, ICON_MAKER_DOWNLOAD_URL_ATTR} from '../svg/constants'
import {FixedContentTray} from '../../shared/FixedContentTray'
import {useStoreProps} from '../../shared/StoreContext'
import formatMessage from '../../../../format-message'
import buildDownloadUrl from '../../shared/buildDownloadUrl'
import {validIcon} from '../utils/iconValidation'
import {IconMakerFormHasChanges} from '../utils/IconMakerFormHasChanges'
import bridge from '../../../../bridge'

const INVALID_MESSAGE = formatMessage(
  'One of the following styles must be added to save an icon: Icon Color, Outline Size, Icon Text, or Image'
)

const UNSAVED_CHANGES_MESSAGE = formatMessage(
  'You have unsaved changes in the Icon Maker tray. Do you want to continue without saving these changes?'
)

function renderHeader(title, settings, onKeyDown, isInvalid, onAlertDismissal, onClose) {
  return (
    <View as="div" background="primary">
      {isInvalid && (
        <Alert
          variant="error"
          margin="small"
          timeout={10000}
          onDismiss={onAlertDismissal}
          renderCloseButtonLabel="Close"
        >
          {INVALID_MESSAGE}
        </Alert>
      )}
      <Flex direction="column">
        <Flex.Item padding="medium medium small">
          <Flex direction="row">
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              <Heading as="h2">{title}</Heading>
            </Flex.Item>
            <Flex.Item>
              <CloseButton
                placement="static"
                color="primary"
                onClick={onClose}
                onKeyDown={onKeyDown}
                data-testid="icon-maker-close-button"
                screenReaderLabel={formatMessage('Close')}
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item as="div" padding="small">
          <Preview settings={settings} />
        </Flex.Item>
      </Flex>
    </View>
  )
}

function renderBody(
  settings,
  dispatch,
  editor,
  editing,
  allowNameChange,
  nameRef,
  rcsConfig,
  isLoading
) {
  return isLoading() ? (
    <Flex justifyItems="center">
      <Spinner renderTitle={formatMessage('Loading...')} size="large" />
    </Flex>
  ) : (
    <CreateIconMakerForm
      settings={settings}
      dispatch={dispatch}
      editor={editor}
      editing={editing}
      allowNameChange={allowNameChange}
      nameRef={nameRef}
      rcsConfig={rcsConfig}
    />
  )
}

function renderFooter(status, onClose, handleSubmit, editing, replaceAll, setReplaceAll, applyRef) {
  return (
    <View as="div" background="primary">
      <Footer
        disabled={status === statuses.LOADING}
        onCancel={onClose}
        onSubmit={() => handleSubmit({replaceFile: replaceAll})}
        replaceAll={replaceAll}
        onReplaceAllChanged={setReplaceAll}
        editing={editing}
        applyRef={applyRef}
      />
    </View>
  )
}

const checkIfAnyUnsavedChanges = (initialSettings, currentSettings) => {
  let shouldCloseTray = true
  const imFormHasChanges = new IconMakerFormHasChanges(initialSettings, currentSettings)
  if (imFormHasChanges.hasChanges()) {
    // RCE already uses browser's confirm dialog for unsaved changes
    // Its use here in the Icon Maker tray keeps that consistency
    // eslint-disable-next-line no-restricted-globals, no-alert
    shouldCloseTray = confirm(UNSAVED_CHANGES_MESSAGE)
  }

  return shouldCloseTray
}

export function IconMakerTray({editor, onUnmount, editing, rcsConfig}) {
  const nameRef = useRef()
  const applyRef = useRef()

  const [isInvalid, setIsInvalid] = useState(false)
  const [isOpen, setIsOpen] = useState(true)
  const [replaceAll, setReplaceAll] = useState(false)

  const title = editing ? formatMessage('Edit Icon') : formatMessage('Create Icon')

  const [settings, settingsStatus, dispatch] = useSvgSettings(editor, editing, rcsConfig)
  const [status, setStatus] = useState(statuses.IDLE)

  const [initialSettings, setInitialSettings] = useState({...defaultState})

  // These useRef objects are needed because when the tray is closed using the escape key
  // objects created by useState are not available, causing the comparison between
  // initialSettings and settings to behave unexpectedly
  const initialSettingsRef = useRef(initialSettings)
  const settingsRef = useRef(settings)
  useEffect(() => {
    settingsRef.current = settings
  }, [settings])
  useEffect(() => {
    initialSettingsRef.current = initialSettings
  }, [initialSettings])

  const storeProps = useStoreProps()

  const onClose = () => {
    const shouldCloseTray = checkIfAnyUnsavedChanges(
      initialSettingsRef.current,
      settingsRef.current
    )
    if (shouldCloseTray) {
      setIsOpen(false)
    }
  }

  const isLoading = () => status === statuses.LOADING

  const onKeyDown = event => {
    if (event.keyCode !== 9) return

    event.preventDefault()
    event.shiftKey ? applyRef.current?.focus() : nameRef.current?.focus()
  }

  useEffect(() => {
    setReplaceAll(false)
  }, [settings.name])

  useEffect(() => {
    if (validIcon(settings)) {
      setIsInvalid(false)
      setStatus(statuses.IDLE)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [
    settings.color,
    settings.textColor,
    settings.text,
    settings.encodedImage,
    settings.outlineColor,
    settings.outlineSize
  ])

  const handleSubmit = ({replaceFile = false}) => {
    setStatus(statuses.LOADING)

    if (!validIcon(settings)) {
      setIsInvalid(true)
      setStatus(statuses.ERROR)
      return
    }

    const svg = buildSvg(settings, {isPreview: false})
    svg.appendChild(buildStylesheet())
    return storeProps
      .startIconMakerUpload(
        {
          name: `${settings.name || formatMessage('untitled')}.svg`,
          domElement: svg
        },
        {
          onDuplicate: replaceFile && 'overwrite'
        }
      )
      .then(writeIconToRCE)
      .then(() => setIsOpen(false))
      .catch(() => setStatus(statuses.ERROR))
  }

  const writeIconToRCE = ({url, display_name}) => {
    const {alt, isDecorative, externalStyle, externalWidth, externalHeight} = settings

    const imageAttributes = {
      alt_text: alt,
      display_name,
      height: externalHeight,
      isDecorativeImage: isDecorative,
      src: url,
      // React wants this to be an object but we are just
      // passing along a string here. Using the style attribute
      // with all caps makes React ignore this fact
      STYLE: externalStyle,
      width: externalWidth
    }

    // Mark the image as an icon maker icon.
    imageAttributes[ICON_MAKER_ATTRIBUTE] = true

    // URL to fetch the SVG from when loading the Edit tray.
    // We can't use the 'src' because Canvas will re-write the
    // source attribute to a URL that is not cross-origin friendly.
    imageAttributes[ICON_MAKER_DOWNLOAD_URL_ATTR] = buildDownloadUrl(url)

    bridge.embedImage(imageAttributes)
  }

  const defaultImageSettings = () => {
    return {
      mode: '',
      image: '',
      imageName: '',
      icon: '',
      iconFillColor: '#000000',
      cropperSettings: null
    }
  }

  const replaceInitialSettings = () => {
    const name = editing ? settings.name : ''
    const textPosition = editing ? settings.textPosition : defaultState.textPosition
    const imageSettings =
      settings.imageSettings && !!settings.imageSettings.mode
        ? settings.imageSettings
        : defaultImageSettings()

    setInitialSettings({
      name,
      alt: editing ? settings.alt : defaultState.alt,
      shape: editing ? settings.shape : defaultState.shape,
      size: settings.size,
      color: settings.color,
      outlineSize: settings.outlineSize,
      outlineColor: settings.outlineColor,
      text: settings.text,
      textSize: settings.textSize,
      textColor: settings.textColor,
      textBackgroundColor: settings.textBackgroundColor,
      textPosition,
      imageSettings
    })
  }

  useEffect(() => {
    setStatus(settingsStatus)
    replaceInitialSettings()

    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [settingsStatus])

  const handleAlertDismissal = () => setIsInvalid(false)

  return (
    <FixedContentTray
      title={title}
      isOpen={isOpen}
      onDismiss={onClose}
      onUnmount={onUnmount}
      renderHeader={() =>
        renderHeader(title, settings, onKeyDown, isInvalid, handleAlertDismissal, onClose)
      }
      renderBody={() =>
        renderBody(settings, dispatch, editor, editing, !replaceAll, nameRef, rcsConfig, isLoading)
      }
      renderFooter={() =>
        renderFooter(status, onClose, handleSubmit, editing, replaceAll, setReplaceAll, applyRef)
      }
      bodyAs="form"
      shouldJoinBodyAndFooter={true}
    />
  )
}

IconMakerTray.propTypes = {
  editor: PropTypes.object.isRequired,
  onUnmount: PropTypes.func,
  editing: PropTypes.bool,
  rcsConfig: PropTypes.object.isRequired
}

IconMakerTray.defaultProps = {
  onUnmount: () => {},
  editing: false
}
