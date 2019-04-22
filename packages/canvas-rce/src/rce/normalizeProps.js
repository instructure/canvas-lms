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

import sanitizeEditorOptions from "./sanitizeEditorOptions";
import wrapInitCb from "./wrapInitCb";
import normalizeLocale from "./normalizeLocale";
import editorLanguage from "./editorLanguage";

export default function(props, tinymce, MutationObserver) {
  let initialEditorOptions = props.editorOptions(tinymce),
    sanitizedEditorOptions = sanitizeEditorOptions(initialEditorOptions),
    editorOptions = wrapInitCb(
      props.mirroredAttrs,
      sanitizedEditorOptions,
      MutationObserver
    );

  // propagate localization prop to appropriate parameter/value on the
  // editor configuration
  props.language = normalizeLocale(props.language);
  const language = editorLanguage(props.language);
  if (language !== undefined) {
    editorOptions.language = language;
    editorOptions.language_url = "none";
  }

  // It is expected that consumers provide their own content_css so that the
  // styles inside the editor match the styles of the site it is going to be
  // displayed in.
  if (props.editorOptions.content_css) {
    editorOptions.content_css = props.editorOptions.content_css;
  }

  // tell tinymce that we already loaded the skin
  editorOptions.skin = false;

  // force tinyMCE to NOT use the "mobile" theme,
  // see: https://stackoverflow.com/questions/54579110/is-it-possible-to-disable-the-mobile-ui-features-in-tinymce-5
  editorOptions.mobile = { theme: "silver" };

  // tell tinyMCE not to put its own branding in the footer of the editor
  editorOptions.branding = false;

  return {
    // other props, including overrides
    ...props,

    // enforced values, in addition to props and cannot be overridden by
    // props
    editorOptions,
    tinymce
  };
}
