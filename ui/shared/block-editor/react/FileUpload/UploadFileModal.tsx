/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useState} from 'react'
import {Alert} from '@instructure/ui-alerts'
import {Billboard} from '@instructure/ui-billboard'
import {Button, CloseButton, CondensedButton} from '@instructure/ui-buttons'
import {FileDrop} from '@instructure/ui-file-drop'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconEditLine} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {Modal} from '@instructure/ui-modal'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {FormMessage} from '@instructure/ui-form-field'
import {RocketSVG} from '@instructure/canvas-media'
import {doFileUpload} from './UploadFile'
import {
  HeroImageHeight,
  type ImageConstraint,
} from '../components/user/blocks/ImageBlock/ImageBlock'

function readFile(theFile: File): Promise<string> {
  const p: Promise<string> = new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => {
      const result = reader.result
      resolve(result as string)
    }
    reader.onerror = () => {
      reject(new Error('An error occured reading the file'))
    }

    if (theFile.size === 0) {
      // canvas will reject uploading an empty file
      reject(new Error('You may not upload an empty file.'))
    }
    reader.readAsDataURL(theFile)
  })
  return p
}

function setError(error: Error | null) {
  if (error) {
    // eslint-disable-next-line no-alert
    window.alert(error)
    // eslint-disable-next-line no-console
    console.log(error)
  }
}

interface UploadFileModalProps {
  imageUrl: string | null
  open: boolean
  variant: 'default' | 'hero'
  onDismiss: () => void
  onSave: (imageUrl: string | null) => void
}

const constraints: Record<string, ImageConstraint> = {
  default: 'contain',
  hero: 'cover',
}

interface Preview {
  preview: string | null
  isLoading: boolean
  error: string | null
}

