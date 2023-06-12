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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {getAutoTrack} from '@canvas/canvas-media-player'
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import {bool, func, string} from 'prop-types'
import elideString from '../../helpers/elideString'
import {isSubmitted} from '../../helpers/SubmissionHelpers'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconTrashLine, IconUploadLine, IconAttachMediaSolid} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import LoadingIndicator from '@canvas/loading-indicator'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import StudentViewContext from '../Context'
import PhotographerPandaSVG from '../../../images/PhotographerPanda.svg'
import UploadFileSVG from '../../../images/UploadFile.svg'
import UploadMedia from '@instructure/canvas-media'
import {
  UploadMediaStrings,
  MediaCaptureStrings,
  SelectStrings,
} from '@canvas/upload-media-translations'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {MediaPlayer} from '@instructure/ui-media-player'
import theme from '@instructure/canvas-theme'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('assignments_2_media_attempt')

export const VIDEO_SIZE_OPTIONS = {height: '400px', width: '768px'}

class MediaAttempt extends React.Component {
  static propTypes = {
    assignment: Assignment.shape.isRequired,
    breakpoints: breakpointsShape,
    createSubmissionDraft: func.isRequired,
    focusOnInit: bool.isRequired,
    submission: Submission.shape.isRequired,
    updateUploadingFiles: func.isRequired,
    uploadingFiles: bool.isRequired,
    setIframeURL: func.isRequired,
    iframeURL: string,
  }

  state = {
    mediaModalOpen: false,
    mediaModalTabs: {record: false, upload: false},
  }

  componentDidMount() {
    if (
      this.props.focusOnInit &&
      !this.props.uploadingFiles &&
      !isSubmitted(this.props.submission) &&
      !this.props.submission.submissionDraft?.mediaObject?._id
    ) {
      this._mediaUploadRef.focus()
    }
  }

  onComplete = (err, data) => {
    if (err) {
      this.context.setOnFailure(I18n.t('There was an error submitting your attempt.'))
    } else {
      this.props.updateUploadingFiles(true)
      if (data.mediaObject.embedded_iframe_url) {
        this.props.setIframeURL(data.mediaObject.embedded_iframe_url)
      }
      this.props.createSubmissionDraft({
        variables: {
          id: this.props.submission.id,
          activeSubmissionType: 'media_recording',
          attempt: this.props.submission.attempt || 1,
          mediaId: data.mediaObject.media_object.media_id,
        },
      })
    }
  }

  onDismiss = () => {
    this.setState({mediaModalOpen: false})
  }

  handleRemoveFile = () => {
    this.props.updateUploadingFiles(true)
    this.props.createSubmissionDraft({
      variables: {
        id: this.props.submission.id,
        activeSubmissionType: 'media_recording',
        attempt: this.props.submission.attempt || 1,
      },
    })
    this.props.setIframeURL('')
  }

  renderMediaPlayer = (mediaObject, renderTrashIcon) => {
    if (!mediaObject) {
      return null
    }
    mediaObject.mediaSources.forEach(mediaSource => {
      mediaSource.label = `${mediaSource.width}x${mediaSource.height}`
    })
    const mediaTracks = mediaObject.mediaTracks.map(track => ({
      src: `/media_objects/${mediaObject._id}/media_tracks/${track._id}`,
      label: track.locale,
      type: track.kind,
      language: track.locale,
    }))
    const shouldRenderWithIframeURL = mediaObject.mediaSources.length === 0 && this.props.iframeURL
    const autoCCTrack = getAutoTrack(mediaObject.mediaTracks)
    return (
      <Flex direction="column" alignItems="center">
        <Flex.Item data-testid="media-recording" width="100%">
          {shouldRenderWithIframeURL ? (
            <div
              style={{
                position: 'relative',
                width: '100%',
                height: '0',
                paddingBottom: '56.25%', // 16:9 aspect ratio
              }}
            >
              <iframe
                src={this.props.iframeURL}
                title="preview"
                style={{
                  position: 'absolute',
                  border: 'none',
                  minWidth: '100%',
                  minHeight: '100%',
                }}
              />
            </div>
          ) : (
            <MediaPlayer
              tracks={mediaTracks}
              sources={mediaObject.mediaSources}
              captionPosition="bottom"
              autoShowCaption={autoCCTrack}
            />
          )}
        </Flex.Item>
        <Flex.Item overflowY="visible" margin="medium 0">
          <span aria-hidden={true} title={mediaObject.title}>
            {elideString(mediaObject.title)}
          </span>
          <ScreenReaderContent>{mediaObject.title}</ScreenReaderContent>
          {renderTrashIcon && (
            <Button
              data-testid="remove-media-recording"
              renderIcon={IconTrashLine}
              id={mediaObject.id}
              margin="0 0 0 x-small"
              onClick={this.handleRemoveFile}
              size="small"
            >
              <ScreenReaderContent>
                {I18n.t('Remove %{filename}', {filename: mediaObject.title})}
              </ScreenReaderContent>
            </Button>
          )}
        </Flex.Item>
      </Flex>
    )
  }

