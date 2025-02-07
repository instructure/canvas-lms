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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import {bool, element, func, instanceOf, oneOfType, shape, string} from 'prop-types'
import {Tray} from '@instructure/ui-tray'
import {CloseButton, Button} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

import ErrorBoundary from './ErrorBoundary'
import Bridge from '../../../bridge/Bridge'
import formatMessage from '../../../format-message'
import Filter from './Filter'
import {useFilterSettings} from './useFilterSettings'

import {getTrayHeight} from './trayUtils'
import {ICON_MAKER_ICONS} from '../instructure_icon_maker/svg/constants'
import {getLinkContentFromEditor} from './ContentSelection'
import {LinkDisplay} from './LinkDisplay'
import {showFlashAlert} from '../../../common/FlashAlert'
import {FILTER_SETTINGS_BY_PLUGIN, DynamicPanel, isLoading} from './canvasContentUtils'

/**
 * Returns the translated tray label
 * @param {string} contentType - The type of content showing on tray
 * @param {string} contentSubtype - The current subtype of content loaded in the tray
 * @param {string} contextType - The user's context
 * @returns {string}
 */
function getTrayLabel(contentType, contentSubtype, contextType) {
  if (contentType === 'links' && contextType === 'course') {
    return formatMessage('Course Links')
  } else if (contentType === 'links' && contextType === 'group') {
    return formatMessage('Group Links')
  }

  switch (contentSubtype) {
    case ICON_MAKER_ICONS:
      return formatMessage('Icon Maker Icons')
    case 'images':
      if (contentType === 'course_files') return formatMessage('Course Images')
      if (contentType === 'group_files') return formatMessage('Group Images')
      return formatMessage('User Images')
    case 'media':
      if (contentType === 'course_files') return formatMessage('Course Media')
      if (contentType === 'group_files') return formatMessage('Group Media')
      return formatMessage('User Media')
    case 'documents':
      if (contentType === 'course_files') return formatMessage('Course Documents')
      if (contentType === 'group_files') return formatMessage('Group Documents')
      return formatMessage('User Documents')
    default:
      return formatMessage('Tray') // Shouldn't ever get here
  }
}

/**
 * This component is used within various plugins to handle loading in content
 * from Canvas.  It is essentially the main component.
 */
