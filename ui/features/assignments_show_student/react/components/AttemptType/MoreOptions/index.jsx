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

import {arrayOf, bool, element, func, shape, string} from 'prop-types'
import CanvasFiles from './CanvasFiles/index'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {USER_GROUPS_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {Flex} from '@instructure/ui-flex'
import GenericErrorPage from '@canvas/generic-error-page'
import {IconFolderLine, IconLtiLine} from '@instructure/ui-icons'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Img} from '@instructure/ui-img'
import LoadingIndicator from '@canvas/loading-indicator'
import {useQuery} from 'react-apollo'
import React, {useEffect, useState} from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import TakePhotoUrl from '../../../../images/TakePhoto.svg'
import {Text} from '@instructure/ui-text'
import WebcamCapture from './WebcamCapture'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'

import {View} from '@instructure/ui-view'

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'

const I18n = useI18nScope('assignments_2_MoreOptions')

// An "abstract" component that renders a button allowing the user to upload a
// file via an interface supplied by the caller.
//
// When clicked, the button will open a modal, the contents of which should be
// specified by passing a function as the component's child. The child function
// will be called with a "close" argument (a function that will close the modal
// when called) and should return the modal's contents as appropriate.
//
// By default, the modal includes a footer with a "Cancel" button. Pass the
// hideFooter prop to omit the footer, or pass a function in the renderFooter
// prop to use your own rendering function. It will be called with two
// properties, cancelButton (a component you can include in the result) and
// closeModal (a function that will close the modal).
//
// The CanvasFileChooser, ExternalTool, and WebcamPhotoUpload components are
// implementations of this component.
function BaseUploadTool({children, hideFooter, icon, label, renderFooter, title}) {
  const [showModal, setShowModal] = useState(false)

  // We specify this to prevent the modal's height from changing due to its
  // contents
  const modalContentsStyle = {
    height: '0',
    paddingBottom: '55%',
    position: 'relative',
  }

  useEffect(() => {
    if (!showModal) {
      return
    }

    const handleMessage = e => {
      if (
        e.data.subject === 'LtiDeepLinkingResponse' ||
        e.data.subject === 'A2ExternalContentReady'
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
      themeOverride={{borderWidth: '0'}}
      withBackground={false}
    >
      <Flex direction="row" justifyItems="center" padding="xxx-small 0">
        <Flex.Item>{icon}</Flex.Item>
        <Flex.Item margin="0 small">
          <ScreenReaderContent>{I18n.t('Submit file using %{label}', {label})}</ScreenReaderContent>
          <Text color="primary" size="large">
            {label}
          </Text>
        </Flex.Item>
      </Flex>
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

  const modalTitle = title || label
  const modal = (
    <Modal
      as="form"
      data-testid="upload-file-modal"
      open={showModal}
      onDismiss={closeModal}
      size="large"
      label={modalTitle}
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={closeModal}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{modalTitle}</Heading>
      </Modal.Header>
      <Modal.Body padding="0 x-small">
        <div style={modalContentsStyle}>{children({close: closeModal})}</div>
      </Modal.Body>
      {!hideFooter && (
        <Modal.Footer>
          {renderFooter ? renderFooter({cancelButton, closeModal}) : cancelButton}
        </Modal.Footer>
      )}
    </Modal>
  )

  return (
    <View
      as="div"
      background="primary"
      borderColor="primary"
      borderWidth="small"
      borderRadius="medium"
      minWidth="100px"
    >
      {button}

      {modal}
    </View>
  )
}

BaseUploadTool.propTypes = {
  children: func.isRequired,
  hideFooter: bool,
  icon: element,
  label: string.isRequired,
  renderFooter: func,
  title: string,
}

const iconDimensions = {height: '24px', width: '24px'}

function CanvasFileChooser({allowedExtensions, courseID, onFileSelect, userID}) {
  const [selectedCanvasFileID, setSelectedCanvasFileId] = useState(null)

  const {loading, error, data} = useQuery(USER_GROUPS_QUERY, {
    variables: {userID},
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
        allowedExtensions={allowedExtensions}
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
          color="primary"
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
      icon={<IconFolderLine size="medium" color="primary" width="24px" height="24px" />}
      label={I18n.t('Canvas Files')}
    >
      {() => contents}
    </BaseUploadTool>
  )
}

function ExternalTool({launchUrl, tool}) {
  const icon =
    tool.settings?.iconUrl != null ? (
      <Img alt="" src={tool.settings.iconUrl} {...iconDimensions} />
    ) : (
      <IconLtiLine size="medium" color="brand" />
    )

  const iframeStyle = {
    border: 'none',
    width: '100%',
    height: '100%',
    position: 'absolute',
  }

  return (
    <BaseUploadTool icon={icon} label={tool.name}>
      {() => (
        <iframe allow={iframeAllowances()} style={iframeStyle} src={launchUrl} title={tool.name} />
      )}
    </BaseUploadTool>
  )
}

ExternalTool.propTypes = {
  tool: shape({
    name: string.isRequired,
    settings: shape({
      iconUrl: string,
    }),
  }).isRequired,
  launchUrl: string.isRequired,
}

function WebcamPhotoUpload({onPhotoTaken}) {
  return (
    <BaseUploadTool
      hideFooter={true}
      icon={<Img alt={I18n.t('Take a Photo via Webcam')} src={TakePhotoUrl} {...iconDimensions} />}
      label={I18n.t('Webcam Photo')}
      title={I18n.t('Take a Photo via Webcam')}
    >
      {({close}) => (
        <WebcamCapture
          onSelectImage={params => {
            onPhotoTaken(params)
            close()
          }}
        />
      )}
    </BaseUploadTool>
  )
}

function MoreOptions({
  allowedExtensions,
  breakpoints,
  courseID,
  handleCanvasFiles,
  handleWebcamPhotoUpload,
  userID,
}) {
  if (handleCanvasFiles == null && handleWebcamPhotoUpload == null) {
    return null
  }

  const itemMargin = breakpoints.desktopOnly ? 'x-small' : 'xx-small xxx-small'

  return (
    <Flex direction="column" justifyItems="center">
      {handleWebcamPhotoUpload && (
        <Flex.Item margin={itemMargin} overflowY="visible">
          <WebcamPhotoUpload onPhotoTaken={handleWebcamPhotoUpload} />
        </Flex.Item>
      )}
      {handleCanvasFiles && (
        <Flex.Item margin={itemMargin} overflowY="visible">
          <CanvasFileChooser
            allowedExtensions={allowedExtensions}
            courseID={courseID}
            userID={userID}
            onFileSelect={handleCanvasFiles}
          />
        </Flex.Item>
      )}
    </Flex>
  )
}

MoreOptions.propTypes = {
  allowedExtensions: arrayOf(string),
  breakpoints: breakpointsShape,
  courseID: string.isRequired,
  handleCanvasFiles: func,
  handleWebcamPhotoUpload: func,
  userID: string,
}

export default WithBreakpoints(MoreOptions)
