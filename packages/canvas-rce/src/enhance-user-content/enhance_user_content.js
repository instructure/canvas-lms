/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import {IconDownloadLine} from '@instructure/ui-icons/es/svg'
import formatMessage from '../format-message'
import {closest, getData, hide, insertAfter, setData, show} from './jqueryish_funcs'
import {isExternalLink, showFilePreview, youTubeID} from './instructure_helper'
import mediaCommentThumbnail from './media_comment_thumbnail'
import {addParentFrameContextToUrl} from '../rce/plugins/instructure_rce_external_tools/util/addParentFrameContextToUrl'
import {MathJaxDirective, Mathml} from './mathml'
import {makeExternalLinkIcon} from './external_links'

// in jest the es directory doesn't exist so stub the undefined svg
const IconDownloadSVG = IconDownloadLine?.src || '<svg></svg>'

function makeDownloadButton(download_url, filename) {
  const a = document.createElement('a')
  a.setAttribute('class', 'file_download_btn')
  a.setAttribute('role', 'button')
  a.setAttribute('download', '')
  a.setAttribute('style', 'margin-inline-start: 5px; text-decoration: none;')
  a.setAttribute('href', download_url)

  const $icon = document.createElement('span')
  $icon.setAttribute('role', 'presentation')
  $icon.innerHTML = IconDownloadSVG
  $icon.firstChild.setAttribute(
    'style',
    'width:1em; height:1em; vertical-align:middle; fill:currentColor'
  )
  a.appendChild($icon)

  const srspan = document.createElement('span')
  srspan.setAttribute('class', 'screenreader-only')
  srspan.textContent = formatMessage('Download {filename}', {filename})
  a.appendChild(srspan)

  return a
}

function handleYoutubeLink($link) {
  const href = $link.getAttribute('href')
  const id = youTubeID(href || '')
  if (id && !$link.classList.contains('inline_disabled')) {
    const $after = document.createElement('a')
    $after.setAttribute('href', href)
    $after.setAttribute('class', 'youtubed')

    const img = document.createElement('img')
    img.src = '/images/play_overlay.png'
    img.className = 'media_comment_thumbnail'
    img.alt = getData($link, 'preview-alt') || ''
    img.style.backgroundImage = `url(//img.youtube.com/vi/${id}/2.jpg)`
    $after.appendChild(img)

    $after.addEventListener('click', function (event) {
      event.preventDefault()
      const $this = event.currentTarget
      const $video = document.createElement('span')
      $video.setAttribute('class', 'youtube_holder')
      $video.style.display = 'block'

      const iframe = document.createElement('iframe')
      iframe.src = `//www.youtube.com/embed/${id}?autoplay=1&rel=0&hl=en_US&fs=1`
      iframe.setAttribute('frameborder', '0')
      iframe.setAttribute('width', '425')
      iframe.setAttribute('height', '344')
      iframe.setAttribute('allowfullscreen', '')
      $video.appendChild(iframe)

      const br = document.createElement('br')
      $video.appendChild(br)

      const link = document.createElement('a')
      link.href = '#'
      link.setAttribute('style', 'font-size: 0.8em;')
      link.setAttribute('class', 'hide_youtube_embed_link')
      link.textContent = formatMessage('Minimize Video')
      $video.appendChild(link)

      $video.querySelectorAll('.hide_youtube_embed_link').forEach($elem => {
        $elem.addEventListener('click', function (event2) {
          event2.preventDefault()
          $video.parentElement.removeChild($video)
          show($after)
        })
      })

      insertAfter($video, $this)
      hide($this)
    })
    $link.classList.add('youtubed')
    insertAfter($after, $link)
  }
}

let preview_counter = 0
function previewId() {
  return `preview_${++preview_counter}`
}

function buildUrl(url) {
  try {
    return new URL(url)
  } catch (e) {
    // Don't raise an error
  }
}

const addResourceIdentifiersToStudioContent = content => {
  content.querySelectorAll('iframe.lti-embed').forEach(iframe => {
    const url = buildUrl(iframe.getAttribute('src'))
    if (
      !url ||
      !url.pathname.includes('external_tools/retrieve') ||
      !url.search.includes('instructuremedia.com') ||
      !url.search.includes('custom_arc_media_id')
    ) {
      return
    }
    const userContentContainer = iframe.closest('.user_content')
    if (userContentContainer?.dataset?.resourceType && userContentContainer?.dataset?.resourceId) {
      url.searchParams.set(
        'com_instructure_course_canvas_resource_type',
        userContentContainer.dataset.resourceType
      )
      url.searchParams.set(
        'com_instructure_course_canvas_resource_id',
        userContentContainer.dataset.resourceId
      )
      iframe.src = url.href
    }
  })
}

