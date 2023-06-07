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

import {isAudio, isImage, isVideo} from '../rce/plugins/shared/fileTypeUtils'
import {
  AUDIO_PLAYER_SIZE,
  VIDEO_SIZE_DEFAULT,
} from '../rce/plugins/instructure_record/VideoOptionsTray/TrayController'
import formatMessage from '../format-message'
import {trimmedOrNull} from './string-util'
import {Editor} from 'tinymce'
import {assertNever} from './assertNever'
import {isTextNode} from './elem-util'

/**
 * Determines what type of placeholder is appropriate for a given file information.
 */
export async function placeholderInfoFor(
  fileMetaProps: PlaceHoldableThingInfo
): Promise<PlaceholderInfo> {
  const fileName = fileMetaProps.title ?? fileMetaProps.name
  const visibleLabel = trimmedOrNull(fileName) ?? formatMessage('Loading...')
  const ariaLabel = formatMessage('Loading placeholder for {fileName}', {
    fileName: fileName ?? 'unknown filename',
  })

  if (isImage(fileMetaProps.contentType) && fileMetaProps.displayAs !== 'link') {
    const imageUrl =
      trimmedOrNull((fileMetaProps.domObject as {preview: string}).preview) ??
      URL.createObjectURL(fileMetaProps.domObject as File | Blob)

    return new Promise<PlaceholderInfo>((resolve, reject) => {
      const image = new Image()
      image.onload = () =>
        resolve({
          type: 'block',
          visibleLabel,
          ariaLabel,
          width: image.width + 'px',
          height: image.height + 'px',
          vAlign: 'middle',
          backgroundImageUrl: image.src,
        })
      image.onerror = () => reject(new Error('Failed to load image: ' + imageUrl))
      image.src = imageUrl
    })
  } else if (isVideo(fileMetaProps.contentType || fileMetaProps.type)) {
    return {
      type: 'block',
      visibleLabel,
      ariaLabel,
      width: VIDEO_SIZE_DEFAULT.width,
      height: VIDEO_SIZE_DEFAULT.height,
      vAlign: 'bottom',
    }
  } else if (isAudio(fileMetaProps.contentType || fileMetaProps.type)) {
    return {
      type: 'block',
      visibleLabel,
      ariaLabel,
      width: AUDIO_PLAYER_SIZE.width,
      height: AUDIO_PLAYER_SIZE.height,
      vAlign: 'bottom',
    }
  } else {
    return {type: 'inline', visibleLabel, ariaLabel}
  }
}

export function removePlaceholder(editor: Editor, unencodedName: string) {
  const placeholderElem = editor.dom.doc.querySelector(
    `[data-placeholder-for="${encodeURIComponent(unencodedName)}"]`
  ) as HTMLDivElement

  // Fail gracefully
  if (!placeholderElem) return

  editor.undoManager.ignore(() => {
    editor.dom.remove(placeholderElem)

    // Cleanup data URIs
    placeholderElem.querySelectorAll('img').forEach(
      // Revoking non-object URLs is safe
      img => URL.revokeObjectURL(img.src)
    )
  })
}

/**
 * Inserts a placeholder into a TinyMCE editor. It should be removed by calling removePlaceholder, to ensure
 * image resources are cleaned up.
 */
