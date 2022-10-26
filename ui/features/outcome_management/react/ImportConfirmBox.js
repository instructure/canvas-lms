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
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {FocusRegionManager} from '@instructure/ui-a11y-utils'

const I18n = useI18nScope('ImportConfirmBox')

const ImportConfirmBox = ({count, onImportHandler, onCloseHandler}) => {
  const containerRef = useRef()
  const cancelBtnRef = useRef()
  const [isOutsideClick, setIsOutsideClick] = useState(false)

  useEffect(() => {
    const handleOutsideClick = event => {
      if (containerRef.current && !containerRef.current.contains(event.target)) {
        setIsOutsideClick(true)
      }
    }
    document.addEventListener('click', handleOutsideClick)
    return () => document.removeEventListener('click', handleOutsideClick)
  }, [])

  useEffect(() => {
    if (isOutsideClick) onCloseHandler()
  }, [isOutsideClick, onCloseHandler])

  useEffect(() => {
    cancelBtnRef.current.focus()
  }, [])

  // traps focus within the confirm box
  useEffect(() => {
    const container = containerRef.current
    const focusRegion = FocusRegionManager.activateRegion(container, {
      shouldContainFocus: true,
      shouldReturnFocus: true,
      onBlur: onCloseHandler,
    })
    return () => FocusRegionManager.blurRegion(container, focusRegion.id)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const onConfirmHandler = () => {
    onImportHandler()
    onCloseHandler()
  }

  return (
    <div ref={containerRef}>
      <Alert variant="warning" onDismiss={onCloseHandler} margin="small 0" transition="fade">
        <Text as="div" weight="bold">
          {I18n.t(
            {
              one: 'You are about to add 1 outcome to this course.',
              other: 'You are about to add %{count} outcomes to this course.',
            },
            {
              count,
            }
          )}
        </Text>
        <Text as="div">
          {I18n.t(
            'To make outcome alignment easier, only add outcomes that are pertinent to this course.'
          )}
        </Text>
        <View as="div" padding="small 0 0">
          <Button
            type="button"
            size="small"
            color="secondary"
            margin="0 small 0 0"
            ref={cancelBtnRef}
            onClick={onCloseHandler}
          >
            {I18n.t('Cancel')}
          </Button>
          <Button
            type="button"
            size="small"
            color="primary"
            margin="0 small 0 0"
            onClick={onConfirmHandler}
          >
            {I18n.t('Import Anyway')}
          </Button>
        </View>
      </Alert>
    </div>
  )
}

ImportConfirmBox.propTypes = {
  count: PropTypes.number.isRequired,
  onCloseHandler: PropTypes.func.isRequired,
  onImportHandler: PropTypes.func.isRequired,
}

export default ImportConfirmBox

export const showImportConfirmBox = ({count, onImportHandler, onCloseHandler}) => {
  const messageHolderId = 'flashalert_message_holder'
  const getBoxContainer = () => {
    let boxContainer = document.getElementById(messageHolderId)
    if (!boxContainer) {
      boxContainer = document.createElement('div')
      boxContainer.id = messageHolderId
      boxContainer.setAttribute(
        'style',
        'position: fixed; top: 0; left: 0; width: 100%; z-index: 100000;'
      )
      document.body.appendChild(boxContainer)
    }
    return boxContainer
  }

  const parent = document.createElement('div')
  parent.setAttribute('style', 'max-width:45em;margin:1rem auto;')
  parent.setAttribute('class', 'flashalert-message')
  getBoxContainer().appendChild(parent)
  ReactDOM.render(
    <ImportConfirmBox
      count={count}
      onImportHandler={onImportHandler}
      onCloseHandler={() => {
        onCloseHandler()
        ReactDOM.unmountComponentAtNode(parent)
        parent.remove()
      }}
    />,
    parent
  )
}
