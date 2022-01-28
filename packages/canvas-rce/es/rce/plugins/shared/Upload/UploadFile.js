import _slicedToArray from "@babel/runtime/helpers/esm/slicedToArray";

/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import React, { useEffect, useState } from 'react';
import ReactDOM from 'react-dom';
import { arrayOf, bool, func, object, oneOf, oneOfType, string } from 'prop-types';
import { px } from '@instructure/ui-utils';
import indicatorRegion from "../../../indicatorRegion.js";
import { isImage, isAudioOrVideo } from "../fileTypeUtils.js";
import indicate from "../../../../common/indicate.js";
import { StoreProvider } from "../StoreContext.js";
import Bridge from "../../../../bridge/index.js";
import UploadFileModal from "./UploadFileModal.js";
/**
 * Handles uploading data based on what type of data is submitted.
 */

export const handleSubmit = (editor, accept, selectedPanel, uploadData, storeProps, source, afterInsert = () => {}) => {
  Bridge.focusEditor(editor.rceWrapper); // necessary since it blurred when the modal opened

  const _ref = (uploadData === null || uploadData === void 0 ? void 0 : uploadData.imageOptions) || {},
        altText = _ref.altText,
        isDecorativeImage = _ref.isDecorativeImage,
        displayAs = _ref.displayAs;

  switch (selectedPanel) {
    case 'COMPUTER':
      {
        var _uploadData$usageRigh;

        const theFile = uploadData.theFile;
        const fileMetaData = {
          parentFolderId: 'media',
          name: theFile.name,
          size: theFile.size,
          contentType: theFile.type,
          domObject: theFile,
          altText,
          isDecorativeImage,
          displayAs,
          usageRights: (uploadData === null || uploadData === void 0 ? void 0 : (_uploadData$usageRigh = uploadData.usageRights) === null || _uploadData$usageRigh === void 0 ? void 0 : _uploadData$usageRigh.usageRight) === 'choose' ? void 0 : uploadData === null || uploadData === void 0 ? void 0 : uploadData.usageRights
        };
        let tabContext = 'documents';

        if (isImage(theFile.type)) {
          tabContext = 'images';
        } else if (isAudioOrVideo(theFile.type)) {
          tabContext = 'media';
        }

        storeProps.startMediaUpload(tabContext, fileMetaData);
        break;
      }

    case 'UNSPLASH':
      {
        const unsplashData = uploadData.unsplashData;
        source.pingbackUnsplash(unsplashData.id);
        let editorHtml;

        if (displayAs !== 'link' && /image/.test(accept)) {
          editorHtml = editor.dom.createHTML('img', {
            src: unsplashData.url,
            alt: altText || unsplashData.alt,
            role: isDecorativeImage ? 'presentation' : void 0
          });
        } else {
          editorHtml = editor.dom.createHTML('a', {
            href: unsplashData.url
          }, altText || unsplashData.url);
        }

        editor.insertContent(editorHtml);
        break;
      }

    case 'URL':
      {
        const fileUrl = uploadData.fileUrl;
        let editorHtml;

        if (displayAs !== 'link' && /image/.test(accept)) {
          editorHtml = editor.dom.createHTML('img', {
            src: fileUrl,
            alt: altText,
            role: isDecorativeImage ? 'presentation' : void 0
          });
        } else {
          editorHtml = editor.dom.createHTML('a', {
            href: fileUrl
          }, altText || fileUrl);
        }

        editor.insertContent(editorHtml);
        break;
      }

    default:
      throw new Error('Selected Panel is invalid');
    // Should never get here
  }

  const element = editor.selection.getEnd();
  element.addEventListener('load', () => indicate(indicatorRegion(editor, element)));
  afterInsert();
};
export function UploadFile({
  accept,
  editor,
  label,
  panels,
  onDismiss,
  requireA11yAttributes = true,
  trayProps,
  onSubmit = handleSubmit
}) {
  const _useState = useState(void 0),
        _useState2 = _slicedToArray(_useState, 2),
        modalBodyWidth = _useState2[0],
        setModalBodyWidth = _useState2[1];

  const _useState3 = useState(void 0),
        _useState4 = _slicedToArray(_useState3, 2),
        modalBodyHeight = _useState4[0],
        setModalBodyHeight = _useState4[1];

  const bodyRef = React.useRef();
  trayProps = trayProps || Bridge.trayProps.get(editor); // the panels get rendered inside tab panels. it's difficult for them to
  // figure out how much space they have to work with, and I'd like the previews
  // not to trigger scrollbars in the modal's body. Get the Modal.Body's size
  // and to the ComputerPanel how much space it has so it can render the file preview

  useEffect(() => {
    if (bodyRef.current) {
      // eslint-disable-next-line react/no-find-dom-node
      const thebody = ReactDOM.findDOMNode(bodyRef.current);
      const sz = thebody.getBoundingClientRect();
      sz.height -= px('3rem'); // leave room for the tabs

      setModalBodyWidth(sz.width);
      setModalBodyHeight(sz.height);
    }
  }, [modalBodyHeight, modalBodyWidth]);
  return /*#__PURE__*/React.createElement(StoreProvider, trayProps, contentProps => /*#__PURE__*/React.createElement(UploadFileModal, {
    ref: bodyRef,
    editor: editor,
    trayProps: trayProps,
    contentProps: contentProps,
    onSubmit: onSubmit,
    onDismiss: onDismiss,
    panels: panels,
    label: label,
    accept: accept,
    modalBodyWidth: modalBodyWidth,
    modalBodyHeight: modalBodyHeight,
    requireA11yAttributes: requireA11yAttributes
  }));
}
UploadFile.propTypes = {
  onSubmit: func,
  onDismiss: func.isRequired,
  accept: oneOfType([arrayOf(string), string]),
  editor: object.isRequired,
  label: string.isRequired,
  panels: arrayOf(oneOf(['COMPUTER', 'UNSPLASH', 'URL'])),
  requireA11yAttributes: bool,
  trayProps: object
};