export default function CanvasContentTray(props) {
  // should the tray be rendered open?
  const [isOpen, setIsOpen] = useState(false)
  // has the tray fully opened. we use this to defer rendering the content
  // until the tray is open.
  const [hasOpened, setHasOpened] = useState(false)
  // should we close the tray after the user clicks on something in it?
  const [hidingTrayOnAction, setHidingTrayOnAction] = useState(true)

  const trayRef = useRef(null)
  const scrollingAreaRef = useRef(null)
  const [closeButtonRef, setCloseButtonRef] = useState(null)
  const [filterSettings, setFilterSettings] = useFilterSettings()
  const [isEditTray, setIsEditTray] = useState(false)
  const [link, setLink] = useState(null)
  const [linkText, setLinkText] = useState(null)
  const [placeholderText, setPlaceholderText] = useState(null)

  const {bridge, editor, mountNode, onTrayClosing, storeProps} = {...props}

  const handleDismissTray = useCallback(() => {
    // return focus to the RCE if focus was on this tray
    if (trayRef.current && trayRef.current.contains(document.activeElement)) {
      bridge.focusActiveEditor(false)
    }

    onTrayClosing && onTrayClosing(CanvasContentTray.globalOpenCount) // tell RCEWrapper we're closing if we're open
    setIsOpen(false)
  }, [bridge, onTrayClosing])

  // this shouldn't be necessary, but INSTUI isn't focusing the close button
  // like it should.
  useEffect(() => {
    if (isOpen && closeButtonRef) {
      closeButtonRef.focus()
    }
  }, [closeButtonRef, isOpen])

  useEffect(() => {
    const controller = {
      showTrayForPlugin(plugin) {
        // increment a counter that's used as the key when rendering
        // this gets us a new instance everytime, which is necessary
        // to get the queries run so we have up to date data.
        ++CanvasContentTray.globalOpenCount
        setFilterSettings(FILTER_SETTINGS_BY_PLUGIN[plugin])
        setIsOpen(true)
        if (plugin === 'course_link_edit') {
          setIsEditTray(true)
          const {fileName, contentType, url, published, text} = getLinkContentFromEditor(
            editor.editor,
          )
          setLink({
            title: fileName,
            type: contentType,
            href: url,
            published,
          })
          setLinkText(text)
          setPlaceholderText(fileName)
        } else {
          setIsEditTray(false)
        }
      },
      hideTray(forceClose) {
        if (forceClose || hidingTrayOnAction) {
          handleDismissTray()
        }
      },
    }

    bridge.attachController(controller, editor.id)

    return () => {
      bridge.detachController(editor.id)
    }
    // it's OK the setFilterSettings is not a dependency
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [editor.id, bridge, handleDismissTray, hidingTrayOnAction])

  useEffect(() => {
    if (
      hasOpened &&
      scrollingAreaRef.current &&
      !scrollingAreaRef.current.style.overscrollBehaviorY
    ) {
      scrollingAreaRef.current.style.overscrollBehaviorY = 'contain'
    }
  }, [hasOpened])

  useEffect(() => {
    if (!hasOpened) return

    let c = document.querySelector('[role="main"]')
    let target_w = 0
    if (!c) return

    const margin =
      window.getComputedStyle(c).direction === 'ltr'
        ? document.body.getBoundingClientRect().right - c.getBoundingClientRect().right
        : c.getBoundingClientRect().left

    target_w = c.offsetWidth - trayRef.current?.offsetWidth + margin

    if (target_w >= 320 && target_w < c.offsetWidth) {
      c.style.boxSizing = 'border-box'
      c.style.width = `${target_w}px`
    }

    setHidingTrayOnAction(target_w < 320)

    return () => {
      c = document.querySelector('[role="main"]')
      if (!c) return
      c.style.width = ''
    }
  }, [hasOpened])

  function handleOpenTray() {
    bridge.focusEditor(editor)
    setHasOpened(true)
  }

  function handleExitTray() {
    onTrayClosing && onTrayClosing(true) // tell RCEWrapper we're closing
  }

  function handleCloseTray() {
    // clear the store's saved search string so the tray doesn't
    // reopen with a previous tray instance's search results
    storeProps.onChangeSearchString('')
    setHasOpened(false)
    onTrayClosing && onTrayClosing(false) // tell RCEWrapper we're closed
  }

  function handleReplaceButton() {
    handleDismissTray()

    const newLink = {
      ...link,
      forceRename: true,
      text: linkText,
    }

    bridge.insertLink(newLink)
    showFlashAlert({
      message: formatMessage('Updated link'),
      type: 'success',
      srOnly: true,
    })
  }

  function renderFooter() {
    return (
      <Flex.Item
        background="secondary"
        borderWidth="small none none none"
        padding="small medium"
        textAlign="end"
      >
        <Button data-testid="cancel-replace-button" onClick={handleDismissTray}>
          {formatMessage('Cancel')}
        </Button>
        <Button
          margin="0 0 0 x-small"
          color="primary"
          onClick={handleReplaceButton}
          data-testid="replace-link-button"
        >
          {formatMessage('Replace')}
        </Button>
      </Flex.Item>
    )
  }

  function handleFilterChange(newFilter, onChangeContext, onChangeSearchString, onChangeSortBy) {
    const newFilterSettings = {...newFilter}
    if (newFilterSettings.sortValue) {
      newFilterSettings.sortDir = newFilterSettings.sortValue === 'alphabetical' ? 'asc' : 'desc'
      onChangeSortBy({sort: newFilterSettings.sortValue, dir: newFilterSettings.sortDir})
    }

    if (
      'searchString' in newFilterSettings &&
      filterSettings.searchString !== newFilterSettings.searchString
    ) {
      onChangeSearchString(newFilterSettings.searchString)
    }

    setFilterSettings(newFilterSettings)
    if (newFilterSettings.contentType) {
      let contextType, contextId
      switch (newFilterSettings.contentType) {
        case 'user_files':
          contextType = 'user'
          contextId = props.containingContext.userId
          break
        case 'group_files':
          contextType = 'group'
          contextId = props.containingContext.contextId
          break
        case 'course_files':
          contextType = props.contextType
          contextId = props.containingContext.contextId
          break
        case 'links':
          contextType = props.containingContext.contextType
          contextId = props.containingContext.contextId
      }
      onChangeContext({contextType, contextId})
    }
  }

  function getHeader() {
    return isEditTray ? formatMessage('Edit Course Link') : formatMessage('Add')
  }

  function renderLinkDisplay() {
    return (
      isEditTray && (
        <LinkDisplay
          linkText={linkText}
          placeholderText={link?.title || placeholderText}
          linkFileName={link?.title || ''}
          published={link?.published || false}
          handleTextChange={setLinkText}
          linkType={link?.type}
        />
      )
    )
  }

  return (
    <Tray
      data-mce-component={true}
      data-testid="CanvasContentTray"
      label={getTrayLabel(
        filterSettings.contentType,
        filterSettings.contentSubtype,
        props.contextType,
      )}
      mountNode={mountNode}
      open={isOpen}
      placement="end"
      size="regular"
      shouldContainFocus={true}
      shouldReturnFocus={false}
      shouldCloseOnDocumentClick={false}
      onDismiss={handleDismissTray}
      onClose={handleCloseTray}
      onExit={handleExitTray}
      onOpen={handleOpenTray}
      contentRef={el => (trayRef.current = el)}
    >
      <Flex
        direction="column"
        as="div"
        height={getTrayHeight()}
        overflowY="hidden"
        tabIndex={-1}
        data-canvascontenttray-content={true}
      >
        <Flex.Item padding="medium" shadow="above">
          <View as="div" margin="none none medium none">
            <Heading level="h2">{getHeader()}</Heading>

            <CloseButton
              placement="end"
              offset="medium"
              onClick={handleDismissTray}
              data-testid="CloseButton_ContentTray"
              screenReaderLabel={formatMessage('Close')}
              elementRef={el => setCloseButtonRef(el)}
            />
          </View>
          {renderLinkDisplay()}
          <Filter
            {...filterSettings}
            mountNode={props.mountNode}
            userContextType={props.contextType}
            containingContextType={props.containingContext.contextType}
            onChange={newFilter => {
              handleFilterChange(
                newFilter,
                storeProps.onChangeContext,
                storeProps.onChangeSearchString,
                storeProps.onChangeSortBy,
              )
            }}
            isContentLoading={isLoading(storeProps)}
            use_rce_icon_maker={props.use_rce_icon_maker}
          />
        </Flex.Item>
        {isOpen && hasOpened ? (
          <Flex.Item
            shouldGrow={true}
            shouldShrink={true}
            margin="xx-small xxx-small 0"
            elementRef={el => (scrollingAreaRef.current = el)}
          >
            <Flex justifyItems="space-between" direction="column" height="100%">
              <Flex.Item shouldGrow={true} shouldShrink={true}>
                <ErrorBoundary>
                  <DynamicPanel
                    contentType={filterSettings.contentType}
                    contentSubtype={filterSettings.contentSubtype}
                    sortBy={{sort: filterSettings.sortValue, order: filterSettings.sortDir}}
                    searchString={filterSettings.searchString}
                    canvasOrigin={props.canvasOrigin}
                    context={{type: props.contextType, id: props.contextId}}
                    editing={isEditTray}
                    onEditClick={setLink}
                    selectedLink={link}
                    {...storeProps}
                  />
                </ErrorBoundary>
              </Flex.Item>
              {isEditTray && renderFooter()}
            </Flex>
          </Flex.Item>
        ) : null}
      </Flex>
    </Tray>
  )
}

CanvasContentTray.globalOpenCount = 0

// Changes made here may need to be reflected in the trayProps type in CanvasContentPanel
const trayPropsMap = {
  canUploadFiles: bool.isRequired,
  contextId: string.isRequired, // initial value indicating the user's context (e.g. student v teacher), not the tray's
  contextType: string.isRequired, // initial value indicating the user's context, not the tray's
  containingContext: shape({
    contextType: string.isRequired,
    contextId: string.isRequired,
    userId: string.isRequired,
  }),
  filesTabDisabled: bool,
  host: string,
  jwt: string,
  refreshToken: func,
  source: shape({
    fetchImages: func.isRequired,
  }),
  themeUrl: string,
}

export const trayPropTypes = shape(trayPropsMap)

CanvasContentTray.propTypes = {
  bridge: instanceOf(Bridge).isRequired,
  editor: shape({id: string}).isRequired,
  mountNode: oneOfType([element, func]),
  onTrayClosing: func, // called with true when the tray starts closing, false once closed
  onEditClick: func,
  ...trayPropsMap,
}

// the way we define trayProps, eslint doesn't recognize the following as props

CanvasContentTray.defaultProps = {
  canUploadFiles: false,
  filesTabDisabled: false,
  refreshToken: null,
  source: null,
  themeUrl: null,
}
