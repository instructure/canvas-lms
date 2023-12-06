/* eslint-disable @typescript-eslint/no-unused-vars */
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

import {getIconByType} from '@canvas/mime/react/mimeClassIconHelper'
import {useScope as useI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import previewUnavailable from '../../../images/PreviewUnavailable.svg'
import React, {useState, useEffect, useRef, useMemo} from 'react'
import {bool} from 'prop-types'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import elideString from '../../helpers/elideString'
import OriginalityReport from '../OriginalityReport'

import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconDownloadLine, IconCompleteSolid} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import theme from '@instructure/canvas-theme'
import {Table} from '@instructure/ui-table'
import {Link} from '@instructure/ui-link'
import {getOriginalityData} from '@canvas/grading/originalityReportHelper'

const I18n = useI18nScope('assignments_2')

export default function FilePreview({submission, isOriginalityReportVisible}) {
  const [selectedFileIndex, setSelectedFileIndex] = useState(0)

  useEffect(() => {
    setSelectedFileIndex(0)
  }, [submission.attempt])

  const translateMimeClass = mimeClass => {
    switch (mimeClass) {
      case 'audio':
        return I18n.t('audio')
      case 'code':
        return I18n.t('code')
      case 'doc':
        return I18n.t('doc')
      case 'flash':
        return I18n.t('flash')
      case 'html':
        return I18n.t('html')
      case 'image':
        return I18n.t('image')
      case 'pdf':
        return I18n.t('pdf')
      case 'ppt':
        return I18n.t('ppt')
      case 'text':
        return I18n.t('text')
      case 'video':
        return I18n.t('video')
      case 'xls':
        return I18n.t('xls')
      case 'zip':
        return I18n.t('zip')
      default:
        return I18n.t('file')
    }
  }

  const capitalize = s => {
    if (typeof s !== 'string') return ''
    return s.charAt(0).toUpperCase() + s.slice(1)
  }

  const selectFile = index => {
    if (index >= 0 || index < submission.attachments.length) {
      setSelectedFileIndex(index)
    }
  }

  const shouldDisplayThumbnail = file => {
    return file.mimeClass === 'image' && file.thumbnailUrl
  }

  const renderThumbnail = (file, index) => {
    return (
      <IconButton
        onClick={() => selectFile(index)}
        size="large"
        screenReaderLabel={file.displayName}
        withBorder={false}
      >
        <img
          alt={I18n.t('%{filename} preview', {filename: file.displayName})}
          src={file.thumbnailUrl}
        />
      </IconButton>
    )
  }

  const renderIcon = (file, index) => {
    return (
      <IconButton
        size="large"
        withBackground={false}
        withBorder={false}
        onClick={() => selectFile(index)}
        renderIcon={getIconByType(file.mimeClass)}
        screenReaderLabel={file.displayName}
      />
    )
  }

  const renderFileIcons = () => {
    const cellTheme = {background: theme.variables.colors.backgroundLight}
    return (
      <Table caption={I18n.t('Uploaded files')} data-testid="uploaded_files_table">
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="thumbnail" width="1rem" themeOverride={cellTheme} />
            <Table.ColHeader id="filename" themeOverride={cellTheme}>
              {I18n.t('File Name')}
            </Table.ColHeader>
            <Table.ColHeader id="size" themeOverride={cellTheme}>
              {I18n.t('Size')}
            </Table.ColHeader>
            <Table.ColHeader id="originality_report" themeOverride={cellTheme} />
            <Table.ColHeader id="upload-success" width="1rem" themeOverride={cellTheme} />
          </Table.Row>
        </Table.Head>
        <Table.Body>
          {submission.attachments.map((file, index) => (
            <Table.Row key={file._id}>
              <Table.Cell themeOverride={cellTheme}>
                {shouldDisplayThumbnail(file)
                  ? renderThumbnail(file, index)
                  : renderIcon(file, index)}
              </Table.Cell>
              <Table.Cell themeOverride={cellTheme}>
                <>
                  <Link onClick={() => selectFile(index)}>
                    {elideString(file.displayName || file.name)}
                  </Link>
                  <ScreenReaderContent>{file.displayName || file.name}</ScreenReaderContent>
                </>
              </Table.Cell>
              <Table.Cell themeOverride={cellTheme} data-testid="file-size">
                {file.size}
              </Table.Cell>
              <Table.Cell themeOverride={cellTheme}>
                {submission.originalityData &&
                  isOriginalityReportVisible &&
                  getOriginalityData(submission, index) && (
                    <Flex.Item>
                      <OriginalityReport originalityData={getOriginalityData(submission, index)} />
                    </Flex.Item>
                  )}
              </Table.Cell>
              <Table.Cell themeOverride={cellTheme}>
                <IconCompleteSolid color="success" />
              </Table.Cell>
            </Table.Row>
          ))}
        </Table.Body>
      </Table>
    )
  }

  const renderUnavailablePreview = message => {
    return (
      <div style={{textAlign: 'center'}}>
        <img alt="" src={previewUnavailable} style={{width: '150px'}} />
        <div
          style={{
            display: 'block',
            padding: `
              ${theme.variables.spacing.large}
              ${theme.variables.spacing.medium}
              0
              ${theme.variables.spacing.medium}
            `,
          }}
        >
          <Text size="large">{message}</Text>
        </div>
      </div>
    )
  }

  const renderFilePreview = () => {
    const iframeContainerStyle = {
      maxWidth: '1366px',
      height: '0',
      paddingBottom: '130%',
      position: 'relative',
    }

    const iframeStyle = {
      border: 'none',
      width: '100%',
      height: '100%',
      position: 'absolute',
      borderLeft: `1px solid ${theme.variables.colors.borderMedium}`,
    }
    const selectedFile = submission.attachments[selectedFileIndex]
    if (selectedFile && !selectedFile.submissionPreviewUrl) {
      return (
        <div
          style={{
            textAlign: 'center',
            padding: `${theme.variables.spacing.medium} 0 0 0`,
            borderLeft: `1px solid ${theme.variables.colors.borderMedium}`,
          }}
        >
          <div style={{display: 'block'}}>
            {renderUnavailablePreview(I18n.t('Preview Unavailable'))}
            {selectedFile.displayName}
            <div style={{display: 'block'}}>
              <Button
                margin="medium auto"
                renderIcon={IconDownloadLine}
                href={selectedFile.url}
                disabled={!selectedFile.url}
              >
                {I18n.t('Download')}
              </Button>
            </div>
          </div>
        </div>
      )
    }

    return (
      <div style={iframeContainerStyle} data-testid="assignments_2_submission_preview">
        <ScreenReaderContent>{selectedFile?.displayName}</ScreenReaderContent>
        <iframe
          src={selectedFile?.submissionPreviewUrl}
          title="preview"
          style={iframeStyle}
          allowFullScreen={true}
        />
      </div>
    )
  }

  const renderFilePreviewContent = () => {
    if (submission.attachments.length) {
      return (
        <Flex data-testid="file-preview" direction="column" width="100%" alignItems="stretch">
          {submission.attachments.length > 1 && (
            <Flex.Item padding="0 x-large x-large">{renderFileIcons()}</Flex.Item>
          )}
          <Flex.Item>{renderFilePreview()}</Flex.Item>
        </Flex>
      )
    } else {
      return renderUnavailablePreview(I18n.t('No Submission'))
    }
  }

  return <>{!submission.attachments ? <LoadingIndicator /> : renderFilePreviewContent()}</>
}

FilePreview.propTypes = {
  submission: Submission.shape,
  isOriginalityReportVisible: bool,
}
