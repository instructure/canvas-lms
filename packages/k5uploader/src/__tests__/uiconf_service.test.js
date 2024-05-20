/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import UiconfService from '../uiconf_service'

describe('UiconfService', () => {
  it('parses XML ui config', () => {
    const kalturaXml = `
      <xml>
        <result>
          <ui_conf>
            <id>undefined</id>
            <partnerId>1</partnerId>
            <objType>5</objType>
            <objTypeAsString>Playlist</objTypeAsString>
            <name>kupload 1.1.7</name>
            <swfUrl>http://notorious-web.inseng.test/flash/kupload/v1.1.7/KUpload.swf</swfUrl>
            <confFilePath>/path/to/config/undefined.xml</confFilePath>
            <confFile>&lt;?xml version="1.0" encoding="UTF-8"?&gt;
      &lt;KUploadConfiguration conversionProfile="2"&gt;
      &lt;fileFilters default="Any"&gt;
      &lt;fileFilter id="image" description="images" extensions="*.jpg;*.jpeg;*.bmp;*.png;*.gif;*.tif;*.tiff" entryType="1" mediaType="2"/&gt;
      &lt;fileFilter id="video" description="videos" extensions="*.flv;*.asf;*.qt;*.mov;*.mpg;*.mpeg;*.avi;*.wmv;*.mp4;*.m4v;*.3gp;*.mkv;*.aac;*.amr" type="1" entryType="1" mediaType="1"/&gt;
      &lt;fileFilter id="audio" description="audio" extensions="*.flv;*.asf;*.wmv;*.qt;*.mov;*.mpg;*.avi;*.mp3;*.wav;*.mp4;*.wma;*.3gp;*.m4a;*.ogg;*.flac;*.aac;*.amr" entryType="1" mediaType="5"/&gt;
      &lt;fileFilter id="media" description="images/videos/audio" extensions="*.qt;*.mov;*.mpg;*.avi;*.mp3;*.wav;*.mp4;*.wma;*.flv;*.asf;*.qt;*.mov;*.mpeg;*.avi;*.wmv;*.m4v;*.3gp;*.jpg;*.jpeg;*.bmp;*.png;*.gif;*.tif;*.tiff;*.aac;*.amr" entryType="1" mediaType="-1"/&gt;
      &lt;fileFilter id="documents" description="documents" extensions="*.csv;*.doc;*.docx;*.txt;*.xls;*.xlsx;*.ppt;*.pptx;*.pdf;*.rtf;*.tab;*.gif;*.jpg;*.jpeg;*.art;*.bmp;*.tif" entryType="10" mediaType="-1"/&gt;
      &lt;fileFilter id="swfdocuments" description="swf" extensions="*.swf" entryType="10" mediaType="12"/&gt;
      &lt;fileFilter id="Any" description="documents/images/videos/audio/swfdocuments" extensions="*.swf;*.csv;*.doc;*.docx;*.txt;*.xls;*.xlsx;*.ppt;*.pptx;*.pdf;*.rtf;*.tab;*.mov;*.mpg;*.avi;*.mp3;*.wav;*.mp4;*.wma;*.flv;*.asf;*.qt;*.mov;*.mpg;*.mpeg;*.avi;*.wmv;*.m4v;*.3gp;*.wav;*.mp4;*.jpg;*.jpeg;*.art;*.bmp;*.png;*.gif;*.tif;*.tiff" entryType="-1" mediaType="-1"/&gt;
      &lt;/fileFilters&gt;
      &lt;limits maxUploads="60" maxFileSize="500" maxTotalSize="9999999999"/&gt;
      &lt;/KUploadConfiguration&gt;
      </confFile>
            <useCdn>1</useCdn>
          </ui_conf>
        </result>
      </xml>
    `
    const uiconfService = new UiconfService()
    uiconfService.xhr = {response: kalturaXml}
    uiconfService.onXhrLoad()
    expect(uiconfService.config.maxFileSize).toEqual('500')
    expect(uiconfService.config.maxUploads).toEqual('60')
    expect(uiconfService.config.maxTotalSize).toEqual('9999999999')
    expect(uiconfService.config.fileFilters).toEqual([
      {
        extensions: ['jpg', 'jpeg', 'bmp', 'png', 'gif', 'tif', 'tiff'],
        id: 'image',
        description: 'images',
        entryType: '1',
        mediaType: '2',
        type: null,
      },
      {
        extensions: [
          'flv',
          'asf',
          'qt',
          'mov',
          'mpg',
          'mpeg',
          'avi',
          'wmv',
          'mp4',
          'm4v',
          '3gp',
          'mkv',
          'aac',
          'amr',
        ],
        id: 'video',
        description: 'videos',
        entryType: '1',
        mediaType: '1',
        type: '1',
      },
      {
        extensions: [
          'flv',
          'asf',
          'wmv',
          'qt',
          'mov',
          'mpg',
          'avi',
          'mp3',
          'wav',
          'mp4',
          'wma',
          '3gp',
          'm4a',
          'ogg',
          'flac',
          'aac',
          'amr',
        ],
        id: 'audio',
        description: 'audio',
        entryType: '1',
        mediaType: '5',
        type: null,
      },
      {
        extensions: [
          'qt',
          'mov',
          'mpg',
          'avi',
          'mp3',
          'wav',
          'mp4',
          'wma',
          'flv',
          'asf',
          'qt',
          'mov',
          'mpeg',
          'avi',
          'wmv',
          'm4v',
          '3gp',
          'jpg',
          'jpeg',
          'bmp',
          'png',
          'gif',
          'tif',
          'tiff',
          'aac',
          'amr',
        ],
        id: 'media',
        description: 'images/videos/audio',
        entryType: '1',
        mediaType: '-1',
        type: null,
      },
      {
        extensions: [
          'csv',
          'doc',
          'docx',
          'txt',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'pdf',
          'rtf',
          'tab',
          'gif',
          'jpg',
          'jpeg',
          'art',
          'bmp',
          'tif',
        ],
        id: 'documents',
        description: 'documents',
        entryType: '10',
        mediaType: '-1',
        type: null,
      },
      {
        extensions: ['swf'],
        id: 'swfdocuments',
        description: 'swf',
        entryType: '10',
        mediaType: '12',
        type: null,
      },
      {
        extensions: [
          'swf',
          'csv',
          'doc',
          'docx',
          'txt',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'pdf',
          'rtf',
          'tab',
          'mov',
          'mpg',
          'avi',
          'mp3',
          'wav',
          'mp4',
          'wma',
          'flv',
          'asf',
          'qt',
          'mov',
          'mpg',
          'mpeg',
          'avi',
          'wmv',
          'm4v',
          '3gp',
          'wav',
          'mp4',
          'jpg',
          'jpeg',
          'art',
          'bmp',
          'png',
          'gif',
          'tif',
          'tiff',
        ],
        id: 'Any',
        description: 'documents/images/videos/audio/swfdocuments',
        entryType: '-1',
        mediaType: '-1',
        type: null,
      },
    ])
  })
})
