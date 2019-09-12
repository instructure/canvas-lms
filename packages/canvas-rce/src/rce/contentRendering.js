/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import {cleanUrl} from './contentInsertionUtils';
import formatMessage from "../format-message";

export function renderLink(data, contents) {
  const linkAttrs = {...data}
  linkAttrs.href = linkAttrs.href || linkAttrs.url;
  delete linkAttrs.url
  if (linkAttrs.href) {
    linkAttrs.href = cleanUrl(linkAttrs.href);
  }
  linkAttrs.title = linkAttrs.title || formatMessage("Link");
  const children = contents || linkAttrs.text || linkAttrs.title;
  delete linkAttrs.selectionDetails
  delete linkAttrs.text
  linkAttrs.className = linkAttrs.class
  delete linkAttrs.class

  // renderToStaticMarkup isn't happy with bool attributes
  Object.keys(linkAttrs).forEach(attr => {
    if (typeof linkAttrs[attr] === 'boolean') linkAttrs[attr] = linkAttrs[attr].toString()
  })

  return renderToStaticMarkup(
    <a {...linkAttrs}>
      {children}
    </a>
  );
}

export function renderDoc(doc) {
  return `<a target="_blank" rel="noopener noreferrer" href="${doc.href}">${doc.display_name || doc.filename}</a>`
}

export function renderLinkedImage(linkElem, image) {
  const linkHref = linkElem.getAttribute("href");

  return renderToStaticMarkup(
    <a href={linkHref} data-mce-href={linkHref}>
      {constructJSXImageElement(image, { doNotLink: true })}
    </a>
  );
}

export function constructJSXImageElement(image, opts = {}) {
  const {href, url, title, display_name, alt_text, link, ...otherAttributes} = image
  const src = href || url;
  let altText = title || display_name
  if (alt_text) {
    if (alt_text.decorativeSelected) {
      altText = ''
      otherAttributes['data-is-decorative'] = 'true'
    } else {
      altText = alt_text.altText
    }
  }

  const ret = (
    <img
      alt={altText}
      src={src}
      width={image.width}
      height={image.height}
      {...otherAttributes}
    />
  )
  if (link && !opts.doNotLink) {
    return(
      <a href={link} target="_blank" rel="noopener noreferrer">
        {ret}
      </a>
    );
  }
  return ret
}

export function renderImage(image, opts) {
  return renderToStaticMarkup(constructJSXImageElement(image, opts));
}
