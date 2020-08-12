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

import React, {Suspense, useEffect, useState} from 'react'
import ReactDOM from 'react-dom'
import {arrayOf, func, object, oneOf, oneOfType, string} from 'prop-types'
import {Modal} from '@instructure/ui-overlays'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-elements'
import {Spinner} from '@instructure/ui-spinner'
import {Tabs} from '@instructure/ui-tabs'
import {px} from '@instructure/ui-utils'
import formatMessage from '../../../../format-message'
import indicatorRegion from '../../../indicatorRegion'
import {isImage, isAudioOrVideo} from '../fileTypeUtils'
import indicate from '../../../../common/indicate'

import {StoreProvider} from '../StoreContext'
import RceApiSource from '../../../../sidebar/sources/api'
import Bridge from '../../../../bridge'
import ImageOptionsForm from '../ImageOptionsForm'

const ComputerPanel = React.lazy(() => import('./ComputerPanel'))
const UrlPanel = React.lazy(() => import('./UrlPanel'))
const UnsplashPanel = React.lazy(() => import('./UnsplashPanel'))

/**
 * Handles uploading data based on what type of data is submitted.
 */
export const handleSubmit = (
  editor,
  accept,
  selectedPanel,
  uploadData,
  storeProps,
  source,
  afterInsert = () => {}
) => {
  Bridge.focusEditor(editor.rceWrapper) // necessary since it blurred when the modal opened
  const {altText, isDecorativeImage, displayAs} = uploadData?.imageOptions || {}
  switch (selectedPanel) {
    case 'COMPUTER': {
      const {theFile} = uploadData
      const fileMetaData = {
        parentFolderId: 'media',
        name: theFile.name,
        size: theFile.size,
        contentType: theFile.type,
        domObject: theFile,
        altText,
        isDecorativeImage,
        displayAs
      }
      let tabContext = 'documents'
      if (isImage(theFile.type)) {
        tabContext = 'images'
      } else if (isAudioOrVideo(theFile.type)) {
        tabContext = 'media'
      }
      storeProps.startMediaUpload(tabContext, fileMetaData)
      break
    }
    case 'UNSPLASH': {
      const {unsplashData} = uploadData
      source.pingbackUnsplash(unsplashData.id)
      let editorHtml
      if (displayAs !== 'link' && /image/.test(accept)) {
        editorHtml = editor.dom.createHTML('img', {
          src: unsplashData.url,
          alt: altText || unsplashData.alt,
          role: isDecorativeImage ? 'presentation' : undefined
        })
      } else {
        editorHtml = editor.dom.createHTML(
          'a',
          {href: unsplashData.url},
          altText || unsplashData.url
        )
      }
      editor.insertContent(editorHtml)
      break
    }
    case 'URL': {
      const {fileUrl} = uploadData
      let editorHtml
      if (displayAs !== 'link' && /image/.test(accept)) {
        editorHtml = editor.dom.createHTML('img', {
          src: fileUrl,
          alt: altText,
          role: isDecorativeImage ? 'presentation' : undefined
        })
      } else {
        editorHtml = editor.dom.createHTML('a', {href: fileUrl}, altText || fileUrl)
      }
      editor.insertContent(editorHtml)
      break
    }
    default:
      throw new Error('Selected Panel is invalid') // Should never get here
  }
  const element = editor.selection.getEnd()
  element.addEventListener('load', () => indicate(indicatorRegion(editor, element)))
  afterInsert()
}

function shouldBeDisabled({fileUrl, theFile, unsplashData, error}, selectedPanel) {
  if (error) {
    return true
  }
  switch (selectedPanel) {
    case 'COMPUTER':
      return !theFile || theFile.error
    case 'UNSPLASH':
      return !unsplashData.id || !unsplashData.url
    case 'URL':
      return !fileUrl
    default:
      return false // When in doubt, don't disable (but we shouldn't get here either)
  }
}

