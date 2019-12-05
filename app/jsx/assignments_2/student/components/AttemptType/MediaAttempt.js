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

import {Assignment} from '../../graphqlData/Assignment'
import {bool, func} from 'prop-types'
import closedCaptionLanguages from '../../../../shared/closedCaptionLanguages'
import elideString from '../../../../shared/helpers/elideString'
import I18n from 'i18n!assignments_2_media_attempt'
import {IconTrashLine, IconAttachMediaLine} from '@instructure/ui-icons'
import LoadingIndicator from '../../../shared/LoadingIndicator'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {Submission} from '../../graphqlData/Submission'
import UploadMedia from '@instructure/canvas-media'
import {UploadMediaStrings, MediaCaptureStrings} from '../../../../shared/UploadMediaTranslations'

import {Billboard} from '@instructure/ui-billboard'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {VideoPlayer} from '@instructure/ui-media-player'
import {View} from '@instructure/ui-layout'

const languages = Object.keys(closedCaptionLanguages).map(key => {
  return {id: key, label: closedCaptionLanguages[key]}
})

export const VIDEO_SIZE_OPTIONS = {height: '400px', width: '768px'}

export default class MediaAttempt extends React.Component {
  static propTypes = {
    assignment: Assignment.shape.isRequired,
    createSubmissionDraft: func.isRequired,
    submission: Submission.shape.isRequired,
    updateUploadingFiles: func.isRequired,
    uploadingFiles: bool.isRequired
  }

  state = {
    mediaModalOpen: false,
    iframeURL: ''
  }

  onComplete = (err, data) => {
    this.props.updateUploadingFiles(true)
    if (data.mediaObject.embedded_iframe_url) {
      this.setState({iframeURL: data.mediaObject.embedded_iframe_url})
    }
    this.props.createSubmissionDraft({
      variables: {
        id: this.props.submission.id,
        activeSubmissionType: 'media_recording',
        attempt: this.props.submission.attempt || 1,
        mediaId: data.mediaObject.media_object.media_id
      }
    })
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
        attempt: this.props.submission.attempt || 1
      }
    })
    this.setState({iframeURL: ''})
  }

  renderMediaPlayer = (mediaObject, renderTrashIcon) => {
    mediaObject.mediaSources.forEach(mediaSource => {
      mediaSource.label = `${mediaSource.width}x${mediaSource.height}`
    })
    const mediaTracks = mediaObject.mediaTracks.map(track => ({
      src: `/media_objects/${mediaObject._id}/media_tracks/${track._id}`,
      label: track.locale,
      type: track.kind,
      language: track.locale
    }))
    const shouldRenderWithIframeURL = mediaObject.mediaSources.length === 0 && this.state.iframeURL

    return (
      <Flex direction="column" alignItems="center">
        <Flex.Item data-testid="media-recording" width="100%">
          {shouldRenderWithIframeURL ? (
            <div
              style={{
                position: 'relative',
                width: '100%',
                height: '0',
                paddingBottom: '56.25%' // 16:9 aspect ratio
              }}
            >
              <iframe
                src={this.state.iframeURL}
                title="preview"
                style={{
                  position: 'absolute',
                  border: 'none',
                  minWidth: '100%',
                  minHeight: '100%'
                }}
              />
            </div>
          ) : (
            <VideoPlayer tracks={mediaTracks} sources={mediaObject.mediaSources} />
          )}
        </Flex.Item>
        <Flex.Item overflowY="visible" margin="medium 0">
          <span aria-hidden title={mediaObject.title}>
            {elideString(mediaObject.title)}
          </span>
          <ScreenReaderContent>{mediaObject.title}</ScreenReaderContent>
          {renderTrashIcon && (
            <Button
              data-testid="remove-media-recording"
              icon={IconTrashLine}
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

  renderMediaUpload = () => (
    <View as="div" borderWidth="small">
      <UploadMedia
        onUploadComplete={this.onComplete}
        onDismiss={this.onDismiss}
        contextId={this.props.assignment.env.courseId}
        contextType="course"
        open={this.state.mediaModalOpen}
        tabs={{embed: false, record: true, upload: true}}
        uploadMediaTranslations={{UploadMediaStrings, MediaCaptureStrings}}
        liveRegion={() => document.getElementById('flash_screenreader_holder')}
        languages={languages}
      />
      <Billboard
        heading={I18n.t('Add Media')}
        hero={<IconAttachMediaLine color="brand" />}
        message={
          <Button
            size="small"
            data-testid="media-modal-launch-button"
            variant="primary"
            onClick={() => this.setState({mediaModalOpen: true})}
          >
            {I18n.t('Record/Upload')}
          </Button>
        }
      />
    </View>
  )

  render() {
    if (this.props.uploadingFiles) {
      return <LoadingIndicator />
    }

    if (['submitted', 'graded'].includes(this.props.submission.state)) {
      return this.renderSubmission()
    }

    if (this.props.submission.submissionDraft?.mediaObject?._id) {
      return this.renderSubmissionDraft()
    }

    return this.renderMediaUpload()
  }
}
