// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useRef, useState} from 'react'
import {useMutation} from 'react-apollo'
import {CREATE_SUBMISSION} from '@canvas/assignments/graphql/student/Mutations'
import axios from '@canvas/axios'
import {useScope as useI18nScope} from '@canvas/i18n'
import {CamelizedAssignment} from '@canvas/grading/grading'
import {getFileThumbnail} from '@canvas/util/fileHelper'
import {uploadFile} from '@canvas/upload-file'
import theme from '@instructure/canvas-theme'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Alert, AlertVariant} from '@instructure/ui-alerts'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {IconCompleteSolid, IconTrashLine, IconCheckLine} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {FileDrop} from '@instructure/ui-file-drop'
import {Flex} from '@instructure/ui-flex'
import {Modal} from '@instructure/ui-modal'
import {ProgressBar} from '@instructure/ui-progress'
import {Spinner} from '@instructure/ui-spinner'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import UploadFileSVG from '../../../features/assignments_show_student/images/UploadFile.svg'

const I18n = useI18nScope('conversations_2')

const {
  Cell: TableCell,
  Body: TableBody,
  Row: TableRow,
  ColHeader: TableColHeader,
  Head: TableHead,
} = Table as any

const {Item: FlexItem} = Flex as any

type AlertType = {
  text: string
  variant: AlertVariant
}

type FileUploadType = {
  _id: string
  index: number
  isLoading: boolean
  name: string
  loaded: number
  total: number
}

export type ProxyUploadModalProps = {
  open: boolean
  onClose: () => void
  assignment: Pick<CamelizedAssignment, 'id' | 'courseId' | 'groupSet'>
  student: {
    id: string
    name: string
  }
  submission: {
    id: string
  }
  reloadSubmission: (proxyDetails) => void
}

export type ProxyDetails = {
  submission_type: 'online_upload'
  proxy_submitter: string
  workflow_state: 'submitted'
  submitted_at: string
}

const elideString = title => {
  if (title.length > 21) {
    return `${title.substr(0, 9)}${I18n.t('...')}${title.substr(-9)}`
  } else {
    return title
  }
}

const ProxyUploadContainer = (props: ProxyUploadModalProps) => {
  // https://beta.reactjs.org/learn/you-might-not-need-an-effect#resetting-all-state-when-a-prop-changes
  return <ProxyUploadModal {...props} key={`${props.assignment.id}-${props.student.id}`} />
}

