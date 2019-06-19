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
import {bool, func, instanceOf, shape, string} from 'prop-types'
import {Tray} from '@instructure/ui-overlays'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading, Spinner} from '@instructure/ui-elements'
import {Flex} from '@instructure/ui-layout'

import ErrorBoundary from './ErrorBoundary'
import Bridge from '../../../bridge/Bridge'
import formatMessage from '../../../format-message'
import Filter, {useFilterSettings} from './Filter'
import {StoreProvider} from './StoreContext'

/**
 * Returns the translated tray label
 * @param {Object} filterSettings
 * @param {string} filterSettings.contentSubtype - The current subtype of
 * content loaded in the tray
 * @returns {string}
 */
function getTrayLabel({contentType, contentSubtype}) {
  if (contentType === 'links') {
    return formatMessage('Course Links')
  }

  switch (contentSubtype) {
    case 'images':
      return formatMessage('Course Images')
    case 'media':
      return formatMessage('Course Media')
    case 'documents':
      return formatMessage('Course Documents')
    default:
      return formatMessage('Tray') // Shouldn't ever get here
  }
}

const thePanels = {
  links: React.lazy(() => import('../instructure_links/components/LinksPanel')),
  images: React.lazy(() => import('../instructure_image/Images')),
  documents: React.lazy(() => import('../instructure_documents/components/DocumentsPanel')),
  media: React.lazy(() => import('./FakeComponent'))
}
/**
 * @param {contentType, contentSubType} filterSettings: key to which panel is desired
 * @param  contentProps: the props from connection to the redux store
 * @returns rendered component
 */
function renderContentComponent({contentType, contentSubtype}, contentProps) {
  let Component = null
  if (contentType === 'links') {
    Component = thePanels.links
  } else {
    Component = thePanels[contentSubtype]
  }
  return Component && <Component {...contentProps} />
}

const FILTER_SETTINGS_BY_PLUGIN = {
  documents: {contentType: 'files', contentSubtype: 'documents', sortValue: 'date_added'},
  images: {contentType: 'files', contentSubtype: 'images', sortValue: 'date_added'},
  links: {contentType: 'links', contentSubtype: 'all', sortValue: 'date_added'},
  media: {contentType: 'files', contentSubtype: 'media', sortValue: 'date_added'}
}

/**
 * This component is used within various plugins to handle loading in content
 * from Canvas.  It is essentially the main component.
 */
export default function CanvasContentTray(props) {
  const [isOpen, setIsOpen] = useState(false)
  const [openCount, setOpenCount] = useState(0)


  const [filterSettings, setFilterSettings] = useFilterSettings()

  useEffect(() => {
    const controller = {
      showTrayForPlugin(plugin) {
        setFilterSettings(FILTER_SETTINGS_BY_PLUGIN[plugin])
        setIsOpen(true)
      },
      hideTray() {
        handleDismissTray()
      }
    }

    props.bridge.attachController(controller)

    return () => {
      props.bridge.detachController()
    }
  }, [props.bridge])

  function handleDismissTray() {
    setIsOpen(false)
  }

  function handleCloseTray() {
    props.bridge.focusActiveEditor(false)
    setOpenCount(openCount + 1)
  }

  function renderLoading() {
    return formatMessage('Loading')
  }

  return (
    <StoreProvider {...props} key={openCount}>
      {contentProps => (
        <Tray
          data-testid="CanvasContentTray"
          label={getTrayLabel(filterSettings)}
          open={isOpen}
          placement="end"
          size="regular"
          shouldContainFocus
          shouldReturnFocus={false}
          shouldCloseOnDocumentClick={false}
          onDismiss={handleDismissTray}
          onClose={handleCloseTray}
        >
          <Flex direction="column" display="block" height="100vh" overflowY="hidden">
            <Flex.Item padding="medium" shadow="above">
              <Flex margin="none none medium none">
                <Flex.Item>
                  <CloseButton placement="static" variant="icon" onClick={handleDismissTray}>
                    {formatMessage('Close')}
                  </CloseButton>
                </Flex.Item>

                <Flex.Item grow shrink>
                  <Heading level="h2" margin="none none none medium">{formatMessage('Add')}</Heading>
                </Flex.Item>
              </Flex>

              <Filter {...filterSettings} onChange={setFilterSettings} />
            </Flex.Item>

            <Flex.Item grow shrink margin="xx-small 0 0 0">
              <ErrorBoundary>
                    <Suspense fallback={<Spinner renderTitle={renderLoading} size="large" />}>
                      {renderContentComponent(filterSettings, contentProps)}
                    </Suspense>
              </ErrorBoundary>
            </Flex.Item>
          </Flex>
        </Tray>
      )}
    </StoreProvider>
  )
}

function requiredWithoutSource(props, propName, componentName) {
  if (props.source == null && props[propName] == null) {
    throw new Error(`The prop \`${propName}\` is marked as required in \`${componentName}\`, but its value is \`${props[propName]}\`.`)
  }
}

const trayPropsMap = {
  canUploadFiles: bool.isRequired,
  contextId: string.isRequired,
  contextType: string.isRequired,
  filesTabDisabled: bool,
  host: requiredWithoutSource,
  jwt: requiredWithoutSource,
  refreshToken: func,
  source: shape({
    fetchImages: func.isRequired
  }),
  themeUrl: string
}

export const trayProps = shape(trayPropsMap)

CanvasContentTray.propTypes = {
  bridge: instanceOf(Bridge).isRequired,
  ...trayPropsMap
}

CanvasContentTray.defaultProps = {
  canUploadFiles: false,
  filesTabDisabled: false,
  refreshToken: null,
  source: null,
  themeUrl: null
}
