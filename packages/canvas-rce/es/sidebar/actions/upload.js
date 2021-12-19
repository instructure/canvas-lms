import _objectSpread from "@babel/runtime/helpers/esm/objectSpread2";

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
import { saveMediaRecording } from '@instructure/canvas-media';
import { headerFor, originFromHost } from "../sources/api.js";
import * as files from "./files.js";
import * as images from "./images.js";
import bridge from "../../bridge/index.js";
import { fileEmbed } from "../../common/mimeClass.js";
import { isPreviewable } from "../../rce/plugins/shared/Previewable.js";
import { isImage, isAudioOrVideo } from "../../rce/plugins/shared/fileTypeUtils.js";
import { fixupFileUrl } from "../../common/fileUrl.js";
export const COMPLETE_FILE_UPLOAD = 'COMPLETE_FILE_UPLOAD';
export const FAIL_FILE_UPLOAD = 'FAIL_FILE_UPLOAD';
export const FAIL_FOLDERS_LOAD = 'FAIL_FOLDERS_LOAD';
export const FAIL_MEDIA_UPLOAD = 'FAIL_MEDIA_UPLOAD';
export const MEDIA_UPLOAD_SUCCESS = 'MEDIA_UPLOAD_SUCCESS';
export const PROCESSED_FOLDER_BATCH = 'PROCESSED_FOLDER_BATCH';
export const QUOTA_EXCEEDED_UPLOAD = 'QUOTA_EXCEEDED_UPLOAD';
export const RECEIVE_FOLDER = 'RECEIVE_FOLDER';
export const START_FILE_UPLOAD = 'START_FILE_UPLOAD';
export const START_LOADING = 'START_LOADING';
export const START_MEDIA_UPLOADING = 'START_MEDIA_UPLOADING';
export const STOP_LOADING = 'STOP_LOADING';
export const STOP_MEDIA_UPLOADING = 'STOP_MEDIA_UPLOADING';
export const TOGGLE_UPLOAD_FORM = 'TOGGLE_UPLOAD_FORM';
export function startLoading() {
  return {
    type: START_LOADING
  };
}
export function stopLoading() {
  return {
    type: STOP_LOADING
  };
}
export function receiveFolder({
  id,
  name,
  parentId
}) {
  return {
    type: RECEIVE_FOLDER,
    id,
    name,
    parentId
  };
}
export function failFoldersLoad(error) {
  return {
    type: FAIL_FOLDERS_LOAD,
    error
  };
}
export function failMediaUpload(error) {
  bridge.showError(error);
  return {
    type: FAIL_MEDIA_UPLOAD,
    error
  };
}
export function mediaUploadSuccess() {
  return {
    type: MEDIA_UPLOAD_SUCCESS
  };
}
export function startUpload(fileMetaProps) {
  return {
    type: START_FILE_UPLOAD,
    file: fileMetaProps
  };
}
export function failUpload(error) {
  return {
    type: FAIL_FILE_UPLOAD,
    error
  };
}
export function quotaExceeded(error) {
  return {
    type: QUOTA_EXCEEDED_UPLOAD,
    error
  };
}
export function completeUpload(results) {
  return {
    type: COMPLETE_FILE_UPLOAD,
    results
  };
}
export function openOrCloseUploadForm() {
  return {
    type: TOGGLE_UPLOAD_FORM
  };
}
export function processedFolderBatch({
  folders
}) {
  return {
    type: PROCESSED_FOLDER_BATCH,
    folders
  };
}
export function startMediaUploading(fileMetaProps) {
  return {
    type: START_MEDIA_UPLOADING,
    payload: fileMetaProps
  };
}
export function stopMediaUploading() {
  return {
    type: STOP_MEDIA_UPLOADING
  };
}
export function activateMediaUpload(fileMetaProps) {
  return dispatch => {
    dispatch(startMediaUploading(fileMetaProps));
    bridge.insertImagePlaceholder(fileMetaProps);
  };
}
export function removePlaceholdersFor(name) {
  return dispatch => {
    dispatch(stopMediaUploading());
    bridge.removePlaceholders(name);
  };
}
export function allUploadCompleteActions(results, fileMetaProps, contextType) {
  const actions = [];
  actions.push(completeUpload(results));
  const fileProps = {
    id: results.id,
    name: results.display_name,
    url: results.preview_url,
    type: fileMetaProps.contentType,
    embed: fileEmbed(results)
  };
  actions.push(files.createAddFile(fileProps));
  actions.push(files.createInsertFile(fileMetaProps.parentFolderId, results.id));

  if (/^image\//.test(results['content-type'])) {
    actions.push(images.createAddImage(results, contextType));
  }

  return actions;
}
export function embedUploadResult(results, selectedTabType) {
  const embedData = fileEmbed(results);

  if (selectedTabType === 'images' && isImage(embedData.type) && results.displayAs !== 'link') {
    var _bridge$activeEditor, _bridge$activeEditor$;

    // embed the image after any current selection rather than link to it or replace it
    (_bridge$activeEditor = bridge.activeEditor()) === null || _bridge$activeEditor === void 0 ? void 0 : (_bridge$activeEditor$ = _bridge$activeEditor.mceInstance()) === null || _bridge$activeEditor$ === void 0 ? void 0 : _bridge$activeEditor$.selection.collapse();
    const file_props = {
      href: results.href || results.url,
      title: results.title,
      display_name: results.display_name || results.name || results.title || results.filename,
      alt_text: results.alt_text,
      isDecorativeImage: results.isDecorativeImage,
      content_type: results['content-type'],
      contextType: results.contextType,
      contextId: results.contextId,
      uuid: results.uuid
    };
    bridge.insertImage(file_props);
  } else if (selectedTabType === 'media' && isAudioOrVideo(embedData.type)) {
    var _bridge$activeEditor2, _bridge$activeEditor3;

    // embed media after any current selection rather than link to it or replace it
    (_bridge$activeEditor2 = bridge.activeEditor()) === null || _bridge$activeEditor2 === void 0 ? void 0 : (_bridge$activeEditor3 = _bridge$activeEditor2.mceInstance()) === null || _bridge$activeEditor3 === void 0 ? void 0 : _bridge$activeEditor3.selection.collapse(); // when we record audio, notorious thinks it's a video. use the content type we got
    // from the recoreded file, not the returned media object.

    bridge.embedMedia({
      id: results.id,
      embedded_iframe_url: results.embedded_iframe_url,
      href: results.href || results.url,
      media_id: results.media_id,
      title: results.title,
      type: embedData.type,
      contextType: results.contextType,
      contextId: results.contextId,
      uuid: results.uuid
    });
  } else {
    bridge.insertLink({
      'data-canvas-previewable': isPreviewable(results['content-type']),
      href: results.href || results.url,
      title: results.alt_text || results.display_name || results.name || results.title || results.filename,
      content_type: results['content-type'],
      embed: _objectSpread(_objectSpread({}, embedData), {}, {
        disablePreview: true
      }),
      target: '_blank',
      contextType: results.contextType,
      contextId: results.contextId,
      uuid: results.uuid
    }, false);
  }

  return results;
} // fetches the list of folders to select from when uploading a file

