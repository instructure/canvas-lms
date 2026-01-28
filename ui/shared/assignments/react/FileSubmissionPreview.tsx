/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useEffect, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {getIconByType} from '@canvas/mime/react/mimeClassIconHelper'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconDownloadLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Attachment, Submission} from './AssignmentsPeerReviewsStudentTypes'
import previewUnavailable from '@canvas/assignments/images/PreviewUnavailable.svg'
import {View} from '@instructure/ui-view'
import {Img} from '@instructure/ui-img'
import {List} from '@instructure/ui-list'

const I18n = createI18nScope('peer_reviews_student')

interface FileSubmissionPreviewProps {
  submission: Submission
}

type SelectFileFn = (index: number) => void

const renderIcon = (
  file: {displayName: string; mimeClass: string},
  index: number,
  selectFileFn: SelectFileFn,
) => {
  return (
    <IconButton
      size="medium"
      withBackground={false}
      withBorder={false}
      onClick={() => selectFileFn(index)}
      renderIcon={getIconByType(file.mimeClass)}
      screenReaderLabel={file.displayName}
    />
  )
}

const shouldDisplayThumbnail = (file: {mimeClass: string; thumbnailUrl?: string | null}) => {
  return file.mimeClass === 'image' && file.thumbnailUrl
}

const renderThumbnail = (
  file: {displayName: string; thumbnailUrl?: string | null},
  index: number,
  selectFileFn: SelectFileFn,
) => {
  return (
    <IconButton
      onClick={() => selectFileFn(index)}
      size="medium"
      screenReaderLabel={file.displayName}
      withBorder={false}
    >
      <img
        alt={I18n.t('%{filename} preview', {filename: file.displayName})}
        src={file.thumbnailUrl || ''}
      />
    </IconButton>
  )
}

const renderFileDetailsTable = (attachments: Attachment[], selectFileFn: SelectFileFn) => {
  return (
    <List
      isUnstyled
      itemSpacing="xxx-small"
      margin="x-small 0 0 0"
      data-testid="uploaded_files_table"
    >
      {attachments.map((file, index) => (
        <List.Item key={file._id}>
          {shouldDisplayThumbnail(file)
            ? renderThumbnail(file, index, selectFileFn)
            : renderIcon(file, index, selectFileFn)}
          <Link onClick={() => selectFileFn(index)} isWithinText={false}>
            <Text>{file.displayName}</Text>
          </Link>
          <View margin="0 0 0 xx-small" data-testid="file-size">
            <Text size="x-small">{file.size}</Text>
          </View>
        </List.Item>
      ))}
    </List>
  )
}

const renderUnavailablePreview = (message: string) => {
  return (
    <View textAlign="center">
      <Img src={previewUnavailable} width="150px" alt={I18n.t('Preview unavailable')}></Img>
      <View padding="small" display="block">
        <Text size="large">{message}</Text>
      </View>
    </View>
  )
}

const renderFilePreview = (selectedFile?: Attachment) => {
  if (!selectedFile) {
    return renderUnavailablePreview(I18n.t('No Submission'))
  }

  const iframeStyle = {
    border: 'none',
    width: '100%',
    height: '100%',
    borderLeft: '0px',
  }

  if (!selectedFile.submissionPreviewUrl) {
    return (
      <View display="block" textAlign="center" padding="medium" borderWidth="none none none small">
        {renderUnavailablePreview(I18n.t('Preview Unavailable'))}
        <Text>{selectedFile.displayName}</Text>
        <View display="block">
          <Button
            margin="medium auto"
            renderIcon={<IconDownloadLine />}
            href={selectedFile.url ?? ''}
            disabled={!selectedFile.url}
          >
            {I18n.t('Download')}
          </Button>
        </View>
      </View>
    )
  }

  return (
    <View display="block" data-testid="file_submission_preview" height="100%" minHeight="600px">
      <ScreenReaderContent>{selectedFile.displayName}</ScreenReaderContent>
      <iframe
        src={selectedFile.submissionPreviewUrl}
        title="preview"
        style={iframeStyle}
        allowFullScreen={true}
      />
    </View>
  )
}

const FileSubmissionPreview = ({submission}: FileSubmissionPreviewProps) => {
  const defaultSelectedFileIndex = 0
  const [selectedFileIndex, setSelectedFileIndex] = useState(defaultSelectedFileIndex)

  useEffect(() => {
    setSelectedFileIndex(defaultSelectedFileIndex)
  }, [submission])

  const selectFile = (index: number) => {
    if (submission.attachments && index >= 0 && index < submission.attachments.length) {
      setSelectedFileIndex(index)
    }
  }

  if (!submission.attachments || submission.attachments.length === 0) {
    return renderUnavailablePreview(I18n.t('No Submission'))
  }

  return (
    <Flex
      data-testid="file-preview"
      direction="column"
      width="100%"
      height="100%"
      alignItems="stretch"
    >
      {submission.attachments.length > 1 && (
        <Flex.Item padding="0" margin="0 0 x-small 0">
          {renderFileDetailsTable(submission.attachments, selectFile)}
        </Flex.Item>
      )}
      <Flex.Item shouldGrow shouldShrink>
        {renderFilePreview(submission.attachments[selectedFileIndex])}
      </Flex.Item>
    </Flex>
  )
}

export default FileSubmissionPreview
