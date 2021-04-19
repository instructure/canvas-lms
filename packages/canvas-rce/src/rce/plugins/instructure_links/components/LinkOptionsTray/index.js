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
import React, {useEffect, useState} from 'react'
import {checkPropTypes, bool, func, object, oneOf, shape, string} from 'prop-types'
import {Button, CloseButton} from '@instructure/ui-buttons'

import {Alert} from '@instructure/ui-alerts'
import {Heading} from '@instructure/ui-heading'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Checkbox} from '@instructure/ui-checkbox'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import validateURL from '../../validateURL'
import formatMessage from '../../../../../format-message'
import {
  DISPLAY_AS_LINK,
  DISPLAY_AS_EMBED,
  DISPLAY_AS_EMBED_DISABLED
} from '../../../shared/ContentSelection'
import {getTrayHeight} from '../../../shared/trayUtils'

export default function LinkOptionsTray(props) {
  const content = props.content || {}
  const textToLink = content.text || ''
  const showText = content.onlyTextSelected
  const [text, setText] = useState(textToLink || '')
  const [url, setUrl] = useState(content.url || '')
  const [err, setErr] = useState(null)
  const [isValidURL, setIsValidURL] = useState(false)
  const [autoOpenPreview, setAutoOpenPreview] = useState(content.displayAs === DISPLAY_AS_EMBED)
  const [disablePreview, setDisablePreview] = useState(
    content.displayAs === DISPLAY_AS_EMBED_DISABLED
  )
  const [rce_better_file_previewing] = useState(!!window?.ENV?.FEATURES?.rce_better_file_previewing)

  useEffect(() => {
    try {
      const v = validateURL(url)
      setIsValidURL(v)
      setErr(null)
    } catch (ex) {
      setIsValidURL(false)
      setErr(ex.message)
    }
  }, [url])

  function handleSave(event) {
    event.preventDefault()
    const embedType = content.isPreviewable ? 'scribd' : null

    const linkAttrs = {
      embed: embedType
        ? {
            type: embedType,
            autoOpenPreview: autoOpenPreview && !disablePreview,
            disablePreview
          }
        : null,
      text,
      target: '_blank',
      href: url,
      id: content.id || null,
      class: embedType ? undefined : 'inline_disabled'
    }

    props.onSave(linkAttrs)
  }
  function handleTextChange(event) {
    setText(event.target.value)
  }
  function handleLinkChange(event) {
    setUrl(event.target.value)
  }
  function handleDisablePreviewChange(event) {
    setDisablePreview(event.target.checked)
  }
  function handlePreviewChange(event) {
    setAutoOpenPreview(event.target.checked)
  }
  function handlePreviewOptionChange(_event, value) {
    setDisablePreview(value === 'overlay')
  }

  function renderDisplayOptions() {
    if (rce_better_file_previewing) {
      return (
        <FormFieldGroup
          description={formatMessage('Display Options')}
          layout="stacked"
          rowSpacing="small"
        >
          <RadioInputGroup
            description=" " /* the FormFieldGroup is providing the label */
            name="preview_option"
            onChange={handlePreviewOptionChange}
            value={disablePreview ? 'overlay' : 'inline'}
          >
            <RadioInput key="overlay" value="overlay" label={formatMessage('Preview in overlay')} />
            <RadioInput key="inline" value="inline" label={formatMessage('Preview inline')} />
          </RadioInputGroup>
          {!disablePreview && (
            <View as="div" margin="0 0 0 small">
              <Checkbox
                label={formatMessage('Expand preview by Default')}
                name="auto-preview"
                onChange={handlePreviewChange}
                checked={autoOpenPreview}
              />
            </View>
          )}
        </FormFieldGroup>
      )
    } else {
      return renderLegacyDisplayOptions()
    }
  }

  function renderLegacyDisplayOptions() {
    return (
      <FormFieldGroup
        description={formatMessage('Display Options')}
        layout="stacked"
        rowSpacing="small"
      >
        <Checkbox
          label={formatMessage('Disable in-line preview.')}
          name="disable-preview"
          onChange={handleDisablePreviewChange}
          checked={disablePreview}
        />
        {!disablePreview && (
          <Checkbox
            label={formatMessage(
              'Automatically open an in-line preview. (Preview displays only after saving)'
            )}
            name="auto-preview"
            onChange={handlePreviewChange}
            checked={autoOpenPreview}
          />
        )}
      </FormFieldGroup>
    )
  }

  return (
    <Tray
      data-testid="RCELinkOptionsTray"
      data-mce-component
      label={formatMessage('Link Options')}
      onDismiss={props.onRequestClose}
      onEntered={props.onEntered}
      onExited={props.onExited}
      open={props.open}
      placement="end"
      shouldCloseOnDocumentClick
      shouldContainFocus
      shouldReturnFocus
    >
      <Flex direction="column" height={getTrayHeight()}>
        <Flex.Item as="header" padding="medium">
          <Flex direction="row">
            <Flex.Item grow shrink>
              <Heading as="h2">{formatMessage('Link Options')}</Heading>
            </Flex.Item>

            <Flex.Item>
              <CloseButton placement="static" variant="icon" onClick={props.onRequestClose}>
                {formatMessage('Close')}
              </CloseButton>
            </Flex.Item>
          </Flex>
        </Flex.Item>

        <Flex.Item as="form" grow margin="none" shrink onSubmit={handleSave}>
          <Flex justifyItems="space-between" direction="column" height="100%">
            <Flex.Item grow padding="small" shrink>
              <input type="submit" style={{display: 'none'}} />
              <Flex direction="column">
                {showText && (
                  <Flex.Item padding="small">
                    <TextInput
                      renderLabel={() => formatMessage('Text')}
                      onChange={handleTextChange}
                      value={text}
                    />
                  </Flex.Item>
                )}

                <Flex.Item padding="small">
                  <TextInput
                    renderLabel={() => formatMessage('Link')}
                    onChange={handleLinkChange}
                    value={url}
                  />
                </Flex.Item>
                {err && (
                  <Flex.Item padding="small" data-testid="url-error">
                    <Alert variant="error">{err}</Alert>
                  </Flex.Item>
                )}

                {content.isPreviewable && (
                  <Flex.Item margin="small none none none" padding="small">
                    {renderDisplayOptions()}
                  </Flex.Item>
                )}
              </Flex>
            </Flex.Item>

            <Flex.Item
              background="light"
              borderWidth="small none none none"
              padding="small medium"
              textAlign="end"
            >
              <Button
                disabled={(showText && !text) || !(url && isValidURL)}
                onClick={handleSave}
                variant="primary"
              >
                {formatMessage('Done')}
              </Button>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </Tray>
  )
}
LinkOptionsTray.propTypes = {
  // content is required only if the tray is open
  content: (props, _propName, _componentName) => {
    if (props.open) {
      checkPropTypes(
        {
          content: shape({
            $element: object, // the DOM's HTMLElement
            dispalyAs: oneOf([DISPLAY_AS_LINK, DISPLAY_AS_EMBED]),
            isPreviewable: bool,
            text: string,
            url: string
          }).isRequired
        },
        props,
        'content',
        'LinkOptionsTray'
      )
    }
  },
  onEntered: func,
  onExited: func,
  onRequestClose: func.isRequired,
  onSave: func.isRequired,
  open: bool.isRequired
}
LinkOptionsTray.defaultProps = {
  onEntered: null,
  onExited: null
}
