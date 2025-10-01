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

const I18n = createI18nScope('terms_of_service_modal')
const termsOfServiceText = I18n.t('Acceptable Use Policy')

// Type for the API response - either has content or redirectUrl
type AcceptableUsePolicyResponse = {content: string} | {redirectUrl: string}

function NewWindow({url}: {url: string}): null {
  useEffect(() => {
    window.open(url, '_blank', 'noopener,noreferrer')
  }, [url])
  return null // Render nothing, all the action is in th' new window
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
        try {
          const {json} = await doFetchApi<AcceptableUsePolicyResponse>({
            path: '/api/v1/acceptable_use_policy',
          })
          if (typeof json === 'undefined') throw new Error('No JSON response')

          if ('content' in json) setContent(json.content)
          else if ('redirectUrl' in json) setUrl(json.redirectUrl)
          else throw new Error('Unexpected JSON response')
        } catch (e) {
          console.error('An error occurred while fetching the Terms of Service content:', e)
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

  function handleLinkClick(): void {
    const rceContainer = document.getElementById('custom_tos_rce_container')
    if (rceContainer) {
      const textArea = rceContainer.querySelector('textarea')
      setCustomContent(RichContentEditor.callOnRCE(textArea, 'get_code'))
    }
    setOpen(true)
  }

  function TOSContents(): React.JSX.Element | null {
    if (!open) return null
    if (!preview && url) {
      requestAnimationFrame(() => setOpen(false)) // only open a new window once
      return <NewWindow url={url} />
    }

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
      <Modal open onDismiss={handleCloseModal} size="fullscreen" label={termsOfServiceText}>
        <Modal.Body>{body}</Modal.Body>
      </Modal>
    )
  }

  return (
    <span id="terms_of_service_modal">
      <Link
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