const ProxyUploadModal = ({
  open,
  onClose,
  assignment,
  student,
  submission,
  reloadSubmission,
}: ProxyUploadModalProps) => {
  const [alert, setAlert] = useState<AlertType | null>(null)
  const [filesToUpload, setFilesToUpload] = useState<FileUploadType[]>([])
  const [uploadedFiles, setUploadedFiles] = useState<any[]>([])
  const [filesUploading, setFilesUploading] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [uploadSuccess, setUploadSuccess] = useState(false)
  const containerRef = useRef<HTMLDivElement | null>(null)

  const [createSubmissionMutation] = useMutation(CREATE_SUBMISSION, {
    onCompleted: data =>
      data.createSubmission.errors ? handleFail() : handleSuccess(data.createSubmission.submission),
    onError: () => {
      handleFail()
    },
  })

  const resetState = () => {
    setAlert(null)
    setFilesToUpload([])
    setUploadedFiles([])
    setFilesUploading(false)
    setSubmitting(false)
    setUploadSuccess(false)
  }

  const handleSuccess = sub => {
    setAlert({text: I18n.t('Submission uploaded successfully!'), variant: 'success'})
    setUploadSuccess(true)
    setTimeout(() => reload(sub), 3000)
  }

  const handleFail = () => {
    setSubmitting(false)
    setAlert({text: I18n.t('Error sending submission'), variant: 'error'})
  }

  const reload = sub => {
    const proxyDetails: ProxyDetails = {
      submission_type: 'online_upload',
      proxy_submitter: sub.proxySubmitter,
      workflow_state: 'submitted',
      submitted_at: sub.submittedAt,
    }
    reloadSubmission(proxyDetails)
    onClose()
    resetState()
  }

  const handleSubmitClick = e => {
    e.preventDefault()
    setSubmitting(true)
    createSubmissionMutation({
      variables: {
        assignmentLid: assignment.id,
        submissionID: submission.id,
        fileIds: uploadedFiles.map(file => file.id),
        studentId: student.id,
        type: 'online_upload',
      },
    })
  }

  const handleDropAccept = async files => {
    if (!files.length) {
      setAlert({text: I18n.t('Error adding files'), variant: 'error'})
      return
    }
    await onUploadRequested({
      files,
      onError: () => {
        setAlert({text: I18n.t('Error uploading files'), variant: 'error'})
      },
      onSuccess: () => {
        setAlert({text: I18n.t('Uploading files'), variant: 'success'})
      },
    })
  }

  const onUploadRequested = async ({files, onSuccess, onError}) => {
    const newFiles = files.map((file, i) => {
      // "text" is filename in LTI Content Item
      const name = file.name || file.text || file.url
      const _id = `${i}-${file.url || file.name}`

      // As we receive progress events for this upload, we'll update the
      // "loaded and "total" values. Set some placeholder values so that
      // we start at 0%.
      return {_id, index: i, isLoading: true, name, loaded: 0, total: 1}
    })
    setFilesToUpload(prevFiles => [...prevFiles, ...newFiles])
    onSuccess()

    updateUploadingFiles(async () => {
      try {
        const newUploadingFiles = await uploadFiles(files)
        setUploadedFiles(prevFiles => [...prevFiles, ...newUploadingFiles])
      } catch (err) {
        onError()
      } finally {
        setFilesToUpload([])
      }
    })
  }

  const updateUploadProgress = ({index, loaded, total}) => {
    setFilesToUpload(prevFiles => {
      const files = [...prevFiles]
      files[index] = {...files[index], loaded, total}
      return files
    })
  }

  const uploadFiles = async files => {
    // This is taken almost verbatim from the uploadFiles method in the
    // upload-file module.  Rather than calling that method, we call uploadFile
    // for each file to track progress for the individual uploads.
    const assignmentCourseId = assignment.courseId || assignment.course_id
    const uploadUrl =
      assignment.groupSet?.currentGroup == null
        ? `/api/v1/courses/${assignmentCourseId}/assignments/${assignment.id}/submissions/${student.id}/files`
        : `/api/v1/groups/${assignment.groupSet.currentGroup._id}/files`

    const uploadPromises: any[] = []
    files.forEach((file, i) => {
      const onProgress = event => {
        const {loaded, total} = event
        updateUploadProgress({index: i, loaded, total})
      }

      let promise
      if (file.url) {
        // LTI content item
        promise = uploadFile(
          uploadUrl,
          {
            url: file.url,
            name: file.text,
            content_type: file.mediaType,
            submit_assignment: false,
          },
          null,
          axios,
          onProgress,
          true
        )
      } else {
        promise = uploadFile(
          uploadUrl,
          {
            name: file.name,
            content_type: file.type,
            submit_assignment: true,
          },
          file,
          axios,
          onProgress,
          true
        )
      }
      uploadPromises.push(promise)
    })

    return Promise.all(uploadPromises)
  }

  const handleRemoveFile = e => {
    const target = e.currentTarget
    const fileId = parseInt(target.id, 10)
    const fileIndex = uploadedFiles.findIndex(file => parseInt(file.id, 10) === fileId)

    const updatedFiles = uploadedFiles.filter((_, i) => i !== fileIndex)

    if (containerRef.current) {
      const focusable = Array.from(containerRef.current.querySelectorAll('input,button')) as (
        | HTMLInputElement
        | HTMLButtonElement
      )[]
      const indexFocus = focusable.findIndex(el => el === target)

      if (indexFocus > 0) {
        focusable[indexFocus - 1].focus()
      } else if (indexFocus === 0) {
        focusable[1].focus()
      }
    }

    setUploadedFiles(updatedFiles)
  }

  const updateUploadingFiles = async wrappedFunc => {
    setFilesUploading(true)
    await wrappedFunc()
    setFilesUploading(false)
  }

  const renderFileProgress = file => {
    // If we're calling this function, we know that "file" represents one of
    // the entries in filesToUpload, and so it will have values
    // representing the progress of the upload.
    const {name, loaded, total} = file

    return (
      <ProgressBar
        formatScreenReaderValue={({valueNow, valueMax}) => {
          return Math.round((valueNow / valueMax) * 100) + ' percent'
        }}
        meterColor="brand"
        screenReaderLabel={I18n.t('Upload progress for %{name}', {name})}
        size="x-small"
        valueMax={total}
        valueNow={loaded}
      />
    )
  }

  const renderFilesTable = () => {
    let files = uploadedFiles
    if (filesToUpload.length) {
      files = files.concat(filesToUpload)
    }

    if (files.length === 0) {
      return
    }

    const cellTheme = {background: theme.variables.colors.backgroundLight}

    return (
      <Table
        caption={I18n.t('Uploaded files')}
        data-testid="proxy_uploaded_files_table"
        margin="none none small none"
      >
        <TableHead>
          <TableRow>
            <TableColHeader id="thumbnail" width="1rem" theme={cellTheme}>
              <ScreenReaderContent>{I18n.t('File Type')}</ScreenReaderContent>
            </TableColHeader>
            <TableColHeader id="filename" theme={cellTheme}>
              {I18n.t('File Name')}
            </TableColHeader>
            <TableColHeader id="upload-progress" width="30%" theme={cellTheme}>
              <ScreenReaderContent>{I18n.t('Upload Progress')}</ScreenReaderContent>
            </TableColHeader>
            <TableColHeader id="upload-success" width="1rem" theme={cellTheme}>
              <ScreenReaderContent>{I18n.t('Upload Success')}</ScreenReaderContent>
            </TableColHeader>
            <TableColHeader id="delete" width="1rem" theme={cellTheme}>
              <ScreenReaderContent>{I18n.t('Remove file')}</ScreenReaderContent>
            </TableColHeader>
          </TableRow>
        </TableHead>
        <TableBody>{files.map(renderTableRow)}</TableBody>
      </Table>
    )
  }

  const renderTableRow = file => {
    // "file" is either a previously-uploaded file or one being uploaded right
    // now.  For the former, we can use the displayName property; files being
    // uploaded don't have that set yet, so use the local name (which we've set
    // to the URL for files from an LTI)
    const displayName = file.display_name || file.name
    const cellTheme = {background: theme.variables.colors.backgroundLight}
    return (
      <TableRow key={file._id || file.id}>
        <TableCell theme={cellTheme}>{getFileThumbnail(file, 'small')}</TableCell>
        <TableCell theme={cellTheme}>
          {displayName && (
            <>
              <span aria-hidden={true} title={displayName}>
                {elideString(displayName)}
              </span>
              <ScreenReaderContent>{displayName}</ScreenReaderContent>
            </>
          )}
        </TableCell>
        <TableCell theme={cellTheme}>
          {file.isLoading && renderFileProgress(file)}
          <ScreenReaderContent>
            {file.isLoading
              ? I18n.t('%{displayName} loading in progress', {displayName})
              : I18n.t('%{displayName} loaded', {displayName})}
          </ScreenReaderContent>
        </TableCell>
        <TableCell theme={cellTheme}>
          {!file.isLoading && <IconCompleteSolid color="success" />}
          <ScreenReaderContent>
            {file.isLoading
              ? I18n.t('%{displayName} loading pending', {displayName})
              : I18n.t('%{displayName} loading success', {displayName})}
          </ScreenReaderContent>
        </TableCell>
        <TableCell theme={cellTheme}>
          {!file.isLoading && (
            <IconButton
              id={file.id}
              onClick={handleRemoveFile}
              screenReaderLabel={I18n.t('Remove %{displayName}', {displayName})}
              size="small"
              withBackground={false}
              withBorder={false}
              disabled={submitting}
            >
              <IconTrashLine />
            </IconButton>
          )}
        </TableCell>
      </TableRow>
    )
  }

  const renderContent = () => {
    if (uploadSuccess) {
      return (
        <Flex justifyItems="center" margin="large">
          <FlexItem>
            <IconCheckLine color="success" size="x-large" />
          </FlexItem>
        </Flex>
      )
    }
    if (submitting) {
      return (
        <Flex justifyItems="center" margin="large" data-testid="proxy-submitting-spinner">
          <FlexItem>
            <Spinner renderTitle="Uploading files for submission" size="large" />
          </FlexItem>
        </Flex>
      )
    }
    return (
      <FileDrop
        // look for allowed extentions on assignment
        id="proxyInputFileDrop"
        data-testid="proxyInputFileDrop"
        accept=""
        shouldAllowMultiple={true}
        onDropAccepted={files => handleDropAccept(files)}
        onDropRejected={_files => {
          setAlert({text: I18n.t('Error uploading files'), variant: 'error'})
        }}
        renderLabel={
          <View as="div" padding="xx-large large" background="primary">
            <Img src={UploadFileSVG} width="160px" margin="small" />
            <Heading aria-hidden="true">{I18n.t('Drag a file here, or')}</Heading>
            <Text color="brand">{I18n.t('Choose a file to upload')}</Text>
          </View>
        }
      />
    )
  }

  return (
    <div>
      <Modal
        label={I18n.t('Upload File')}
        open={open}
        size="medium"
        shouldCloseOnDocumentClick={true}
      >
        <Modal.Header>
          <Heading>{I18n.t('Upload File')}</Heading>
          <CloseButton
            data-test="CloseBtn"
            placement="end"
            offset="small"
            onClick={onClose}
            screenReaderLabel={I18n.t('Close')}
          />
        </Modal.Header>
        <Modal.Body>
          {alert && (
            <>
              <Alert
                open={true}
                variant={alert.variant}
                renderCloseButtonLabel={I18n.t('Close')}
                onDismiss={() => setAlert(null)}
                margin="small"
                timeout={3000}
              >
                {I18n.t('%{text}', {text: alert.text})}
              </Alert>
              <p role="alert" className="screenreader-only">
                {I18n.t('%{text}', {text: alert.text})}
              </p>
            </>
          )}
          <div ref={containerRef}>
            {renderFilesTable()}
            {renderContent()}
          </div>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={onClose} margin="0 x-small 0 0">
            Close
          </Button>
          <Button
            data-testid="proxySubmit"
            color="primary"
            type="submit"
            disabled={filesUploading || submitting}
            onClick={e => handleSubmitClick(e)}
          >
            Submit
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  )
}

export default ProxyUploadContainer
