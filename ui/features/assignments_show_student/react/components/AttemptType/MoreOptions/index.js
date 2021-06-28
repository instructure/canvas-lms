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

import {element, func, shape, string} from 'prop-types'
import CanvasFiles from './CanvasFiles/index'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {EXTERNAL_TOOLS_QUERY, USER_GROUPS_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {Flex} from '@instructure/ui-flex'
import GenericErrorPage from '@canvas/generic-error-page'
import {IconFolderLine, IconLtiLine} from '@instructure/ui-icons'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import I18n from 'i18n!assignments_2_MoreOptions'
import {Img} from '@instructure/ui-img'
import LoadingIndicator from '@canvas/loading-indicator'
import {useQuery} from 'react-apollo'
import React, {useEffect, useState} from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'

import {View} from '@instructure/ui-view'

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'

// An "abstract" component that renders a button allowing the user to upload a
// file using some sort of external interface.  Clicking the button shows a
// modal with this component's children as the contents.  By default, the
// footer contains a single "Cancel" button that will close the modal and
// assumes that the modal's contents will close it automatically when
// appropriate, but you can specify your own contents, such as a Submit button,
// by passing them as a function to the renderFooter property.
//
// The CanvasFileChooser and ExternalTool components are implementations of
// this component.
function BaseUploadTool({children, renderFooter, name, icon}) {
  const [showModal, setShowModal] = useState(false)

  // We specify this to prevent the modal's height from changing due to its
  // contents
  const modalContentsStyle = {
    height: '0',
    paddingBottom: '55%',
    position: 'relative'
  }

  useEffect(() => {
    if (!showModal) {
      return
    }

    const handleMessage = e => {
      if (
        e.data.messageType === 'LtiDeepLinkingResponse' ||
        e.data.messageType === 'A2ExternalContentReady'
      ) {
        setShowModal(false)
      }
    }
    window.addEventListener('message', handleMessage)

    return () => {
      window.removeEventListener('message', handleMessage)
    }
  }, [showModal])

  const button = (
    <Button
      display="block"
      height="100%"
      onClick={() => {
        setShowModal(true)
      }}
      theme={{borderWidth: '0'}}
      withBackground={false}
    >
      {icon}
      <View as="div" margin="small 0 0">
        <ScreenReaderContent>{I18n.t('Submit file using %{name}', {name})}</ScreenReaderContent>
        <Text color="brand" weight="bold" size="medium">
          {name}
        </Text>
      </View>
    </Button>
  )

  const closeModal = () => {
    setShowModal(false)
  }
  const cancelButton = (
    <Button onClick={closeModal} margin="0 xx-small 0 0">
      {I18n.t('Cancel')}
    </Button>
  )

  const modal = (
    <Modal
      as="form"
      data-testid="upload-file-modal"
      open={showModal}
      onDismiss={closeModal}
      size="large"
      label={name}
      shouldCloseOnDocumentClick
    >
      <Modal.Header>
        <CloseButton placement="end" offset="medium" variant="icon" onClick={closeModal}>
          {I18n.t('Close')}
        </CloseButton>
        <Heading>{name}</Heading>
      </Modal.Header>
      <Modal.Body padding="0 small">
        <div style={modalContentsStyle}>{children}</div>
      </Modal.Body>
      <Modal.Footer>
        {renderFooter ? renderFooter({cancelButton, closeModal}) : cancelButton}
      </Modal.Footer>
    </Modal>
  )

  return (
    <View
      as="div"
      background="primary"
      borderColor="brand"
      borderWidth="small"
      borderRadius="medium"
      height="100px"
      minWidth="100px"
    >
      {button}

      {modal}
    </View>
  )
}

BaseUploadTool.propTypes = {
  children: element.isRequired,
  renderFooter: func,
  name: string.isRequired,
  icon: element
}

function CanvasFileChooser({courseID, onFileSelect, userID}) {
  const [selectedCanvasFileID, setSelectedCanvasFileId] = useState(null)

  const {loading, error, data} = useQuery(USER_GROUPS_QUERY, {
    variables: {userID}
  })

  let contents
  if (loading) {
    contents = <LoadingIndicator />
  } else if (error) {
    contents = (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('User groups query error')}
        errorCategory={I18n.t('Assignments 2 Student Error Page')}
      />
    )
  } else {
    const userGroups = data.legacyNode
    contents = (
      <CanvasFiles
        courseID={courseID}
        handleCanvasFileSelect={fileID => {
          setSelectedCanvasFileId(fileID)
        }}
        userGroups={userGroups.groups}
      />
    )
  }

  let footerContents
  if (selectedCanvasFileID) {
    footerContents = ({cancelButton, closeModal}) => (
      <>
        {cancelButton}
        <Button
          variant="primary"
          onClick={() => {
            onFileSelect(selectedCanvasFileID)
            closeModal()
          }}
        >
          {I18n.t('Upload')}
        </Button>
      </>
    )
  }

  return (
    <BaseUploadTool
      renderFooter={footerContents}
      icon=<IconFolderLine size="medium" color="brand" />
      name={I18n.t('Files')}
    >
      {contents}
    </BaseUploadTool>
  )
}

function ExternalTool({launchUrl, tool}) {
  const icon =
    tool.settings?.iconUrl != null ? (
      <Img alt="" src={tool.settings.iconUrl} width="48px" height="48px" />
    ) : (
      <IconLtiLine size="medium" color="brand" />
    )

  const iframeStyle = {
    border: 'none',
    width: '100%',
    height: '100%',
    position: 'absolute'
  }

  return (
    <BaseUploadTool icon={icon} name={tool.name}>
      <iframe allow={iframeAllowances()} style={iframeStyle} src={launchUrl} title={tool.name} />
    </BaseUploadTool>
  )
}

ExternalTool.propTypes = {
  tool: shape({
    name: string.isRequired,
    settings: shape({
      iconUrl: string
    })
  }).isRequired,
  launchUrl: string.isRequired
}

function MoreOptions({assignmentID, courseID, handleCanvasFiles, userID}) {
  const {loading, error, data} = useQuery(EXTERNAL_TOOLS_QUERY, {
    variables: {courseID}
  })

  if (loading) return <LoadingIndicator />
  if (error) {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('Course external tools query error')}
        errorCategory={I18n.t('Assignments 2 Student Error Page')}
      />
    )
  }

  const externalTools = data.course?.externalToolsConnection?.nodes || []
  if (handleCanvasFiles == null && externalTools.length === 0) {
    return null
  }

  const buildLaunchUrl = tool =>
    `${window.location.origin}/courses/${encodeURIComponent(
      courseID
    )}/external_tools/${encodeURIComponent(
      tool._id
    )}/resource_selection?launch_type=homework_submission&assignment_id=${encodeURIComponent(
      assignmentID
    )}`

  return (
    <Flex direction="row" justifyItems="center">
      {handleCanvasFiles && (
        <Flex.Item margin="0 x-small">
          <CanvasFileChooser courseID={courseID} userID={userID} onFileSelect={handleCanvasFiles} />
        </Flex.Item>
      )}
      {externalTools.map(tool => (
        <Flex.Item key={tool._id} margin="0 x-small">
          <ExternalTool launchUrl={buildLaunchUrl(tool)} tool={tool} />
        </Flex.Item>
      ))}
    </Flex>
  )
}

MoreOptions.propTypes = {
  assignmentID: string.isRequired,
  courseID: string.isRequired,
  handleCanvasFiles: func,
  userID: string
}

export default MoreOptions