  renderSubmissionDraft = () => {
    const mediaObject = this.props.submission.submissionDraft.mediaObject
    return this.renderMediaPlayer(mediaObject, true)
  }

  renderSubmission = () => {
    const mediaObject = this.props.submission.mediaObject
    return this.renderMediaPlayer(mediaObject, false)
  }

  renderMediaUpload = () => {
    const {desktop} = this.props.breakpoints
    return (
      <>
        <UploadMedia
          onUploadComplete={this.onComplete}
          onDismiss={this.onDismiss}
          rcsConfig={{
            contextId: ENV.current_user.id,
            contextType: 'user',
          }}
          open={this.state.mediaModalOpen}
          tabs={this.state.mediaModalTabs}
          uploadMediaTranslations={{UploadMediaStrings, MediaCaptureStrings, SelectStrings}}
          liveRegion={() => document.getElementById('flash_screenreader_holder')}
          userLocale={ENV.LOCALE}
        />
        <StudentViewContext.Consumer>
          {context => (
            <Flex alignItems="center" justifyItems="center" direction={desktop ? 'row' : 'column'}>
              <Flex.Item margin="small">
                <View
                  as="div"
                  height="350px"
                  width="400px"
                  borderRadius="large"
                  background="primary"
                >
                  <Flex
                    direction="column"
                    alignItems="center"
                    justifyItems="space-around"
                    height="100%"
                    shouldShrink={true}
                  >
                    <Flex.Item>
                      <Img
                        src={PhotographerPandaSVG}
                        alt={I18n.t('panda taking photograph')}
                        height="180px"
                      />
                    </Flex.Item>
                    <Flex.Item overflowY="visible">
                      <Button
                        data-testid="open-record-media-modal-button"
                        disabled={!context.allowChangesToSubmission}
                        renderIcon={IconAttachMediaSolid}
                        color="primary"
                        elementRef={el => {
                          this._mediaUploadRef = el
                        }}
                        onClick={() =>
                          this.setState({
                            mediaModalTabs: {record: true, upload: false},
                            mediaModalOpen: true,
                          })
                        }
                      >
                        {I18n.t('Record Media')}
                      </Button>
                    </Flex.Item>
                  </Flex>
                </View>
              </Flex.Item>
              <Flex.Item margin="medium">
                <Flex
                  direction={desktop ? 'column' : 'row'}
                  justifyItems="space-between"
                  alignItems="center"
                >
                  <Flex.Item>
                    <div
                      style={{
                        backgroundColor: theme.variables.colors.backgroundDark,
                        height: desktop ? '9em' : '1px',
                        width: desktop ? '1px' : '9em',
                      }}
                    />
                  </Flex.Item>
                  <Flex.Item color="darkgrey" margin="small">
                    {I18n.t('or')}
                  </Flex.Item>
                  <Flex.Item>
                    <div
                      style={{
                        backgroundColor: theme.variables.colors.backgroundDark,
                        height: desktop ? '9em' : '1px',
                        width: desktop ? '1px' : '9em',
                      }}
                    />
                  </Flex.Item>
                </Flex>
              </Flex.Item>
              <Flex.Item margin="medium">
                <View
                  as="div"
                  height="350px"
                  width="400px"
                  borderRadius="large"
                  background="primary"
                >
                  <Flex
                    direction="column"
                    alignItems="center"
                    justifyItems="space-around"
                    height="100%"
                    shouldShrink={true}
                  >
                    <Flex.Item>
                      <Img
                        src={UploadFileSVG}
                        alt={I18n.t('rocketship on launchpad')}
                        height="180px"
                      />
                    </Flex.Item>
                    <Flex.Item overflowY="visible">
                      <Button
                        data-testid="open-upload-media-modal-button"
                        disabled={!context.allowChangesToSubmission}
                        renderIcon={IconUploadLine}
                        color="primary"
                        onClick={() =>
                          this.setState({
                            mediaModalTabs: {record: false, upload: true},
                            mediaModalOpen: true,
                          })
                        }
                      >
                        {I18n.t('Upload Media')}
                      </Button>
                    </Flex.Item>
                  </Flex>
                </View>
              </Flex.Item>
            </Flex>
          )}
        </StudentViewContext.Consumer>
      </>
    )
  }

  render() {
    if (this.props.uploadingFiles) {
      return <LoadingIndicator />
    }

    if (isSubmitted(this.props.submission)) {
      return this.renderSubmission()
    }

    if (this.props.submission.submissionDraft?.mediaObject?._id) {
      return this.renderSubmissionDraft()
    }

    return this.renderMediaUpload()
  }
}

MediaAttempt.contextType = AlertManagerContext

export default WithBreakpoints(MediaAttempt)
