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

import AnonymousResponseSelector from '@canvas/discussions/react/components/AnonymousResponseSelector/AnonymousResponseSelector'
import {useScope as useI18nScope} from '@canvas/i18n'
import React, {useRef, useState, useEffect} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {IconCheckMarkLine} from '@instructure/ui-icons'
import {Responsive} from '@instructure/ui-responsive'
import {Text} from '@instructure/ui-text'
import {responsiveQuerySizes, showErrorWhenMessageTooLong} from '../../utils'
import {View} from '@instructure/ui-view'
import PropTypes from 'prop-types'
import CanvasRce from '@canvas/rce/react/CanvasRce'
import {nanoid} from 'nanoid'
import {name as mentionsPluginName} from '@canvas/rce/plugins/canvas_mentions/plugin'
import positionCursor from './PositionCursorHook'
import {ReplyPreview} from '../ReplyPreview/ReplyPreview'
import {Spinner} from '@instructure/ui-spinner'
import {AttachmentDisplay} from '../AttachmentDisplay/AttachmentDisplay'

const I18n = useI18nScope('discussion_posts')

export const DiscussionEdit = props => {
  const rceRef = useRef()
  const [rceContent, setRceContent] = useState(false)
  const [includeQuotedReply, setIncludeQuotedReply] = useState(!!props.quotedEntry?.previewMessage)
  const textAreaId = useRef(`message-body-${nanoid()}`) // for VICE-3279 change `message-body-${nanoid()}` to `message-body-${props.rceIdentifier}`
  const [draftTimeout, setDraftTimeout] = useState(null)
  const [awaitingChanges, setAwaitingChanges] = useState(false)
  const [anonymousAuthorState, setAnonymousAuthorState] = useState(
    !!props.discussionAnonymousState && props.canReplyAnonymously
  )

  const [attachment, setAttachment] = useState(null)
  const [attachmentToUpload, setAttachmentToUpload] = useState(false)

  const rceMentionsIsEnabled = () => {
    return !!ENV.rce_mentions_in_discussions
  }

  const getPlugins = () => {
    const plugins = []

    // Non-Editable
    plugins.push('noneditable')

    // Mentions
    if (rceMentionsIsEnabled()) {
      plugins.push(mentionsPluginName)
    }

    return plugins
  }

  useEffect(() => {
    setRceContent(props.value)
    setAttachment(props.attachment)
  }, [props.value, setRceContent, props.attachment])

  const handleDraftResponse = nextDraft => {
    if (!ENV.draft_discussions) return
    if (!nextDraft) return

    setAwaitingChanges(true)
    if (draftTimeout) {
      clearTimeout(draftTimeout)
      setDraftTimeout(
        setTimeout(() => {
          setAwaitingChanges(false)
          props.onSetDraftSaved(false)
          props.updateDraft(nextDraft)
        }, 1000)
      )
    } else {
      setDraftTimeout(
        setTimeout(() => {
          setAwaitingChanges(false)
          props.onSetDraftSaved(false)
          props.updateDraft(nextDraft)
        }, 1000)
      )
    }
  }

  return (
    <div
      style={{
        width: '100%',
        // props.show allows you to load an RCE without displaying it which can aleviate load times
        display: props.show ? '' : 'none',
      }}
      data-testid="DiscussionEdit-container"
    >
      {props.quotedEntry?.previewMessage && (
        <span className="discussions-include-reply">
          <View as="div" margin="0 0 small 0">
            <Checkbox
              label={I18n.t('Include quoted reply in message')}
              variant="toggle"
              value="medium"
              checked={includeQuotedReply}
              onChange={() => {
                setIncludeQuotedReply(!includeQuotedReply)
              }}
            />
          </View>
          <ReplyPreview {...props.quotedEntry} />
        </span>
      )}
      {props.discussionAnonymousState && props.canReplyAnonymously && !props.isEdit && (
        <AnonymousResponseSelector
          username={ENV.current_user?.display_name}
          avatarUrl={ENV.current_user?.avatar_image_url}
          discussionAnonymousState={props.discussionAnonymousState}
          setAnonymousAuthorState={setAnonymousAuthorState}
        />
      )}
      <View display="block">
        <span className="discussions-editor">
          <CanvasRce
            textareaId={textAreaId.current}
            onFocus={() => {}}
            onBlur={() => {}}
            onInit={() => {
              setTimeout(() => {
                rceRef?.current?.focus()
                positionCursor(rceRef)
              }, 1000)
              props.onInit()
            }}
            ref={rceRef}
            onContentChange={content => {
              setRceContent(content)
              handleDraftResponse(content)
            }}
            editorOptions={{
              focus: true,
              plugins: getPlugins(),
            }}
            height={300}
            defaultContent={props.value}
            mirroredAttrs={{'data-testid': 'message-body'}}
          />
        </span>
        <Responsive
          match="media"
          query={responsiveQuerySizes({mobile: true, desktop: true})}
          props={{
            mobile: {
              direction: 'column',
              display: 'block',
              marginCancel: 'xx-small',
              marginReply: 'xx-small',
              paddingAttachment: 'xx-small',
              viewAs: 'div',
            },
            desktop: {
              direction: 'row',
              display: 'inline-block',
              marginCancel: '0 0 0 0',
              marginReply: '0 0 0 small',
              paddingAttachment: '0 0 0 0',
              viewAs: 'span',
            },
          }}
          render={(responsiveProps, matches) => {
            const rceButtons = [
              <View
                as={responsiveProps.viewAs}
                padding={responsiveProps.marginCancel}
                key="cancelButton"
              >
                <span className="discussions-editor-cancel">
                  <Button
                    onClick={() => {
                      if (props.onCancel) {
                        props.onCancel()
                      }
                    }}
                    display={responsiveProps.display}
                    color="secondary"
                    data-testid="DiscussionEdit-cancel"
                    key="rce-cancel-button"
                  >
                    <Text size="medium">{I18n.t('Cancel')}</Text>
                  </Button>
                </span>
              </View>,
              <View
                as={responsiveProps.viewAs}
                padding={responsiveProps.marginReply}
                key="replyButton"
              >
                <span className="discussions-editor-submit">
                  <Button
                    onClick={() => {
                      if (props.onSubmit) {
                        if (showErrorWhenMessageTooLong(rceContent)) {
                          return
                        }
                        localStorage.removeItem(
                          `rceautosave:${ENV.current_user_id}${window.location?.href}:${textAreaId.current}`
                        )
                        props.onSubmit(
                          rceContent,
                          includeQuotedReply ? props.quotedEntry.id : null,
                          attachment,
                          anonymousAuthorState
                        )
                      }
                    }}
                    display={responsiveProps.display}
                    color="primary"
                    data-testid="DiscussionEdit-submit"
                    key="rce-reply-button"
                    interaction={attachmentToUpload ? 'disabled' : 'enabled'}
                  >
                    <Text size="medium">{props.isEdit ? I18n.t('Save') : I18n.t('Reply')}</Text>
                  </Button>
                </span>
              </View>,
            ]
            return matches.includes('mobile') ? (
              <View as="div" padding={undefined} key="mobileButtons">
                <View as={responsiveProps.viewAs} padding={responsiveProps.paddingAttachment}>
                  <AttachmentDisplay
                    attachment={attachment}
                    setAttachment={setAttachment}
                    setAttachmentToUpload={setAttachmentToUpload}
                    attachmentToUpload={attachmentToUpload}
                  />
                </View>
                {rceButtons.reverse()}
              </View>
            ) : (
              <Flex key="nonMobileButtons">
                <Flex.Item shouldGrow={true} textAlign="start">
                  <View as={responsiveProps.viewAs} padding={responsiveProps.paddingAttachment}>
                    <AttachmentDisplay
                      attachment={attachment}
                      setAttachment={setAttachment}
                      setAttachmentToUpload={setAttachmentToUpload}
                      attachmentToUpload={attachmentToUpload}
                    />
                  </View>
                </Flex.Item>
                {ENV.draft_discussions && (
                  <Flex.Item shouldGrow={true} textAlign="start">
                    {props.draftSaved ? (
                      !awaitingChanges && (
                        <span>
                          <Text size="small">{I18n.t('Saved')}</Text>
                          <View as="span" margin="0 0 0 small">
                            <IconCheckMarkLine color="success" />
                          </View>
                        </span>
                      )
                    ) : (
                      <span>
                        <Text size="small">{I18n.t('Saving')}</Text>
                        <Spinner
                          renderTitle="Saving draft in progress"
                          margin="0 0 0 small"
                          size="x-small"
                        />
                      </span>
                    )}
                  </Flex.Item>
                )}
                <Flex.Item shouldGrow={true} textAlign="end">
                  {rceButtons}
                </Flex.Item>
              </Flex>
            )
          }}
        />
      </View>
    </div>
  )
}

DiscussionEdit.propTypes = {
  show: PropTypes.bool,
  rceIdentifier: PropTypes.string,
  discussionAnonymousState: PropTypes.string,
  canReplyAnonymously: PropTypes.bool,
  draftSaved: PropTypes.bool,
  value: PropTypes.string,
  attachment: PropTypes.object,
  onCancel: PropTypes.func.isRequired,
  onSubmit: PropTypes.func.isRequired,
  onSetDraftSaved: PropTypes.func,
  isEdit: PropTypes.bool,
  quotedEntry: PropTypes.object,
  updateDraft: PropTypes.func,
  onInit: PropTypes.func,
}

DiscussionEdit.defaultProps = {
  show: true,
  isEdit: false,
  quotedEntry: null,
  value: '',
  updateDraft: () => {},
  onInit: () => {},
}

export default DiscussionEdit
