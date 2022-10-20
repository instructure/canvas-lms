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

import htmlEscape from 'escape-html'
import {IconDownloadLine, IconExternalLinkLine} from '@instructure/ui-icons/es/svg'
import formatMessage from '../format-message'
import {closest, siblings, show, hide, insertAfter, getData, setData} from './jqueryish_funcs'
import {youTubeID, isExternalLink, getTld, showFilePreview} from './instructure_helper'
import mediaCommentThumbnail from './media_comment_thumbnail'

// in jest the es directory doesn't exist so stub the undefined svg
const IconDownloadSVG = IconDownloadLine?.src || '<svg></svg>'
const IconExternalLinkSVG = IconExternalLinkLine?.src || '<svg></svg>'

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
  srspan.innerHTML = htmlEscape(formatMessage('Download {filename}', {filename}))
  a.appendChild(srspan)

  return a
}

function makeExternalLinkIcon(forLink) {
  const dir = (forLink && window.getComputedStyle(forLink).direction) || 'ltr'
  const $icon = document.createElement('span')
  $icon.setAttribute('class', 'external_link_icon')
  const style = `margin-inline-start: 5px; ${dir === 'rtl' ? 'transform:scale(-1, 1)' : ''}`
  $icon.setAttribute('style', style)
  $icon.setAttribute('role', 'presentation')
  $icon.innerHTML = IconExternalLinkSVG
  $icon.firstChild.setAttribute(
    'style',
    'width:1em; height:1em; vertical-align:middle; fill:currentColor'
  )

  const srspan = document.createElement('span')
  srspan.setAttribute('class', 'screenreader-only')
  srspan.innerHTML = htmlEscape(formatMessage('Links to an external site.'))
  $icon.appendChild(srspan)
  return $icon
}

function handleYoutubeLink($link) {
  const href = $link.getAttribute('href')
  const id = youTubeID(href || '')
  if (id && !$link.classList.contains('inline_disabled')) {
    const $after = document.createElement('a')
    $after.setAttribute('href', href)
    $after.setAttribute('class', 'youtubed')
    $after.innerHTML = `
      <img src="/images/play_overlay.png"
        class="media_comment_thumbnail"
        style="background-image: url(//img.youtube.com/vi/${htmlEscape(id)}/2.jpg)"
        alt="${htmlEscape(getData($link, 'preview-alt') || '')}"
      />
    `
    $after.addEventListener('click', function (event) {
      event.preventDefault()
      const $this = event.currentTarget
      const $video = document.createElement('span')
      $video.setAttribute('class', 'youtube_holder')
      $video.style.display = 'block'
      $video.innerHTML = `
        <iframe
          src='//www.youtube.com/embed/${htmlEscape(id)}?autoplay=1&rel=0&hl=en_US&fs=1'
          frameborder='0'
          width='425'
          height='344'
          allowfullscreen
        ></iframe>
        <br/>
        <a
          href='#'
          style='font-size: 0.8em;'
          class='hide_youtube_embed_link'
        >
          ${htmlEscape(formatMessage('Minimize Video'))}
        </a>
      `
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

export function enhanceUserContent(container, customEnhanceFunc) {
  if (ENV?.SKIP_ENHANCING_USER_CONTENT) {
    return
  }

  const content =
    (container instanceof HTMLElement && container) ||
    document.getElementById('content') ||
    document

  content
    .querySelectorAll('.user_content:not(.enhanced)')
    .forEach(elem => elem.classList.add('unenhanced'))

  content.querySelectorAll('.unenhanced').forEach(unenhanced_elem => {
    unenhanced_elem.querySelectorAll('img').forEach(img => {
      // if the image file is unpublished it's replaced with the lock image
      // and canvas adds hidden=1 to the URL.
      // we also need to strip the alt text
      if (/hidden=1$/.test(img.getAttribute('src'))) {
        img.setAttribute('alt', formatMessage('This image is currently unavailable'))
      }
    })
    setData(unenhanced_elem, 'unenhanced_content_html', unenhanced_elem.innerHTML)

    unenhanced_elem.querySelectorAll('a:not(.not_external, .external)').forEach(childLink => {
      if (!isExternalLink(childLink)) return
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
        file_link.addEventListener('click', showFilePreview)

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
      if (siblings($link, '.preview_container').length) {
        return
      }

      const preview_id = previewId()
      $link.setAttribute('aria-expanded', 'false')
      $link.setAttribute('aria-controls', preview_id)
      $link.addEventListener('click', showFilePreview)
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
      mediaCommentThumbnail($anchor, 'normal')
    }

    if ($anchor.matches('.instructure_video_link, .instructure_audio_link')) {
      mediaCommentThumbnail($anchor, 'normal', true)
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

export function makeAllExternalLinksExternalLinks() {
  // in 100ms (to give time for everything else to load), find all the external links and add give them
  // the external link look and behavior (force them to open in a new tab)
  setTimeout(function () {
    const content = document.getElementById('content')
    if (!content) return
    const tld = getTld(window.location.hostname)
    const links = content.querySelectorAll(`a[href*="//"]:not([href*="${tld}"])`) // technique for finding "external" links copied from https://davidwalsh.name/external-links-css
    for (let i = 0; i < links.length; i++) {
      const $link = links[i]
      // don't mess with the ones that were already processed in enhanceUserContent
      if ($link.classList.contains('external')) continue
      if ($link.matches('.open_in_a_new_tab')) continue
      if ($link.querySelectorAll('img').length > 0) continue
      if ($link.matches('.not_external')) continue
      if ($link.matches('.exclude_external_icon')) continue
      // we have some pre-instui buttons that are styled links
      if ($link.classList.contains('btn')) continue
      const $linkToReplace = $link
      if ($linkToReplace) {
        const $linkIndicator = makeExternalLinkIcon()
        $linkToReplace.classList.add('external')
        $linkToReplace.querySelectorAll('span.ui-icon-extlink').forEach(c => c.remove)
        $linkToReplace.setAttribute('target', '_blank')
        $linkToReplace.setAttribute('rel', 'noreferrer noopener')
        const $linkSpan = document.createElement('span')
        const $linkText = $linkToReplace.innerHTML
        $linkSpan.innerHTML = $linkText
        while ($linkToReplace.firstChild) $linkToReplace.removeChild($linkToReplace.firstChild)
        $linkToReplace.appendChild($linkSpan)
        $linkToReplace.appendChild($linkIndicator)
      }
    }
  }, 100)
}
