import _objectSpread from "@babel/runtime/helpers/esm/objectSpread2";
import _slicedToArray from "@babel/runtime/helpers/esm/slicedToArray";
import _objectWithoutProperties from "@babel/runtime/helpers/esm/objectWithoutProperties";
const _excluded = ["autosave", "defaultContent", "editorOptions", "height", "highContrastCSS", "instRecordDisabled", "language", "liveRegion", "mirroredAttrs", "readOnly", "textareaId", "textareaClassName", "rcsProps", "use_rce_buttons_and_icons", "use_rce_a11y_checker_notifications", "onFocus", "onBlur", "onInit", "onContentChange"];

var _process, _process$env;

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
import React, { forwardRef, useState } from 'react';
import { arrayOf, bool, func, number, objectOf, oneOfType, shape, string } from 'prop-types';
import formatMessage from "../format-message.js";
import RCEWrapper, { editorOptionsPropType, ltiToolsPropType } from "./RCEWrapper.js";
import { trayPropTypes } from "./plugins/shared/CanvasContentTray.js";
import editorLanguage from "./editorLanguage.js";
import normalizeLocale from "./normalizeLocale.js";
import wrapInitCb from "./wrapInitCb.js";
import tinyRCE from "./tinyRCE.js";
import defaultTinymceConfig from "../defaultTinymceConfig.js";
import getTranslations from "../getTranslations.js";
import '@instructure/canvas-theme';

if (!((_process = process) !== null && _process !== void 0 && (_process$env = _process.env) !== null && _process$env !== void 0 && _process$env.BUILD_LOCALE)) {
  formatMessage.setup({
    locale: 'en',
    generateId: require('format-message-generate-id/underscored_crc32'),
    missingTranslation: 'ignore'
  });
} // forward rceRef to it refs the RCEWrapper where clients can call getCode etc. on it.
// You probably shouldn't use it until onInit has been called. Until then tinymce
// is not initialized.


