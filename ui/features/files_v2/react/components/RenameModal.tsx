/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {ChangeEvent, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from "@instructure/ui-modal";
import {Button, CloseButton} from "@instructure/ui-buttons";
import {Heading} from "@instructure/ui-heading";
import FileFolderID from "./FileFolderTable/FileFolderID";
import {TextInput} from "@instructure/ui-text-input";
import type {File, Folder} from "../../interfaces/File";
import {queryClient} from '@canvas/query'
import doFetchApi from "@canvas/do-fetch-api-effect";
import {showFlashError} from "@canvas/alerts/react/FlashAlert";
import type {FormMessage} from '@instructure/ui-form-field'
import {isFile} from "../../utils/fileFolderUtils";

const I18n = createI18nScope('files_v2')

const updateFilename = (file: File | Folder, name: null | string) => {
  return doFetchApi({
    method: 'PUT',
    path: `/api/v1/${isFile(file) ? 'files' : 'folders'}/${file.id}`,
    body: {name: name},
  })
}

export const RenameModal = ({renamingFile, setRenamingFile}: {
  renamingFile: File | Folder | null,
  setRenamingFile: React.Dispatch<React.SetStateAction<File | Folder | null>>
}) => {
  const [newFileName, setNewFileName] = useState<null | string | undefined>()
  const [errorMessages, setErrorMessages] = useState<FormMessage[]>()

  const saveRenaming = () => {
    if(!renamingFile) return

    if (typeof(newFileName) == 'undefined') // pristine
      return setRenamingFile(null)

    if (newFileName == '' || newFileName?.indexOf("/") !== -1) {
      if (isFile(renamingFile)) {
        setErrorMessages(!newFileName ? [{text: I18n.t("File name cannot be blank"), type: 'newError'}] : [{text: I18n.t("File name cannot contain /"), type: 'newError'}])
      } else {
        setErrorMessages(!newFileName ? [{text: I18n.t("Folder name cannot be blank"), type: 'newError'}] : [{text: I18n.t("Folder name cannot contain /"), type: 'newError'}])
      }
      return
    }

    updateFilename(renamingFile, newFileName)
      .then(async () => {
        setRenamingFile(null)
        await queryClient.refetchQueries({queryKey: ['files'], type: 'active'})
      })
      .catch((err) => {
        if (err.response.status == 409) {
          showFlashError(I18n.t(
            'A file named "%{name}" already exists in this folder',
            {name: newFileName},
          ))()
          setRenamingFile(null)
        } else {
          showFlashError(I18n.t("Renaming failed"))(err)
          setRenamingFile(null)
        }
      })
  }

  return (renamingFile ?
      <Modal
        as="div"
        open={true}
        onDismiss={() => {
          setRenamingFile(null)
        }}
        size="small"
        label={I18n.t('Rename file/folder modal')}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={() => {
              setRenamingFile(null)
            }}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t('Rename')}</Heading>
        </Modal.Header>
        <Modal.Body>
          <FileFolderID item={renamingFile}/>
          <div style={{paddingTop: '1.5rem'}}>
            <TextInput
              defaultValue={renamingFile.display_name || renamingFile.name}
              onChange={(_e: ChangeEvent<HTMLInputElement>, new_value: string) => {
                setNewFileName(new_value)
              }}
              messages={errorMessages}
              renderLabel={renamingFile.folder_id ? I18n.t('File Name') : I18n.t('Folder Name')}
              isRequired
            />
          </div>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={() => {
            setRenamingFile(null)
          }}>
            {I18n.t('Cancel')}
          </Button>
          <Button
            color="primary"
            margin="none none none small"
            onClick={saveRenaming}
          >
            {I18n.t('Save')}
          </Button>
        </Modal.Footer>
      </Modal> : null
  )
}
