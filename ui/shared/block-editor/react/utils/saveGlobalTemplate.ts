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

import uuid from 'uuid'
import {type BlockTemplate} from '../types'

type GlobalTemplate = Partial<BlockTemplate>

const saveGlobalTemplateToFile = (template: GlobalTemplate) => {
  const blob = new Blob([JSON.stringify(template, null, 2)], {type: 'application/json'})

  const link = document.createElement('a')
  link.setAttribute('style', 'postion: absolute; top: -10000px; left: -10000px')
  link.href = window.URL.createObjectURL(blob)
  link.download = `template-${template.global_id}.json`
  document.body.appendChild(link)
  link.click()
  link.remove()
}

export type ImageMapping = {
  src: string
  filename: string
}

export type ImagesMapping = Record<string, string>

const getImageFilename = (src: string): Promise<string> => {
  const fileid = src.match(/\/files\/(\d+)\//)?.[1]
  if (fileid) {
    return fetch(`/api/v1/files/${fileid}`)
      .then(response => {
        if (response.ok) {
          return response.json()
        }
        throw new Error(`Failed to fetch file metadata for file ${fileid}`)
      })
      .then(data => {
        return data.display_name || data.filename
      })
      .catch(err => {
        return src.replace(window.origin, '').replaceAll('/', '_')
      })
  } else {
    return Promise.resolve(src.replace(window.origin, '').replaceAll('/', '_'))
  }
}

// take the image src URL as input and return the
// name of the file we saved it in
const saveTemplateImage = async (src: string): Promise<ImageMapping> => {
  const filename = await getImageFilename(src)
  const link = document.createElement('a')
  link.href = src
  link.download = filename
  document.body.appendChild(link)
  link.click()
  link.remove()
  return {src, filename}
}

const saveTemplateImages = async (templateRootNode: HTMLElement): Promise<ImagesMapping> => {
  const imagePromises: Promise<any>[] = []
  const images = templateRootNode.querySelectorAll('img')
  images.forEach(img => {
    const src = img.getAttribute('src')
    if (src) {
      imagePromises.push(saveTemplateImage(src))
    }
  })

  const results = await Promise.allSettled(imagePromises)

  const imagesMap = results.reduce(
    (acc: ImagesMapping, currResult: PromiseSettledResult<ImageMapping>): ImagesMapping => {
      if (currResult.status === 'fulfilled') {
        const mapping = currResult.value as ImageMapping
        acc[mapping.src] = `/images/block_editor/templates/${mapping.filename}`
      }
      return acc
    },
    {},
  )

  return imagesMap
}

export {saveGlobalTemplateToFile, saveTemplateImages}