const UploadFileModal = ({imageUrl, open, variant, onDismiss, onSave}: UploadFileModalProps) => {
  const [showUpload, setShowUpload] = useState(!imageUrl)
  const [fileDropMessages, setFileDropMessages] = useState<FormMessage[]>([])
  const [theFile, setTheFile] = useState<File | null>(null)
  const [preview, setPreview] = useState<Preview>({preview: null, isLoading: false, error: null})
  const [uploadInFlight, setUploadInFlight] = useState(false)

  useEffect(() => {
    return () => {
      if (Array.isArray(preview?.preview)) {
        URL?.revokeObjectURL?.(preview.preview[0].src)
      }
    }
  }, [preview])

  useEffect(() => {
    if (!theFile || preview.isLoading || preview.preview || preview.error) return

    async function getPreview() {
      if (!theFile) return
      setPreview({preview: null, isLoading: true, error: null})
      try {
        const previewer: string = await readFile(theFile)
        setPreview({preview: previewer, isLoading: false, error: null})
        setError(null)
        // @ts-expect-error
        theFile.preview = previewer
        setTheFile(theFile)
      } catch (ex) {
        setError(ex as Error)
        setPreview({
          preview: null,
          error: (ex as Error).message,
          isLoading: false,
        })
      }
    }
    getPreview()
  })

  function renderPreview() {
    if (preview.isLoading) {
      return (
        <div aria-live="polite">
          <Text color="secondary">Generating preview...</Text>
        </div>
      )
    } else if (preview.error) {
      return (
        <div
          style={{
            maxHeight: '250px',
            overflow: 'hidden',
            boxSizing: 'border-box',
            margin: '5rem .375rem 0',
            position: 'relative',
          }}
          aria-live="polite"
        >
          <Alert variant="error">{preview.error}</Alert>
        </div>
      )
    } else if (preview.preview) {
      return (
        <View as="div" width="794px" height={variant === 'hero' ? HeroImageHeight : '350px'}>
          <Img
            aria-label={`${theFile?.name} image preview`}
            src={preview.preview}
            constrain={constraints[variant]}
            display="block"
          />
        </View>
      )
    }
  }

  const handleDismiss = useCallback(() => {
    if (uploadInFlight) return
    setShowUpload(false)
    setFileDropMessages([])
    setTheFile(null)
    setPreview({preview: null, isLoading: false, error: null})
    onDismiss()
  }, [onDismiss, uploadInFlight])

  const handleSave = useCallback(async () => {
    if (uploadInFlight) return

    if (!theFile) {
      onSave(null)
      return
    }
    try {
      setShowUpload(false)
      setUploadInFlight(true)
      const filedata = await doFileUpload(theFile)
      const url = new URL(filedata.preview_url, window.location.origin)
      url.pathname = url.pathname.replace(/\w+$/, 'preview')
      url.searchParams.set('verifier', filedata.uuid)
      onSave(url.href)
    } catch (ex) {
      setError(ex as Error)
    } finally {
      setUploadInFlight(false)
    }
  }, [onSave, theFile, uploadInFlight])

  const handleChangeClick = useCallback(() => {
    setFileDropMessages([])
    setTheFile(null)
    setPreview({preview: null, isLoading: false, error: null})
    setShowUpload(true)
  }, [])

  const handleDropRejected = useCallback(() => {
    setFileDropMessages([
      {
        text: 'Invalid file type',
        type: 'error',
      },
    ])
  }, [])

  const handleDropAccepted = useCallback((dropped: ArrayLike<DataTransferItem | File>) => {
    const file = dropped[0] as File
    setFileDropMessages([])
    setTheFile(file)
    setShowUpload(false)
  }, [])

  const renderImage = () => {
    if (theFile) {
      return renderPreview()
    } else if (imageUrl) {
      return <Img src={imageUrl} alt="Selected Image" constrain={constraints[variant]} />
    }
    return null
  }

  const renderBodyContents = () => {
    if (showUpload) {
      return (
        <FileDrop
          accept="image/*"
          messages={fileDropMessages}
          onDropAccepted={handleDropAccepted}
          onDropRejected={handleDropRejected}
          renderLabel={
            <Billboard
              heading="Upload Image"
              hero={<RocketSVG width="3em" height="3em" />}
              message={
                <>
                  <View as="div" margin="small 0">
                    <Text>Drag and drop, or upload from your computer</Text>
                  </View>
                  <View as="div" margin="small 0">
                    <Text>Supported formats: JPG, PNG, GIF, SVG</Text>
                  </View>
                </>
              }
            />
          }
          shouldEnablePreview={true}
          width="942px"
        />
      )
    }
    if (uploadInFlight) {
      return (
        <View as="div" width="942px" height="100%" textAlign="center">
          <Spinner size="large" renderTitle="Uploading image" />
        </View>
      )
    }
    return (
      <Flex as="div" direction="column">
        <Flex.Item
          as="div"
          width="792px"
          maxHeight={variant === 'hero' ? HeroImageHeight : '350px'}
          shouldGrow={true}
        >
          {renderImage()}
        </Flex.Item>

        <Flex as="div" margin="small 0 large 0" justifyItems="center" gap="small">
          <Button renderIcon={<IconEditLine />} onClick={handleChangeClick}>
            Change
          </Button>
        </Flex>
      </Flex>
    )
  }

  return (
    <Modal open={open} size="auto" label="Edit Cover Image" onDismiss={onDismiss}>
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={handleDismiss}
          screenReaderLabel="Close"
        />
        <Heading>Pick an Image</Heading>
      </Modal.Header>
      <Modal.Body>
        {showUpload && (
          <View as="div" margin="0 0 small 0">
            <CondensedButton onClick={() => setShowUpload(false)}>&lt; Back</CondensedButton>
          </View>
        )}
        <View as="div" margin="small 0">
          {renderBodyContents()}
        </View>
      </Modal.Body>
      {!showUpload && (
        <Modal.Footer>
          <Button color="secondary" onClick={handleDismiss}>
            Cancel
          </Button>
          <Button color="primary" margin="0 0 0 small" onClick={handleSave}>
            Save image
          </Button>
        </Modal.Footer>
      )}
    </Modal>
  )
}

export {UploadFileModal}
