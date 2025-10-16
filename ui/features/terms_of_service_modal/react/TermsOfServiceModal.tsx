/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React, {useEffect, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import RichContentEditor from '@canvas/rce/RichContentEditor'
import {Link} from '@instructure/ui-link'
import doFetchApi from '@canvas/do-fetch-api-effect'
import type {ViewOwnProps} from '@instructure/ui-view'
import {openWindow} from '@canvas/util/globalUtils'

const I18n = createI18nScope('terms_of_service_modal')
const termsOfServiceText = I18n.t('Acceptable Use Policy')

// Type for the raw API response - either has content or redirectUrl
type AcceptableUsePolicyResponse = {content: string} | {redirectUrl: string}

// normalized AUP response with a type tag for safe narrowing
type ParsedAupApi = {type: 'content'; content: string} | {type: 'redirectUrl'; url: string}

// normalize AUP API response into ParsedAupApi; throw if missing or malformed
function parseAupApiResponse(json: AcceptableUsePolicyResponse | undefined): ParsedAupApi {
  if (typeof json === 'undefined') throw new Error('No JSON response')
  if ('content' in json) return {type: 'content', content: json.content}
  if ('redirectUrl' in json) return {type: 'redirectUrl', url: json.redirectUrl}
  throw new Error('Unexpected JSON response')
}

// fetch AUP JSON from /api; return undefined on error
async function fetchAcceptableUsePolicy(): Promise<AcceptableUsePolicyResponse | undefined> {
  try {
    const {json} = await doFetchApi<AcceptableUsePolicyResponse>({
      path: '/api/v1/acceptable_use_policy',
    })
    return json
  } catch (e) {
    console.error('Failed to fetch acceptable use policy from API:', e)
    return undefined
  }
}

interface TermsOfServiceCustomContentsProps {
  content: string | undefined
  url: string | undefined
  setContent: (content: string) => void
  setUrl: (url: string) => void
}

function TermsOfServiceCustomContents({
  content,
  url,
  setContent,
  setUrl,
}: TermsOfServiceCustomContentsProps): JSX.Element | null {
  useEffect(
    function () {
      async function fetchTermsOfService() {
        const json = await fetchAcceptableUsePolicy()
        try {
          const result = parseAupApiResponse(json)
          if (result.type === 'content') setContent(result.content)
          else if (result.type === 'redirectUrl') setUrl(result.url)
        } catch (e) {
          console.error('Failed to parse acceptable use policy response:', e)
        }
      }

      if (content || url) return // already have it
      fetchTermsOfService()
    },
    [content, setContent, setUrl, url],
  )

  if (content) return <div dangerouslySetInnerHTML={{__html: content}} />
  if (url) return null
  return <span>{I18n.t('Loading...')}</span>
}

export interface TermsOfServiceModalProps {
  preview?: boolean
  footerLink?: boolean
}

export default function TermsOfServiceModal(props: TermsOfServiceModalProps): React.JSX.Element {
  const preview = Boolean(props.preview)
  const footerLink = Boolean(props.footerLink)
  const [open, setOpen] = useState(false)
  const [customContent, setCustomContent] = useState<string | undefined>(undefined)
  const [tosContentHTML, setTosContentHTML] = useState<string | undefined>(undefined)
  const [url, setUrl] = useState<string | undefined>(undefined)
  const linkRef = useRef<HTMLAnchorElement | null>(null)
  const fontColorDark = window.CANVAS_ACTIVE_BRAND_VARIABLES?.[
    'ic-brand-font-color-dark-lightened-15'
  ] as string

  const linkThemeOverrides = footerLink && fontColorDark ? {color: fontColorDark} : undefined

  function handleCloseModal() {
    linkRef.current?.focus()
    setOpen(false)
  }

  function setLinkRef(element: Element | null): void {
    linkRef.current = element as HTMLAnchorElement
  }

  async function handleLinkClick(e?: React.MouseEvent<ViewOwnProps>): Promise<void> {
    e?.preventDefault()

    if (preview) {
      const rceContainer = document.getElementById('custom_tos_rce_container')
      if (rceContainer) {
        const textArea = rceContainer.querySelector('textarea')
        setCustomContent(RichContentEditor.callOnRCE(textArea, 'get_code'))
      }
      setOpen(true)
      return
    }

    // read cached url from state
    let redirectUrl = url

    // fetch if needed (no url and no inline content yet)
    if (!redirectUrl && !tosContentHTML) {
      const json = await fetchAcceptableUsePolicy()

      try {
        const result = parseAupApiResponse(json)

        if (result.type === 'content') {
          setTosContentHTML(result.content)
        } else if (result.type === 'redirectUrl') {
          redirectUrl = result.url
          setUrl(redirectUrl)
        }
      } catch (e) {
        console.error('Failed to load acceptable use policy:', e)
        // silently fail (don’t open broken modal)
        return
      }
    }

    // open external AUP and skip modal
    if (redirectUrl) {
      openWindow(redirectUrl, '_blank', 'noopener,noreferrer')
      return
    }

    // no redirect: show modal with inline content
    setOpen(true)
  }

  function TOSContents(): React.JSX.Element | null {
    if (!open) return null

    if (preview && typeof customContent === 'undefined') return null

    const body = preview ? (
      <div dangerouslySetInnerHTML={{__html: customContent!}} />
    ) : (
      <TermsOfServiceCustomContents
        content={tosContentHTML}
        url={url}
        setContent={setTosContentHTML}
        setUrl={setUrl}
      />
    )

    return (
      <Modal
        data-testid="tos-modal"
        open
        onDismiss={handleCloseModal}
        size="fullscreen"
        label={termsOfServiceText}
      >
        <Modal.Body>{body}</Modal.Body>
      </Modal>
    )
  }

  return (
    <span id="terms_of_service_modal">
      <Link
        data-testid="tos-link"
        elementRef={setLinkRef}
        interaction={open ? 'disabled' : 'enabled'}
        href="#"
        onClick={handleLinkClick}
        isWithinText={!footerLink}
        themeOverride={linkThemeOverrides}
      >
        {preview ? I18n.t('Preview') : termsOfServiceText}
      </Link>
      <TOSContents />
    </span>
  )
}