export function UploadFile({
  accept,
  editor,
  label,
  panels,
  onDismiss,
  trayProps,
  onSubmit = handleSubmit
}) {
  const [theFile, setFile] = useState(null)
  const [error, setError] = useState(null)
  const [fileUrl, setFileUrl] = useState('')
  const [selectedPanel, setSelectedPanel] = useState(panels[0])
  const [unsplashData, setUnsplashData] = useState({id: null, url: null})
  const [modalBodyWidth, setModalBodyWidth] = useState(undefined)
  const [modalBodyHeight, setModalBodyHeight] = useState(undefined)
  const bodyRef = React.createRef()

  // Image options props
  const [altText, setAltText] = useState('')
  const [isDecorativeImage, setIsDecorativeImage] = useState(false)
  const [displayAs, setDisplayAs] = useState('embed')

  function handleAltTextChange(event) {
    setAltText(event.target.value)
  }

  function handleIsDecorativeChange(event) {
    setIsDecorativeImage(event.target.checked)
  }

  function handleDisplayAsChange(event) {
    setDisplayAs(event.target.value)
  }

  trayProps = trayProps || Bridge.trayProps.get(editor)

  const source =
    trayProps.source ||
    new RceApiSource({
      jwt: trayProps.jwt,
      refreshToken: trayProps.refreshToken,
      host: trayProps.host
    })

  // the panels get rendered inside tab panels. it's difficult for them to
  // figure out how much space they have to work with, and I'd like the previews
  // not to trigger scrollbars in the modal's body. Get the Modal.Body's size
  // and to the ComputerPanel how much space it has so it can render the file preview
  useEffect(() => {
    if (bodyRef.current) {
      // eslint-disable-next-line react/no-find-dom-node
      const thebody = ReactDOM.findDOMNode(bodyRef.current)
      const sz = thebody.getBoundingClientRect()
      sz.height -= px('3rem') // leave room for the tabs
      setModalBodyWidth(sz.width)
      setModalBodyHeight(sz.height)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [bodyRef.current, modalBodyHeight, modalBodyWidth])

  function renderLoading() {
    return formatMessage('Loading')
  }

  function renderTabs() {
    return panels.map(panel => {
      switch (panel) {
        case 'COMPUTER':
          return (
            <Tabs.Panel
              key={panel}
              renderTitle={function() {
                return formatMessage('Computer')
              }}
              selected={selectedPanel === 'COMPUTER'}
            >
              <Suspense fallback={<Spinner renderTitle={renderLoading} size="large" />}>
                <ComputerPanel
                  editor={editor}
                  theFile={theFile}
                  setFile={setFile}
                  setError={setError}
                  label={label}
                  accept={accept}
                  bounds={{width: modalBodyWidth, height: modalBodyHeight}}
                />
              </Suspense>
            </Tabs.Panel>
          )
        case 'UNSPLASH':
          return (
            <Tabs.Panel
              key={panel}
              renderTitle={function() {
                return 'Unsplash'
              }}
              selected={selectedPanel === 'UNSPLASH'}
            >
              <Suspense fallback={<Spinner renderTitle={renderLoading} size="large" />}>
                <UnsplashPanel
                  editor={editor}
                  setUnsplashData={setUnsplashData}
                  source={source}
                  brandColor={trayProps.brandColor}
                  liveRegion={trayProps.liveRegion}
                />
              </Suspense>
            </Tabs.Panel>
          )
        case 'URL':
          return (
            <Tabs.Panel
              key={panel}
              renderTitle={function() {
                return formatMessage('URL')
              }}
              selected={selectedPanel === 'URL'}
            >
              <Suspense fallback={<Spinner renderTitle={renderLoading} size="large" />}>
                <UrlPanel fileUrl={fileUrl} setFileUrl={setFileUrl} />
              </Suspense>
            </Tabs.Panel>
          )
      }
      return null
    })
  }

  const disabledSubmit = shouldBeDisabled({fileUrl, theFile, unsplashData, error}, selectedPanel)

  return (
    <StoreProvider {...trayProps}>
      {contentProps => (
        <Modal
          data-mce-component
          as="form"
          label={label}
          size="large"
          overflow="fit"
          onDismiss={onDismiss}
          onSubmit={e => {
            e.preventDefault()
            if (disabledSubmit) {
              return false
            }
            onSubmit(
              editor,
              accept,
              selectedPanel,
              {
                fileUrl,
                theFile,
                unsplashData,
                imageOptions: {altText, isDecorativeImage, displayAs}
              },
              contentProps,
              source,
              onDismiss
            )
          }}
          open
          shouldCloseOnDocumentClick
          liveRegion={trayProps.liveRegion}
        >
          <Modal.Header>
            <CloseButton onClick={onDismiss} offset="small" placement="end">
              {formatMessage('Close')}
            </CloseButton>
            <Heading>{label}</Heading>
          </Modal.Header>
          <Modal.Body ref={bodyRef}>
            <Tabs onRequestTabChange={(event, {index}) => setSelectedPanel(panels[index])}>
              {renderTabs()}
            </Tabs>
            {/image/.test(accept) && (
              <ImageOptionsForm
                altText={altText}
                isDecorativeImage={isDecorativeImage}
                displayAs={displayAs}
                handleAltTextChange={handleAltTextChange}
                handleIsDecorativeChange={handleIsDecorativeChange}
                handleDisplayAsChange={handleDisplayAsChange}
                hideDimensions
              />
            )}
          </Modal.Body>
          <Modal.Footer>
            <Button onClick={onDismiss}>{formatMessage('Close')}</Button>&nbsp;
            <Button variant="primary" type="submit" disabled={disabledSubmit}>
              {formatMessage('Submit')}
            </Button>
          </Modal.Footer>
        </Modal>
      )}
    </StoreProvider>
  )
}

UploadFile.propTypes = {
  onSubmit: func,
  onDismiss: func.isRequired,
  accept: oneOfType([arrayOf(string), string]),
  editor: object.isRequired,
  label: string.isRequired,
  panels: arrayOf(oneOf(['COMPUTER', 'UNSPLASH', 'URL'])),
  trayProps: object
}
