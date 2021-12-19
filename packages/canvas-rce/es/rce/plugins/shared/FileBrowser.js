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
import React, { useMemo } from 'react';
import { func, string } from 'prop-types';
import classnames from 'classnames';
import { View } from '@instructure/ui-view';
import { downloadToWrap } from "../../../common/fileUrl.js";
import { mediaPlayerURLFromFile } from "./fileTypeUtils.js";
import RceApiSource from "../../../sidebar/sources/api.js"; // TODO: should find a better way to share this code

import FileBrowser from "../../../canvasFileBrowser/FileBrowser.js";
import { isPreviewable } from "./Previewable.js";
RceFileBrowser.propTypes = {
  onFileSelect: func.isRequired,
  onAllFilesLoading: func.isRequired,
  searchString: string.isRequired
};
export default function RceFileBrowser(props) {
  const onFileSelect = props.onFileSelect,
        searchString = props.searchString,
        onAllFilesLoading = props.onAllFilesLoading,
        jwt = props.jwt,
        refreshToken = props.refreshToken,
        host = props.host,
        source = props.source;
  const apiSource = useMemo(() => {
    return source || new RceApiSource({
      jwt,
      refreshToken,
      host
    });
  }, [source]);
  return /*#__PURE__*/React.createElement(View, {
    as: "div",
    margin: "medium",
    "data-testid": "instructure_links-FilesPanel"
  }, /*#__PURE__*/React.createElement(FileBrowser, {
    selectFile: function (fileInfo) {
      var _fileInfo$api$embed;

      const content_type = fileInfo.api.type;
      const canPreview = isPreviewable(content_type);
      const clazz = classnames('instructure_file_link', {
        instructure_scribd_file: canPreview,
        inline_disabled: true
      });
      const url = downloadToWrap(fileInfo.src);
      const embedded_iframe_url = mediaPlayerURLFromFile(fileInfo.api);
      onFileSelect({
        name: fileInfo.name,
        title: fileInfo.name,
        href: url,
        embedded_iframe_url,
        media_id: (_fileInfo$api$embed = fileInfo.api.embed) === null || _fileInfo$api$embed === void 0 ? void 0 : _fileInfo$api$embed.id,
        target: '_blank',
        class: clazz,
        content_type
      });
    },
    contentTypes: ['**'],
    searchString: searchString,
    onLoading: onAllFilesLoading,
    source: apiSource,
    context: props.context
  }));
}