export function fetchFolders(bookmark) {
  return (dispatch, getState) => {
    dispatch(startLoading());

    const _getState2 = getState(),
          source = _getState2.source,
          jwt = _getState2.jwt,
          upload = _getState2.upload,
          host = _getState2.host,
          contextId = _getState2.contextId,
          contextType = _getState2.contextType;

    if (bookmark || upload.folders && Object.keys(upload.folders).length === 0) {
      return source.fetchFolders({
        jwt,
        host,
        contextId,
        contextType
      }, bookmark).then(({
        folders,
        bookmark
      }) => {
        dispatch(folders.map(receiveFolder));

        const _getState3 = getState(),
              upload = _getState3.upload;

        dispatch(processedFolderBatch(upload));

        if (bookmark) {
          dispatch(fetchFolders(bookmark));
        } else {
          dispatch(stopLoading());
        }
      }).catch(error => {
        dispatch(failFoldersLoad(error));
      });
    }
  };
} // uploads handled via canvas-media

export function mediaUploadComplete(error, uploadData) {
  const _ref = uploadData || {},
        mediaObject = _ref.mediaObject,
        uploadedFile = _ref.uploadedFile;

  return dispatch => {
    if (error) {
      dispatch(failMediaUpload(error));
      dispatch(removePlaceholdersFor(uploadedFile === null || uploadedFile === void 0 ? void 0 : uploadedFile.name));
    } else {
      const embedData = {
        embedded_iframe_url: mediaObject.embedded_iframe_url,
        media_id: mediaObject.media_object.media_id,
        type: uploadedFile.type,
        title: uploadedFile.title || uploadedFile.name
      };
      dispatch(removePlaceholdersFor(uploadedFile.name));
      embedUploadResult(embedData, 'media');
      dispatch(mediaUploadSuccess());
    }
  };
}
export function createMediaServerSession() {
  return (dispatch, getState) => {
    const _getState4 = getState(),
          source = _getState4.source;

    if (!bridge.mediaServerSession) {
      return source.mediaServerSession().then(data => {
        bridge.setMediaServerSession(data);
      });
    }
  };
}
export function uploadToButtonsAndIconsFolder(svg, uploadSettings = {}) {
  return (_dispatch, getState) => {
    const _getState5 = getState(),
          source = _getState5.source,
          jwt = _getState5.jwt,
          host = _getState5.host,
          contextId = _getState5.contextId,
          contextType = _getState5.contextType;

    const onDuplicate = uploadSettings.onDuplicate;
    const svgAsFile = new File([svg.domElement.outerHTML], svg.name, {
      type: 'image/svg+xml'
    });
    const fileMetaProps = {
      file: {
        name: svg.name,
        type: 'image/svg+xml'
      },
      name: svg.name
    };
    return source.fetchButtonsAndIconsFolder({
      jwt,
      host,
      contextId,
      contextType
    }).then(({
      folders
    }) => {
      fileMetaProps.parentFolderId = folders[0].id;
      return source.preflightUpload(fileMetaProps, {
        host,
        contextId,
        contextType,
        onDuplicate
      }).then(results => {
        return source.uploadFRD(svgAsFile, results);
      });
    });
  };
}
export function uploadToMediaFolder(tabContext, fileMetaProps) {
  return (dispatch, getState) => {
    var _editorComponent$edit;

    const editorComponent = bridge.activeEditor();
    const bookmark = editorComponent === null || editorComponent === void 0 ? void 0 : (_editorComponent$edit = editorComponent.editor) === null || _editorComponent$edit === void 0 ? void 0 : _editorComponent$edit.selection.getBookmark(2, true);
    dispatch(activateMediaUpload(fileMetaProps));

    const _getState6 = getState(),
          source = _getState6.source,
          jwt = _getState6.jwt,
          host = _getState6.host,
          contextId = _getState6.contextId,
          contextType = _getState6.contextType;

    if (tabContext === 'media' && fileMetaProps.domObject) {
      return saveMediaRecording(fileMetaProps.domObject, {
        contextId,
        contextType,
        origin: originFromHost(host),
        headers: headerFor(jwt)
      }, (err, uploadData) => {
        dispatch(mediaUploadComplete(err, uploadData));
      });
    }

    return source.fetchMediaFolder({
      jwt,
      host,
      contextId,
      contextType
    }).then(({
      folders
    }) => {
      fileMetaProps.parentFolderId = folders[0].id;

      if (fileMetaProps.domObject) {
        delete fileMetaProps.domObject.preview; // don't need this anymore
      }

      dispatch(uploadPreflight(tabContext, _objectSpread(_objectSpread({}, fileMetaProps), {}, {
        bookmark
      })));
    }).catch(e => {
      // Get rid of any placeholder that might be there.
      dispatch(removePlaceholdersFor(fileMetaProps.name)); // eslint-disable-next-line no-console

      console.error('Fetching the media folder failed.', e);
    });
  };
}
export function setUsageRights(source, fileMetaProps, results) {
  const usageRights = fileMetaProps.usageRights;

  if (usageRights) {
    source.setUsageRights(results.id, usageRights);
  }

  return results;
}
export function getFileUrlIfMissing(source, results) {
  if (results.href || results.url) {
    return Promise.resolve(results);
  }

  return source.getFile(results.id).then(file => {
    results.url = file.url;
    return results;
  });
}