export async function insertPlaceholder(
  editor: Editor,
  unencodedName: string,
  placeholderInfoPromise: Promise<PlaceholderInfo>
): Promise<HTMLElement> {
  const placeholderId = `placeholder-${placeholderIdCounter++}`

  // Insert a minimal placeholder element into the editor.
  editor.undoManager.ignore(() =>
    editor.execCommand(
      'mceInsertContent',
      false,
      `<span
            aria-label="${formatMessage('Loading')}"
            data-placeholder-for="${encodeURIComponent(unencodedName)}"
            id="${placeholderId}"
            class="mceNonEditable"
            style="user-select: none; pointer-events: none; user-focus: none; display: inline-flex;"
          ></span>&nbsp;`
      // Without the trailing &nbsp;, tinymce will place the cursor inside the placeholder, which we don't want.
    )
  )

  const placeholderElem = editor.dom.doc.querySelector(`#${placeholderId}`) as HTMLDivElement
  if (placeholderElem) {
    editor.undoManager.ignore(() => {
      // Remove the trailing space
      const nextNode = placeholderElem.nextSibling
      placeholderElem.contentEditable = 'false'
      if (isTextNode(nextNode) && nextNode?.data?.startsWith('\xA0' /* nbsp */)) {
        // Split out the non-breaking-space which only counts as length 1 for splitText
        nextNode.splitText(1)

        // Remove the now split text node
        if (placeholderElem.nextSibling) {
          editor.dom.remove(placeholderElem.nextSibling)
        }
      }
    })
  } else {
    throw new Error('Failed to find placeholder element after inserting it into the editor.')
  }

  const placeholderInfo = await placeholderInfoPromise

  // Fully initialize the placeholder. Done separately from inserting to avoid TinyMCE mangling the HTML
  editor.undoManager.ignore(() => {
    // Set up the overall placeholder container
    placeholderElem.setAttribute('aria-label', placeholderInfo.ariaLabel)
    Object.assign(placeholderElem.style, {
      // Placeholder has absolute children
      position: 'relative',

      // Layout
      display: 'inline-flex',
      alignItems: 'center',
      borderRadius: '10px',
      overflow: 'hidden',
    } as CSSStyleDeclaration)

    // Create the spinner
    placeholderElem.innerHTML = spinnerSvg(
      placeholderInfo.type === 'inline' ? 'x-small' : 'medium',
      placeholderId + '-label'
    )

    const spinnerElem = placeholderElem.firstElementChild as SVGElement
    if (!spinnerElem) {
      throw new Error("Couldn't find the Spinner element in the placeholder")
    }

    // Create the label
    const labelElem = editor.dom.doc.createElement('div')
    placeholderElem.appendChild(labelElem)

    Object.assign(labelElem.style, {
      color: '#2D3B45',
      zIndex: '1000',

      /* Restrict text to one line */
      display: 'inline-block',
      maxWidth: 'calc(100% - 10px)',
      overflow: 'hidden',
      whiteSpace: 'nowrap',
      textOverflow: 'ellipsis',
    } as CSSStyleDeclaration)
    labelElem.appendChild(editor.dom.doc.createTextNode(placeholderInfo.visibleLabel))

    // Handle type specific stying
    switch (placeholderInfo.type) {
      case 'inline':
        Object.assign(placeholderElem.style, {
          flexDirection: 'row',
          justifyContent: 'start',
          padding: '5px',
          verticalAlign: 'baseline',
          gap: '8px',
          backgroundColor: '#F5F5F5',
        } as CSSStyleDeclaration)
        break

      case 'block':
        {
          const {width, height, vAlign, backgroundImageUrl} = placeholderInfo

          Object.assign(placeholderElem.style, {
            flexDirection: 'column',
            justifyContent: 'center',

            minWidth: '128px',
            width,
            maxWidth: '100%',

            minHeight: '128px',
            height,
            maxHeight: '90vh',

            verticalAlign: vAlign,
            backgroundColor: '#FFFFFF',
          } as CSSStyleDeclaration)

          if (backgroundImageUrl != null) {
            const imageElem = document.createElement('img')
            imageElem.src = backgroundImageUrl
            placeholderElem.insertBefore(imageElem, placeholderElem.firstElementChild)

            Object.assign(imageElem.style, {
              // The image should fill the placeholder
              position: 'absolute',
              left: '0px',
              top: '0px',
              width: '100%',
              height: '100%',

              // Aspect ratio should be maintained, though
              objectFit: 'cover',
              objectPosition: 'center center',

              // UI calls for a 80% white overlay, which is equivalent to a 20% opacity image on white
              opacity: '.2',
            } as CSSStyleDeclaration)
          }
        }
        break

      default:
        // Ensure all valid placeholderInfo types are handled above.
        assertNever(placeholderInfo)
    }
  })

  // Prevent user interaction with the placeholder elements
  placeholderElem.querySelectorAll('*').forEach(elem => {
    if (elem instanceof HTMLElement) {
      elem.style.pointerEvents = 'none'
      elem.style.userSelect = 'none'
      elem.setAttribute('aria-hidden', 'true')
    }
  })

  return placeholderElem
}

/**
 * Something for which a placeholder can be added to the editor.
 */
export interface PlaceHoldableThingInfo {
  name?: string
  type?: string
  title?: string
  contentType?: string
  displayAs?: 'link' | string
  domObject: File | Blob | {preview?: string}
}

/**
 * Style of placeholder to be inserted into the editor.
 */
export type PlaceholderInfo = {
  visibleLabel: string
  ariaLabel: string
} & (
  | {
      type: 'inline'
    }
  | {
      type: 'block'
      backgroundImageUrl?: string
      width: string
      height: string
      vAlign: string
    }
)

let placeholderIdCounter = 0

/**
 * A fully standalone version of InstUI <Spinner> that can be used inside TinyMCE's iframe without access to
 * Canvas's CSS or JS.
 */
