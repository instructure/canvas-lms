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

import normalizeLocale from "./rce/normalizeLocale";
import { renderIntoDiv as render } from "./rce/root";
import "tinymce";

if (process.env.BUILD_LOCALE && process.env.BUILD_LOCALE !== "en") {
  try {
    // In a pretranslated build, this should not result in a network request for a new chunk.
    // We still tell tinymce about the translations it should use, but those should be included in
    // the same webpack chunk this file was included in. This approach will result in better
    // performance and smaller bundle size since it won't have to include all the chunk info
    // for all the possible locales in the webpack runtime and will be less network roundtrips.

    require(`./rce/languages/${process.env.BUILD_LOCALE}`);
  } catch (e) {
    // gracefully proceed if we do not have a language file for this locale
    // eslint-disable-next-line no-console
    console.warn(
      `could not find canvas-rce language: ${process.env.BUILD_LOCALE}`
    );
  }
}

export function renderIntoDiv(editorEl, props, cb) {
  const language = normalizeLocale(props.language);
  if (process.env.BUILD_LOCALE || language === "en") {
    render(editorEl, props, cb);
  } else {
    // unlike the pretranslated builds, in the default, non-pretranslated build,
    // this will cause a new network round trip to get all the locale info we
    // and tinymce need.
    import(`./locales/${language}`).then(() => render(editorEl, props, cb));
  }
}

export { renderIntoDiv as renderSidebarIntoDiv } from "./sidebar/root";
