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

export function fileEmbed(file) {
  let fileMimeClass = mimeClass(file);
  let fileMediaEntryId = mediaEntryId(file);

  if (fileMimeClass === "image") {
    return { type: "image" };
  } else if (fileMimeClass === "video") {
    return { type: "video", id: fileMediaEntryId };
  } else if (fileMimeClass === "audio") {
    return { type: "audio", id: fileMediaEntryId };
  } else if (file.preview_url) {
    return { type: "scribd" };
  } else {
    return { type: "file" };
  }
}

function mediaEntryId(file) {
  return file.media_entry_id || "maybe";
}

export function mimeClass(file) {
  if (file.mime_class) {
    return file.mime_class;
  } else {
    let contentType = getContentType(file);

    return (
      {
        "text/html": "html",
        "text/x-csharp": "code",
        "text/xml": "code",
        "text/css": "code",
        text: "text",
        "text/plain": "text",
        "application/rtf": "doc",
        "text/rtf": "doc",
        "application/vnd.oasis.opendocument.text": "doc",
        "application/pdf": "pdf",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
          "doc",
        "application/x-docx": "doc",
        "application/msword": "doc",
        "application/vnd.ms-powerpoint": "ppt",
        "application/vnd.openxmlformats-officedocument.presentationml.presentation":
          "ppt",
        "application/vnd.ms-excel": "xls",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
          "xls",
        "application/vnd.oasis.opendocument.spreadsheet": "xls",
        "image/jpeg": "image",
        "image/pjpeg": "image",
        "image/png": "image",
        "image/gif": "image",
        "application/x-rar": "zip",
        "application/x-rar-compressed": "zip",
        "application/x-zip": "zip",
        "application/x-zip-compressed": "zip",
        "application/xml": "code",
        "application/zip": "zip",
        "audio/mp3": "audio",
        "audio/mpeg": "audio",
        "audio/basic": "audio",
        "audio/mid": "audio",
        "audio/3gpp": "audio",
        "audio/x-aiff": "audio",
        "audio/x-mpegurl": "audio",
        "audio/x-pn-realaudio": "audio",
        "audio/x-wav": "audio",
        "video/mpeg": "video",
        "video/quicktime": "video",
        "video/x-la-asf": "video",
        "video/x-ms-asf": "video",
        "video/x-msvideo": "video",
        "video/x-sgi-movie": "video",
        "video/3gpp": "video",
        "video/mp4": "video",
        "application/x-shockwave-flash": "flash"
      }[contentType] || "file"
    );
  }
}

function getContentType(file) {
  return file["content-type"] || file.type;
}
