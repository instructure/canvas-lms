/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useState, useEffect} from 'react'

// Given a URL to some resource (lik an image),
// fetches that resource and creates a base64
// data URL representation of the resource
const useDataUrl = () => {
  const [url, setUrl] = useState('')
  const [dataUrl, setDataUrl] = useState('')
  const [dataBlob, setDataBlob] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState()

  useEffect(() => {
    async function fetchDataUrl() {
      try {
        setLoading(true)

        // Fetch the data and parse as blob
        const response = await fetch(url)
        const blob = await response.blob()

        // Return a promise that resolves with
        // the the result of the blob read as
        // a data URL.
        return new Promise((resolve, reject) => {
          const reader = new FileReader()
          reader.onloadend = () =>
            resolve({
              result: reader.result,
              blob,
            })

          reader.onerror = reject
          reader.readAsDataURL(blob)
        })
      } catch (e) {
        setError(e)
      }
    }

    if (url) {
      fetchDataUrl()
        .then(({result, blob}) => {
          setDataUrl(result)
          setDataBlob(blob)
        })
        .catch(e => {
          setError(e)
        })
        .finally(() => setLoading(false))
    }
  }, [url])

  return {
    setUrl,
    dataUrl,
    dataLoading: loading,
    dataError: error,
    dataBlob,
  }
}

export default useDataUrl
