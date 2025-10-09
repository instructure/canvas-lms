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

import doFetchApi from '@canvas/do-fetch-api-effect'
import TakePictureView from '../backbone/views/TakePictureView'
import UploadFileView from '../backbone/views/UploadFileView'
import {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import {completeUpload} from '@canvas/upload-file'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('profile')

declare const ENV: GlobalEnv & {folder_id: string}

type PreflightResponse = [
  {
    upload_url: string
    upload_params: Record<string, string>
    file_param: string
  },
  string, // status text ('success', 'failure', etc.)
]

// there are more fields, but these are the only ones we care about
type Avatar = {
  display_name: string
  url: string
  type: string
  token: string
}

type UploadResponse = {
  id: string
  folder_id: string
  display_name: string
  filename: string
  upload_status: string
  'content-type': string
  url: string
  size: number
  created_at: string
  updated_at: string
  unlock_at: string | null
  locked: boolean
  hidden: boolean
  lock_at: string | null
  hidden_for_user: boolean
  thumbnail_url: string
  modified_at: string
  mime_class: string
  media_entry_id: string | null
  category: string
  locked_for_user: boolean
  preview_url: string
  avatar: Avatar | null
  canvadoc_session_url: string | null
  crocodoc_session_url: string | null
}

export async function getImage(currentView: TakePictureView | UploadFileView | null) {
  try {
    if (currentView instanceof TakePictureView || currentView instanceof UploadFileView) {
      return currentView.getImage()
    }
  } catch (_error) {
    throw new Error(I18n.t('Failed to get image'))
  }
}

export async function preflightRequest(): Promise<PreflightResponse> {
  try {
    const formData = new FormData()
    formData.append('name', 'profile.jpg')
    formData.append('format', 'text')
    formData.append('no_redirect', 'true')
    formData.append('attachment[on_duplicate]', 'overwrite')
    formData.append('attachment[folder_id]', ENV.folder_id)
    formData.append('attachment[filename]', 'profile.jpg')
    formData.append('attachment[context_code]', `user_${ENV.current_user_id}`)
    const {json} = await doFetchApi<PreflightResponse>({
      path: '/files/pending',
      method: 'POST',
      body: formData,
    })
    return json!
  } catch (error) {
    throw new Error(I18n.t('Preflight request failed: %{error}', {error}))
  }
}

async function uploadImage(
  preflightResponse: PreflightResponse,
  image: Blob,
): Promise<UploadResponse> {
  const uploadResponse = await completeUpload(preflightResponse, image, {
    filename: 'profile.jpg',
    includeAvatar: true,
  })
  return uploadResponse as UploadResponse
}

async function getUpdatedAvatar(
  token: string | null,
  url: string | null,
  count: number,
): Promise<boolean> {
  const {json} = await doFetchApi<Avatar[]>({
    path: '/api/v1/users/self/avatars',
    method: 'GET',
  })
  const processedAvatar = json?.find(avatar => {
    return avatar.token === token
  })
  if (processedAvatar) {
    return true
  } else if (count < 50) {
    return new Promise(resolve =>
      setTimeout(() => resolve(getUpdatedAvatar(token, url, count + 1)), 100),
    )
  } else {
    return false
  }
}

async function saveAvatar(token: string | null): Promise<void> {
  const formData = new FormData()
  formData.append('user[avatar][token]', token || '')
  await doFetchApi({
    path: '/api/v1/users/self',
    method: 'PUT',
    body: formData,
  })
}

export function updateAvatarInDom(url: string) {
  const profilePictures = document.querySelectorAll('.profile_pic_link, .profile-link')
  profilePictures.forEach(pic => {
    const htmlImg = pic as HTMLElement
    htmlImg.style.backgroundImage = `url('${url}')`
  })
}

export async function handleUpdatingProfilePicture(
  setupResponses: [any, PreflightResponse],
): Promise<UploadResponse> {
  const [image, preflightResponse] = setupResponses
  const uploadResponse = await uploadImage(preflightResponse, image as Blob)
  const {token, url} = uploadResponse.avatar!
  const hasProcessedAvatar = await getUpdatedAvatar(token, url, 0)
  if (hasProcessedAvatar) {
    await saveAvatar(token)
    await updateAvatarInDom(url)
    return uploadResponse
  } else {
    throw new Error(I18n.t('Timed out waiting for avatar to be processed'))
  }
}
