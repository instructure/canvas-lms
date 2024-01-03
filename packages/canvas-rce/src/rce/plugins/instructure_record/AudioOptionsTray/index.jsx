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

import React, {useState, useEffect} from 'react'
import {arrayOf, bool, func, shape, string} from 'prop-types'
import {Flex} from '@instructure/ui-flex'
import {Tray} from '@instructure/ui-tray'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ClosedCaptionPanel} from '@instructure/canvas-media'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {StoreProvider} from '../../shared/StoreContext'
import Bridge from '../../../../bridge'
import formatMessage from '../../../../format-message'
import {getTrayHeight} from '../../shared/trayUtils'
import {instuiPopupMountNode} from '../../../../util/fullscreenHelpers'
import {Heading} from '@instructure/ui-heading'

const getLiveRegion = () => document.getElementById('flash_screenreader_holder')

export default function AudioOptionsTray({
  open,
  onEntered,
  onExited,
  onDismiss,
  onSave,
  trayProps,
  audioOptions,
  requestSubtitlesFromIframe,
}) {
  const [subtitles, setSubtitles] = useState(audioOptions.tracks || [])

  useEffect(() => {
    if (subtitles.length === 0) requestSubtitlesFromIframe(setSubtitles)
  }, [])

  const handleSave = (e, contentProps) => {
    onSave({
      media_object_id: audioOptions.id,
      subtitles,
      updateMediaObject: contentProps.updateMediaObject,
    })
  }

  return (
    <StoreProvider {...trayProps}>
      {contentProps => (
        <Tray
          key="audio-options-tray"
          data-mce-component={true}
          label={formatMessage('Audio Options Tray')}
          mountNode={instuiPopupMountNode}
          onDismiss={onDismiss}
          onEntered={onEntered}
          onExited={onExited}
          open={open}
          placement="end"
          shouldCloseOnDocumentClick={true}
          shouldContainFocus={true}
          shouldReturnFocus={true}
        >
          <Flex direction="column" height={getTrayHeight()}>
            <Flex.Item as="header" padding="medium">
              <Flex direction="row">
                <Flex.Item shouldGrow={true} shouldShrink={true}>
                  <Heading as="h2">{formatMessage('Audio Options')}</Heading>
                </Flex.Item>
                <Flex.Item>
                  <CloseButton
                    placement="static"
                    color="primary"
                    onClick={onDismiss}
                    screenReaderLabel={formatMessage('Close')}
                  />
                </Flex.Item>
              </Flex>
            </Flex.Item>
            <Flex.Item as="form" shouldGrow={true} margin="none" shouldShrink={true}>
              <Flex justifyItems="space-between" direction="column" height="100%">
                <Flex.Item shouldGrow={true} padding="small" shouldShrink={true}>
                  <Flex direction="column">
                    <Flex.Item padding="small">
                      <FormFieldGroup description={formatMessage('Closed Captions/Subtitles')}>
                        <ClosedCaptionPanel
                          subtitles={subtitles.map(st => ({
                            locale: st.locale,
                            file: {name: st.language || st.locale},
                          }))}
                          uploadMediaTranslations={Bridge.uploadMediaTranslations}
                          languages={Bridge.languages}
                          updateSubtitles={newSubtitles => setSubtitles(newSubtitles)}
                          liveRegion={getLiveRegion}
                        />
                      </FormFieldGroup>
                    </Flex.Item>
                  </Flex>
                </Flex.Item>
                <Flex.Item
                  background="secondary"
                  borderWidth="small none none none"
                  padding="small medium"
                  textAlign="end"
                >
                  <Button onClick={e => handleSave(e, contentProps)} color="primary">
                    {formatMessage('Done')}
                  </Button>
                </Flex.Item>
              </Flex>
            </Flex.Item>
          </Flex>
        </Tray>
      )}
    </StoreProvider>
  )
}

AudioOptionsTray.propTypes = {
  onEntered: func,
  onExited: func,
  onDismiss: func,
  onSave: func,
  open: bool.isRequired,
  requestSubtitlesFromIframe: func,
  trayProps: shape({
    host: string.isRequired,
    jwt: string.isRequired,
  }).isRequired,
  audioOptions: shape({
    id: string.isRequired,
    titleText: string.isRequired,
    tracks: arrayOf(
      shape({
        locale: string.isRequired,
      })
    ),
  }).isRequired,
}

AudioOptionsTray.defaultProps = {
  onEntered: null,
  onExited: null,
  onDismiss: null,
  onSave: null,
  requestSubtitlesFromIframe: () => {}
}
