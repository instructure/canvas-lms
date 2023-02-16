// @ts-nocheck
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

import Formatter from './Formatter'
import spacing from './formatters/spacing'

enum MimeTypes {
  mathML = 'application/mathml+xml',
  html = 'text/html',
}

type ChunkerOptions = {
  selector?: string
  mathMLAttr?: string
  formatters?: Array<Formatter>
}

type Chunk = {
  content: string
  mimeType: MimeTypes
}

/**
 * Breaks content into chunks of content and MathML for
 * Microsoft Immersive Reader.
 *
 * Example:
 * content = `<div>
 *   <p>
 *     Some content
 *     <span class="math" data-mathml="...some MathML"></span
 *   </p>
 *   <p>
 *     More content
 *   </p>
 * </div>`
 *
 * contentChunker.chunk(content)
 *
 * => [
 *      { content: "<div><p>Some content", mimeType: "text/html" },
 *      { content: "<MathML from the data-attribut>", mimeType: "application/mathml+xml"},
 *      { content: "</p>Mp>More content</p></div>", mimeType: "text/html"}
 *    ]
 *
 * Note that some tags will be missing closing tags, while others miss opening tags.
 *
 * DOM parsers will automatically close the tags without closings and remove the tags without
 * openings.
 *
 * @constructor
 * @param {ChunkerOptions} options to controll how content
 *  is chunked.
 */
class ContentChunker {
  selector: string

  mathMLAttr: string

  formatters: Array<Formatter>

  parser: DOMParser

  constructor(opts: ChunkerOptions = {}) {
    this.selector = opts.selector || '.MathJax_SVG'
    this.mathMLAttr = opts.mathMLAttr || 'data-mathml'
    this.formatters = opts.formatters || [spacing]
    this.parser = new DOMParser()
  }

  chunk(content: string): Array<Chunk> {
    const chunks: Array<Chunk> = []
    const body = this.bodyFor(content)
    const mathElement = body.querySelector(this.selector)
    const [preMath, postMath] = body.innerHTML.split(mathElement?.outerHTML)

    // Add pre-math content
    chunks.push({content: this.applyFormatters(preMath), mimeType: MimeTypes.html})

    // Add the math
    if (mathElement) {
      chunks.push({
        content: mathElement.getAttribute(this.mathMLAttr) || '',
        mimeType: MimeTypes.mathML,
      })
      // Recursive base case: no more chunks to process
    } else if (!mathElement) {
      return chunks
    }

    // Recurse and concat results
    chunks.push(...this.chunk(postMath))
    return chunks
  }

  applyFormatters(content: string): string {
    let formattedContent = content

    this.formatters.forEach(formatter => {
      formattedContent = formatter(formattedContent, this.parser)
    })

    return formattedContent
  }

  bodyFor(content: string): HTMLElement {
    return this.parser.parseFromString(content, 'text/html').body
  }
}

export default ContentChunker
