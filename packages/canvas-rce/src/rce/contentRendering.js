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
import formatMessage from "../format-message";

export function renderLink(link) {
  const href = link.href || link.url;
  const title =
    link.title ||
    formatMessage({
      default: "Link",
      description:
        "Fallback title attribute on an unnamed link inserted from the sidebar."
    });
  const previewAlt = link["data-preview-alt"];
  const contents = link.contents || title;

  return renderToStaticMarkup(
    <a
      href={href}
      title={title}
      data-preview-alt={previewAlt}
      className={link["class"]}
      id={link["id"]}
    >
      {contents}
    </a>
  );
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
  const href = image.href || image.url;
  let ret = <img alt={image.title || image.display_name} src={href} />;
  if (image.alt_text) {
    if (image.alt_text.decorativeSelected) {
      ret = <img alt="" data-decorative="true" src={href} />;
    } else {
      ret = <img alt={image.alt_text.altText} src={href} />;
    }
  }
  if (image.link && !opts.doNotLink) {
    ret = (
      <a href={image.link} target="_blank">
        {ret}
      </a>
    );
  }
  return ret;
}

export function renderImage(image) {
  return renderToStaticMarkup(constructJSXImageElement(image));
}
