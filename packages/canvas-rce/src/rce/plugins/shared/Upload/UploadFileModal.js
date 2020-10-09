/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React, {Suspense, useState} from 'react'
import {arrayOf, func, number, object, oneOf, oneOfType, string} from 'prop-types'
import {Modal} from '@instructure/ui-overlays'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-elements'
import {Spinner} from '@instructure/ui-spinner'
import {Tabs} from '@instructure/ui-tabs'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {Text} from '@instructure/ui-text'
import formatMessage from '../../../../format-message'

import RceApiSource from '../../../../sidebar/sources/api'
import ImageOptionsForm from '../ImageOptionsForm'
import UsageRightsSelectBox from './UsageRightsSelectBox'
import {View} from '@instructure/ui-view'

const ComputerPanel = React.lazy(() => import('./ComputerPanel'))
const UrlPanel = React.lazy(() => import('./UrlPanel'))
const UnsplashPanel = React.lazy(() => import('./UnsplashPanel'))

function shouldBeDisabled(
  {fileUrl, theFile, unsplashData, error},
  selectedPanel,
  usageRightNotSet
) {
  if (error || usageRightNotSet) {
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

const UploadFileModal = React.forwardRef(
  (
    {
      editor,
      contentProps,
      trayProps,
      onSubmit,
      onDismiss,
      panels,
      label,
      accept,
      modalBodyWidth,
      modalBodyHeight
    },
    ref
  ) => {
    const [theFile, setFile] = useState(null)
    const [error, setError] = useState(null)
    const [fileUrl, setFileUrl] = useState('')
    const [selectedPanel, setSelectedPanel] = useState(panels[0])
    const [unsplashData, setUnsplashData] = useState({id: null, url: null})

    const [usageRightsState, setUsageRightsState] = React.useState({
      usageRight: 'choose',
      ccLicense: '',
      copyrightHolder: ''
    })

    // Image options props
    const [altText, setAltText] = useState('')
    const [isDecorativeImage, setIsDecorativeImage] = useState(false)
    const [displayAs, setDisplayAs] = useState('embed')
    // even though usage rights might be required by the course, canvas has no place
    // on the user to store it. Only Group and Course.
    const requiresUsageRights =
      contentProps?.session?.usageRightsRequired && /(?:course|group)/.test(trayProps.contextType)

    function handleAltTextChange(event) {
      setAltText(event.target.value)
    }

    function handleIsDecorativeChange(event) {
      setIsDecorativeImage(event.target.checked)
    }

    function handleDisplayAsChange(event) {
      setDisplayAs(event.target.value)
    }

    const submitDisabled = shouldBeDisabled(
      {fileUrl, theFile, unsplashData, error},
      selectedPanel,
      requiresUsageRights && usageRightsState.usageRight === 'choose'
    )

    // Load the necessary session values, if not already loaded
    const loadSession = contentProps.loadSession
    React.useEffect(() => {
      loadSession()
    }, [loadSession])

    const source =
      trayProps.source ||
      new RceApiSource({
        jwt: trayProps.jwt,
        refreshToken: trayProps.refreshToken,
        host: trayProps.host
      })

    return (
      <Modal
        data-mce-component
        as="form"
        label={label}
        size="large"
        overflow="fit"
        onDismiss={onDismiss}
        onSubmit={e => {
          e.preventDefault()
          if (submitDisabled) {
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
              imageOptions: {altText, isDecorativeImage, displayAs},
              usageRights: usageRightsState
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
        <Modal.Body ref={ref}>
          <Tabs onRequestTabChange={(event, {index}) => setSelectedPanel(panels[index])}>
            {panels.map(panel => {
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
                      <Suspense
                        fallback={<Spinner renderTitle={formatMessage('Loading')} size="large" />}
                      >
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
                      <Suspense
                        fallback={<Spinner renderTitle={formatMessage('Loading')} size="large" />}
                      >
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
                      <Suspense
                        fallback={<Spinner renderTitle={formatMessage('Loading')} size="large" />}
                      >
                        <UrlPanel fileUrl={fileUrl} setFileUrl={setFileUrl} />
                      </Suspense>
                    </Tabs.Panel>
                  )
              }
              return null
            })}
          </Tabs>
          {// We shouldn't show the accordions until the session data is loaded.
          Object.keys(contentProps.session || {}).length > 0 && (
            <>
              {selectedPanel === 'COMPUTER' && requiresUsageRights && (
                <View
                  as="div"
                  role="group"
                  borderColor="primary"
                  borderWidth="0 0 small 0"
                  padding="medium"
                >
                  <ToggleDetails
                    defaultExpanded
                    summary={<Text size="x-large">{formatMessage('Usage Rights (required)')}</Text>}
                  >
                    <UsageRightsSelectBox
                      usageRightsState={usageRightsState}
                      setUsageRightsState={setUsageRightsState}
                      contextType={trayProps.contextType}
                      contextId={trayProps.contextId}
                      showMessage={false}
                    />
                  </ToggleDetails>
                </View>
              )}
              {/image/.test(accept) && (
                <View
                  as="div"
                  role="group"
                  borderColor="primary"
                  borderWidth="0 0 small 0"
                  padding="medium"
                >
                  <ToggleDetails
                    defaultExpanded={!requiresUsageRights}
                    summary={<Text size="x-large">{formatMessage('Attributes')}</Text>}
                  >
                    <ImageOptionsForm
                      altText={altText}
                      isDecorativeImage={isDecorativeImage}
                      displayAs={displayAs}
                      handleAltTextChange={handleAltTextChange}
                      handleIsDecorativeChange={handleIsDecorativeChange}
                      handleDisplayAsChange={handleDisplayAsChange}
                      hideDimensions
                    />
                  </ToggleDetails>
                </View>
              )}
            </>
          )}
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={onDismiss}>{formatMessage('Close')}</Button>&nbsp;
          <Button variant="primary" type="submit" disabled={submitDisabled}>
            {formatMessage('Submit')}
          </Button>
        </Modal.Footer>
      </Modal>
    )
  }
)

UploadFileModal.propTypes = {
  editor: object.isRequired,
  contentProps: object,
  trayProps: object,
  onSubmit: func,
  onDismiss: func.isRequired,
  panels: arrayOf(oneOf(['COMPUTER', 'UNSPLASH', 'URL'])),
  label: string.isRequired,
  accept: oneOfType([arrayOf(string), string]),
  modalBodyWidth: number,
  modalBodyHeight: number
}

export default UploadFileModal