function readUploadedFileAsDataURL(file, reader = new FileReader()) {
  return new Promise((resolve, reject) => {
    reader.onerror = () => {
      reader.abort();
      reject(new DOMException('Unable to parse file'));
    };

    reader.onload = () => {
      resolve(reader.result);
    };

    reader.readAsDataURL(file);
  });
}

export function generateThumbnailUrl(results, fileDOMObject, reader) {
  if (/^image\//.test(results['content-type'])) {
    return readUploadedFileAsDataURL(fileDOMObject, reader).then(result => {
      results.thumbnail_url = result;
      return results;
    });
  } else {
    return Promise.resolve(results);
  }
}
export function setAltText(altText, results) {
  if (altText) {
    results.alt_text = altText;
  }

  return results;
}
export function handleFailures(error, dispatch) {
  if (error && error.response) {
    return error.response.json().then(resp => {
      if (resp.message === 'file size exceeds quota') {
        dispatch(quotaExceeded(error));
      } else {
        dispatch(failUpload(error));
      }
    }).catch(error => dispatch(failUpload(error)));
  }

  if (error) {
    return Promise.resolve().then(() => dispatch(failUpload(error)));
  }
}
export function uploadPreflight(tabContext, fileMetaProps) {
  return (dispatch, getState) => {
    const _getState7 = getState(),
          source = _getState7.source,
          jwt = _getState7.jwt,
          host = _getState7.host,
          contextId = _getState7.contextId,
          contextType = _getState7.contextType;

    const fileReader = fileMetaProps.fileReader;
    dispatch(startUpload(fileMetaProps));
    return source.preflightUpload(fileMetaProps, {
      jwt,
      host,
      contextId,
      contextType
    }).then(results => {
      return source.uploadFRD(fileMetaProps.domObject, results);
    }).then(results => {
      return setUsageRights(source, fileMetaProps, results);
    }).then(results => {
      return getFileUrlIfMissing(source, results);
    }).then(results => {
      return fixupFileUrl(contextType, contextId, results);
    }).then(results => {
      return generateThumbnailUrl(results, fileMetaProps.domObject, fileReader);
    }).then(results => {
      return setAltText(fileMetaProps.altText, results);
    }).then(results => {
      if (fileMetaProps.isDecorativeImage) {
        results.isDecorativeImage = fileMetaProps.isDecorativeImage;
      }

      if (fileMetaProps.displayAs) {
        results.displayAs = fileMetaProps.displayAs;
      }

      return results;
    }).then(results => {
      // This may or may not be necessary depending on the upload
      dispatch(removePlaceholdersFor(fileMetaProps.name));
      return results;
    }).then(results => {
      let newBookmark;
      const editorComponent = bridge.activeEditor();

      if (fileMetaProps.bookmark) {
        newBookmark = editorComponent.editor.selection.getBookmark(2, true);
        editorComponent.editor.selection.moveToBookmark(fileMetaProps.bookmark);
      }

      const uploadResult = embedUploadResult(_objectSpread({
        contextType,
        contextId
      }, results), tabContext);

      if (fileMetaProps.bookmark) {
        editorComponent.editor.selection.moveToBookmark(newBookmark);
      }

      return uploadResult;
    }).then(results => {
      dispatch(allUploadCompleteActions(results, fileMetaProps, contextType));
    }).catch(err => {
      // This may or may not be necessary depending on the upload
      dispatch(removePlaceholdersFor(fileMetaProps.name));
      handleFailures(err, dispatch);
    });
  };
}