const RCE = /*#__PURE__*/forwardRef(function (props, rceRef) {
  const autosave = props.autosave,
        defaultContent = props.defaultContent,
        editorOptions = props.editorOptions,
        height = props.height,
        highContrastCSS = props.highContrastCSS,
        instRecordDisabled = props.instRecordDisabled,
        language = props.language,
        liveRegion = props.liveRegion,
        mirroredAttrs = props.mirroredAttrs,
        readOnly = props.readOnly,
        textareaId = props.textareaId,
        textareaClassName = props.textareaClassName,
        rcsProps = props.rcsProps,
        use_rce_buttons_and_icons = props.use_rce_buttons_and_icons,
        use_rce_a11y_checker_notifications = props.use_rce_a11y_checker_notifications,
        onFocus = props.onFocus,
        onBlur = props.onBlur,
        onInit = props.onInit,
        onContentChange = props.onContentChange,
        rest = _objectWithoutProperties(props, _excluded);

  useState(() => formatMessage.setup({
    locale: normalizeLocale(props.language)
  }));

  const _useState = useState(() => {
    const locale = normalizeLocale(props.language);
    const p = getTranslations(locale).then(() => {
      setTranslations(true);
    }).catch(err => {
      // eslint-disable-next-line no-console
      console.error('Failed loading the language file for', locale, '\n Cause:', err);
      setTranslations(false);
    });
    return p;
  }, []),
        _useState2 = _slicedToArray(_useState, 2),
        translations = _useState2[0],
        setTranslations = _useState2[1]; // some properties are only used on initialization
  // Languages is a bit of a mess. Tinymce and Canvas
  // have 2 different sets of language names. normalizeLocale
  // takes the language prop and returns the locale Canvas knows,
  // editorLanguage takes the language prop and returns the
  // corresponding locale for tinymce.


  const _useState3 = useState(() => {
    const iProps = {
      autosave,
      defaultContent,
      highContrastCSS,
      instRecordDisabled,
      language: normalizeLocale(language),
      liveRegion,
      textareaId,
      textareaClassName,
      trayProps: rcsProps,
      use_rce_buttons_and_icons,
      use_rce_a11y_checker_notifications,
      editorOptions: Object.assign(editorOptions, editorOptions, {
        selector: `#${textareaId}`,
        height,
        language: editorLanguage(props.language)
      })
    };
    wrapInitCb(mirroredAttrs, iProps.editorOptions);
    return iProps;
  }),
        _useState4 = _slicedToArray(_useState3, 1),
        initOnlyProps = _useState4[0];

  if (typeof translations !== 'boolean') {
    return formatMessage('Loading...');
  } else {
    return /*#__PURE__*/React.createElement(RCEWrapper, Object.assign({
      ref: rceRef,
      tinymce: tinyRCE,
      readOnly: readOnly
    }, initOnlyProps, {
      onFocus: onFocus,
      onBlur: onBlur,
      onContentChange: onContentChange,
      onInitted: onInit
    }, rest));
  }
});
export default RCE;
RCE.propTypes = {
  // do you want the rce to autosave content to localStorage, and
  // how long should it be until it's deleted.
  // If autosave is enabled, call yourRef.RCEClosed() if the user
  // exits the page normally (e.g. via Cancel or Save)
  autosave: shape({
    enabled: bool,
    maxAge: number
  }),
  // the initial content
  defaultContent: string,
  // tinymce configuration. See defaultTinymceConfig for all the defaults
  // and RCEWrapper.editorOptionsPropType for stuff you may want to include
  editorOptions: editorOptionsPropType,
  // there's an open bug when RCE is rendered in a Modal form
  // and the user navigates to the KB Shortcut Helper Button using
  // Apple VoiceOver navigation keys (VO+arrows)
  // as a workaround, the KB Shortcut Helper Button may be supressed
  // setting renderKBShortcutModal to false
  renderKBShortcutModal: bool,
  //
  // height of the RCE. if a number, in px
  height: oneOfType([number, string]),
  // array of URLs to high-contrast css
  highContrastCSS: arrayOf(string),
  // if true, do not load the plugin that provides the media toolbar and menu items
  instRecordDisabled: bool,
  // locale of the user's language
  language: string,
  // list of all supported languages. This is the list of languages
  // shown to the user when adding closed captions to videos.
  // If you are not supporting media uploads, this is not necessary.
  // Defaults to [{id: 'en', label: 'English'}]
  languages: arrayOf(shape({
    // the id is the locale
    id: string.isRequired,
    // the label to show in the UI
    label: string.isRequired
  })),
  // function that returns the element where screenreader alerts go
  liveRegion: func,
  // array of lti tools available to the user
  // {id, favorite} are all that's required, ther fields are ignored
  ltiTools: ltiToolsPropType,
  // The maximum number of RCEs that will render on page load.
  // Any more than this will be deferred until it is nearly
  // scrolled into view.
  // if isNaN or <=0, render them all
  maxInitRenderedRCEs: number,
  // name:value pairs of attributes to add to the textarea
  // tinymce creates as the backing store of the RCE
  mirroredAttrs: objectOf(string),
  // is this RCE readonly?
  readOnly: bool,
  // id put on the generated textarea
  textareaId: string.isRequired,
  // class name added to the generated textarea
  textareaClassName: string,
  // properties necessary for the RCE to us the RCS
  // if missing, RCE features that require the RCS are omitted
  rcsProps: trayPropTypes,
  // enable the custom buttons feature (temporary until the feature is forced on)
  use_rce_buttons_and_icons: bool,
  // enable the a11y checker notifications (temporary until the feature is forced on)
  use_rce_a11y_checker_notifications: bool,
  // event handlers
  onFocus: func,
  // f(RCEWrapper component)
  onBlur: func,
  // f(event)
  onInit: func,
  // f(tinymce_editor)
  onContentChange: func // f(content), don't mistake this as an indication RCE is a controlled component

};
RCE.defaultProps = {
  autosave: {
    enabled: false,
    maxAge: 3600000
  },
  defaultContent: '',
  editorOptions: _objectSpread({}, defaultTinymceConfig),
  renderKBShortcutModal: true,
  highContrastCSS: [],
  instRecordDisabled: false,
  language: 'en',
  liveRegion: () => document.getElementById('flash_screenreader_holder'),
  maxInitRenderedRCEs: -1,
  mirroredAttrs: {},
  readOnly: false,
  use_rce_buttons_and_icons: true,
  use_rce_a11y_checker_notifications: true,
  onFocus: () => {},
  onBlur: () => {},
  onContentChange: () => {},
  onInit: () => {}
};