export function enhanceUserContent(container = document, opts = {}) {
  const {
    customEnhanceFunc,
    canvasOrigin,
    kalturaSettings,
    disableGooglePreviews,
    canvasLinksTarget,

    /**
     * For MathML configuration
     */
    new_math_equation_handling,
    explicit_latex_typesetting,
    locale,

    /**
     * When used inside of an LTI tool, this contains the canvas global id of the tool.
     */
    containingCanvasLtiToolId,
  } = opts

  const content =
    (container instanceof HTMLElement && container) ||
    document.getElementById('content') ||
    document

  const showFilePreviewEx = event => showFilePreview(event, {canvasOrigin, disableGooglePreviews})

  content.querySelectorAll('.user_content:not(.enhanced)').forEach(elem => {
    elem.classList.add('unenhanced')
    explicit_latex_typesetting && elem.classList.add(MathJaxDirective.Process)
  })

  const mathml = new Mathml({new_math_equation_handling, explicit_latex_typesetting}, {locale})

  content.querySelectorAll('.unenhanced').forEach(unenhanced_elem => {
    explicit_latex_typesetting && mathml.processNewMathInElem(unenhanced_elem)

    unenhanced_elem.querySelectorAll('img').forEach(img => {
      const src = img.getAttribute('src')

      if (!/^\/[^/]/.test(src)) {
        return
      }

      // if the image file is unpublished it's replaced with the lock image
      // and canvas adds hidden=1 to the URL.
      // we also need to strip the alt text
      if (/hidden=1$/.test(src)) {
        img.setAttribute('alt', formatMessage('This image is currently unavailable'))
      }
    })
    setData(unenhanced_elem, 'unenhanced_content_html', unenhanced_elem.innerHTML)

    // guarantee relative links point to canvas
    if (canvasOrigin) {
      const attributes = ['href', 'src']
      const selector = '[href], [src]'

      unenhanced_elem.querySelectorAll(selector).forEach(element => {
        try {
          for (const a of attributes) {
            const potentialUrl = element.getAttribute(a)
            if (!/^\/[^/]/.test(potentialUrl)) {
              continue
            }

            const absoluteUrl = new URL(potentialUrl, canvasOrigin)
            element.setAttribute(a, absoluteUrl.href)

            if (
              canvasLinksTarget &&
              element.tagName === 'A' &&
              (!element.getAttribute('target') || element.getAttribute('target') === '_blank')
            ) {
              element.setAttribute('target', canvasLinksTarget)
            }
          }
        } catch (_ignore) {
          // canvasOrigin probably isn't a valid base url
        }
      })
    }

    // add parent_frame_context to canvas iframes to allow them loading inside another LTI tool
    if (containingCanvasLtiToolId != null) {
      unenhanced_elem.querySelectorAll('iframe[src]').forEach(iframeElem => {
        const src = iframeElem.getAttribute('src')

        if (src.startsWith(canvasOrigin)) {
          iframeElem.setAttribute('src', addParentFrameContextToUrl(src, containingCanvasLtiToolId))
        }
      })
    }

    // tell LTI tools that they are launching from within the active RCE
    unenhanced_elem.querySelectorAll('iframe[src]').forEach(iframeElem => {
      const src = iframeElem.getAttribute('src')

      if (src.startsWith(canvasOrigin)) {
        iframeElem.setAttribute('src', src.replace('display=in_rce', 'display=borderless'))
      }
    })

    unenhanced_elem.querySelectorAll('a:not(.not_external, .external)').forEach(childLink => {
      if (!isExternalLink(childLink, canvasOrigin)) return
      if (childLink.tagName === 'IMG' || childLink.querySelectorAll('img').length > 0) return
      childLink.classList.add('external')
      childLink.setAttribute('target', '_blank')
      childLink.setAttribute('rel', 'noreferrer noopener')
      const $linkSpan = document.createElement('span')
      const $linkText = childLink.innerHTML
      $linkSpan.innerHTML = $linkText
      while (childLink.firstChild) childLink.removeChild(childLink.firstChild)
      childLink.appendChild($linkSpan)
      const externalLinkIcon = makeExternalLinkIcon(childLink)
      childLink.appendChild(externalLinkIcon)
    })

    addResourceIdentifiersToStudioContent(unenhanced_elem)
  })

  content
    .querySelectorAll('a.instructure_file_link, a.instructure_scribd_file')
    .forEach(file_link => {
      const href = buildUrl(file_link.href)

      // Don't attempt to enhance links with no href
      if (!href) return

      const matchesCanvasFile = href.pathname.match(
        /(?:\/(courses|groups|users)\/(\d+))?\/files\/(\d+)/
      )
      if (!matchesCanvasFile) {
        // a bug in the new RCE added instructure_file_link class name to all links
        // only proceed if this is a canvas file link
        return
      }

      if (file_link.textContent.trim()) {
        file_link.addEventListener('click', showFilePreviewEx)

        const filename = file_link.textContent
        // instructure_file_link_holder is used to find file_preview_link
        const $span = document.createElement('span')
        $span.setAttribute(
          'class',
          'instructure_file_holder link_holder instructure_file_link_holder'
        )

        const qs = href.searchParams
        qs.delete('wrap')
        qs.append('download_frd', '1')
        const download_url = `${href.origin}${href.pathname.replace(
          /(?:\/(download|preview))?$/,
          '/download'
        )}?${qs}`
        const $download_btn = makeDownloadButton(download_url, filename)

        if (file_link.classList.contains('instructure_scribd_file')) {
          if (file_link.classList.contains('no_preview')) {
            // link downloads
            file_link.setAttribute('href', download_url)
            file_link.removeAttribute('target')
          } else if (file_link.classList.contains('inline_disabled')) {
            // link opens in overlay
            file_link.classList.add('preview_in_overlay')
          } else {
            // link previews
            file_link.classList.add('file_preview_link')
          }
        }
        file_link.classList.remove('instructure_file_link')
        file_link.classList.remove('instructure_scribd_file')
        file_link.parentElement.replaceChild($span, file_link)
        $span.appendChild(file_link)
        if ($download_btn) $span.appendChild($download_btn)
      }
    })

  // Some schools have been using 'file_preview_link' for inline previews
  // outside of the RCE so find them all after we've gone through and
  // added our own (above)
  content
    .querySelectorAll(
      '.instructure_file_link_holder a.file_preview_link, .instructure_file_link_holder a.scribd_file_preview_link'
    )
    .forEach($link => {
      if ($link.classList.contains('previewable')) {
        return
      }

      const preview_id = previewId()
      $link.setAttribute('aria-expanded', 'false')
      $link.setAttribute('aria-controls', preview_id)
      $link.classList.add('previewable')
      $link.addEventListener('click', showFilePreviewEx)
      const $preview_container = document.createElement('div')
      $preview_container.setAttribute('role', 'region')
      $preview_container.setAttribute('class', 'preview_container')
      $preview_container.id = preview_id
      $preview_container.setAttribute('style', 'display: none;')
      $link.parentElement.appendChild($preview_container)
      if ($link.classList.contains('auto_open')) {
        $link.click()
      }
    })

  const unenhanced_anchors = content.querySelectorAll(
    '.user_content.unenhanced a, .user_content.unenhanced+div.answers a'
  )
  unenhanced_anchors.forEach($anchor => {
    $anchor.querySelectorAll('img.media_comment_thumbnail').forEach($thumbnail => {
      const a = closest($thumbnail, 'a', content)
      a?.classList.add('instructure_inline_media_comment')
    })

    if ($anchor.matches('.instructure_inline_media_comment')) {
      $anchor.classList.remove('no-underline')
      mediaCommentThumbnail($anchor, 'normal', false, kalturaSettings)
    }

    if ($anchor.matches('.instructure_video_link, .instructure_audio_link')) {
      mediaCommentThumbnail($anchor, 'normal', true, kalturaSettings)
    }

    if (!$anchor.matches('.youtubed')) {
      handleYoutubeLink($anchor)
    }
  })

  if (customEnhanceFunc) {
    customEnhanceFunc()
  }

  content.querySelectorAll('.user_content.unenhanced').forEach($elem => {
    $elem.classList.remove('unenhanced')
    $elem.classList.add('enhanced')
  })

  setTimeout(() => {
    content
      .querySelectorAll('.user_content form.user_content_post_form:not(.submitted)')
      .forEach($elem => {
        $elem.submit()
        $elem.classList.add('submitted')
      })
  }, 10)
  // Remove sandbox attribute from user content iframes to fix busted
  // third-party content, like Google Drive documents.
  document
    .querySelectorAll('.user_content iframe[sandbox="allow-scripts allow-forms allow-same-origin"]')
    .forEach(frame => {
      frame.removeAttribute('sandbox')
      const src = frame.src
      frame.src = src
    })
}