// language=html
function spinnerSvg(size: 'x-small' | 'small' | 'medium' | 'large', labelId: string) {
  const radius = (() => {
    switch (size) {
      case 'x-small':
        return '0.5em'
      case 'small':
        return '1em'
      case 'large':
        return '2.25em'
      default:
        return '1.75em'
    }
  })()

  return `
  <span class="Spinner-root Spinner-default Spinner-${size}" role="presentation">
		<svg class="Spinner-circle"
		     role="img"
		     focusable="false"
		     aria-labelledby="${labelId}"
		>
			<style>
				@keyframes Spinner-rotate {
					to {
						transform: rotate(360deg);
					}
				}
				@keyframes Spinner-morph {
					0% {
						stroke-dashoffset: 190%;
					}
					50% {
						stroke-dashoffset: 50%;
						transform: rotate(90deg);
					}
					100% {
						stroke-dashoffset: 190%;
						transform: rotate(360deg);
					}
				}
				.Spinner-root {
					display: inline-block;
					vertical-align: middle;
					position: relative;
					box-sizing: border-box;
					overflow: hidden;
					--Spinner-trackColor: #F5F5F5;
					--Spinner-color: #0374B5;
					--Spinner-xSmallSize: 1.5em;
					--Spinner-xSmallBorderWidth: 0.25em;
					--Spinner-smallSize: 3em;
					--Spinner-smallBorderWidth: 0.375em;
					--Spinner-mediumSize: 5em;
					--Spinner-mediumBorderWidth: 0.5em;
					--Spinner-largeSize: 7em;
					--Spinner-largeBorderWidth: 0.75em;
					--Spinner-inverseColor: #0374B5;
				}

				.Spinner-circleTrack {
					stroke: var(--Spinner-trackColor);
					
					/* Give the track extra width per UI */
					stroke-width: calc(var(--Spinner-trackWidth) + 4px);
				}
				
				.Spinner-circleSpin {
					stroke-width: var(--Spinner-trackWidth);
				}

				.Spinner-x-small {
					width: var(--Spinner-xSmallSize);
					height: var(--Spinner-xSmallSize);
					
					--Spinner-trackWidth:  var(--Spinner-xSmallBorderWidth);
				}
				.Spinner-x-small .Spinner-circle {
					width: var(--Spinner-xSmallSize);
					height: var(--Spinner-xSmallSize);
				}
				.Spinner-x-small .Spinner-circleSpin {
					stroke-dasharray: 3em;
					transform-origin: 50% 50%;
				}

				.Spinner-small {
					width: var(--Spinner-smallSize);
					height: var(--Spinner-smallSize);
					--Spinner-trackWidth:  var(--Spinner-smallBorderWidth);
				}
				.Spinner-small .Spinner-circle {
					width: var(--Spinner-smallSize);
					height: var(--Spinner-smallSize);
				}
				.Spinner-small .Spinner-circleTrack,
				.Spinner-small .Spinner-circleSpin {
					stroke-dasharray: 6em;
					transform-origin: 50% 50%;
				}

				.Spinner-medium {
					width: var(--Spinner-mediumSize);
					height: var(--Spinner-mediumSize);
					
					--Spinner-trackWidth:  var(--Spinner-mediumBorderWidth);
				}
				.Spinner-medium .Spinner-circle {
					stroke-width: var(--Spinner-mediumBorderWidth);
					width: var(--Spinner-mediumSize);
					height: var(--Spinner-mediumSize);
				}
				.Spinner-medium .Spinner-circleSpin {
					stroke-dasharray: 10.5em;
					transform-origin: 50% 50%;
				}

				.Spinner-large {
					width: var(--Spinner-largeSize);
					height: var(--Spinner-largeSize);
					
					--Spinner-trackWidth:  var(--Spinner-largeBorderWidth);
				}
				.Spinner-large .Spinner-circle {
					stroke-width: var(--Spinner-largeBorderWidth);
					width: var(--Spinner-largeSize);
					height: var(--Spinner-largeSize);
				}
				.Spinner-large .Spinner-circleSpin {
					stroke-dasharray: 14em;
					transform-origin: 50% 50%;
				}

				.Spinner-circle {
					display: block;
					position: absolute;
					top: 0;
					left: 0;
					/* stylelint-disable-line property-blacklist */
					animation-name: Spinner-rotate;
					animation-duration: 2.25s;
					animation-iteration-count: infinite;
					animation-timing-function: linear;
				}

				.Spinner-circleTrack,
				.Spinner-circleSpin {
					fill: none;
				}

				.Spinner-circleSpin {
					stroke-linecap: round;
				}

				.Spinner-root:not(.ie11) .Spinner-circleSpin {
					animation-name: Spinner-morph;
					animation-duration: 1.75s;
					animation-iteration-count: infinite;
					animation-timing-function: ease;
				}

				.Spinner-root.ie11 .Spinner-circleSpin {
					stroke-dashoffset: 100%;
				}

				.Spinner-default .Spinner-circleSpin {
					stroke: var(--Spinner-color);
				}

				.Spinner-inverse .Spinner-circleSpin {
					stroke: var(--Spinner-inverseColor);
				}
			</style>
			<g role="presentation">
				<circle class="Spinner-circleTrack" cx="50%" cy="50%" r="${radius}"></circle>
				<circle class="Spinner-circleSpin" cx="50%" cy="50%" r="${radius}"></circle>
			</g>
		</svg>
  </span>
`
}
