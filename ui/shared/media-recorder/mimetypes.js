/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

// should be kept up to date with packages/canvas-media/src/shared/constants.js
export function mediaExtension(mimeType) {
  return {
    'video/3gpp2': '3g2',
    'video/3gpp': '3gp',
    'audio/ac3': 'ac3',
    'audio/x-aiff': 'aif',
    'audio/AMR': 'amr',
    'audio/x-ape': 'ape',
    'video/x-ms-asf': 'asf',
    'audio/x-ms-asx': 'asx',
    'audio/basic': 'au',
    'video/x-msvideo': 'avi',
    'audio/AMR-WB': 'awb',
    'video/dl': 'dl',
    'video/dv': 'dv',
    'audio/vnd.nuera.ecelp4800': 'ecelp4800',
    'audio/vnd.nuera.ecelp7470': 'ecelp7470',
    'audio/vnd.nuera.ecelp9600': 'ecelp9600',
    'audio/vnd.digital-winds': 'eol',
    'audio/EVRC': 'evc',
    'audio/x-flac': 'flac',
    'video/x-flic': 'flc',
    'video/gl': 'gl',
    'audio/x-it': 'it',
    'audio/L16': 'l16',
    'audio/vnd.lucent.voice': 'lvp',
    'audio/mp4': 'm4a',
    'audio/x-m4b': 'm4b',
    'audio/midi': 'mid',
    'audio/x-minipsf': 'minipsf',
    'video/MJ2': 'mj2',
    'audio/x-matroska': 'mka',
    'video/x-matroska': 'mkv',
    'video/x-mng': 'mng',
    'audio/x-mod': 'mod',
    'video/quicktime': 'mov',
    'video/x-sgi-movie': 'movie',
    'audio/mp2': 'mp2',
    'audio/mpeg': 'mp3',
    'video/mp4': 'mp4',
    'audio/x-musepack': 'mpc',
    'video/mpeg': 'mpg',
    'audio/vnd.nokia.mobile-xmf': 'mxmf',
    'video/vnd.mpegurl': 'mxu',
    'video/vnd.nokia.interleaved-multimedia': 'nim',
    'video/x-nsv': 'nsv',
    'audio/ogg': 'oga',
    'video/x-ogm+ogg': 'ogm',
    'video/ogg': 'ogv',
    'audio/x-iriver-pla': 'pla',
    'audio/vnd.everad.plj': 'plj',
    'audio/x-scpls': 'pls',
    'audio/x-psf': 'psf',
    'audio/x-psflib': 'psflib',
    'audio/QCELP': 'qcp',
    'audio/vnd.rn-realaudio': 'ra',
    'audio/x-pn-realaudio': 'ram',
    'video/vnd.rn-realvideo': 'rv',
    'video/vnd.sealed.mpeg1': 's11',
    'audio/x-s3m': 's3m',
    'audio/prs.sid': 'sid',
    'video/vnd.sealedmedia.softseal.mov': 'smo',
    'audio/vnd.sealedmedia.softseal.mpeg': 'smp',
    'video/vnd.sealed.mpeg4': 'smpg',
    'audio/SMV': 'smv',
    'audio/x-speex': 'spx',
    'video/vnd.sealed.swf': 'ssw',
    'audio/x-tta': 'tta',
    'audio/vnd.nortel.vbk': 'vbk',
    'video/vivo': 'viv',
    'audio/x-mpegurl': 'vlc',
    'audio/x-voc': 'voc',
    'audio/x-wav': 'wav',
    'video/x-ms-wm': 'wm',
    'audio/x-ms-wma': 'wma',
    'video/x-ms-wmv': 'wmv',
    'audio/x-wavpack-correction': 'wvc',
    'audio/x-wavpack': 'wvp',
    'audio/x-xi': 'xi',
    'audio/x-xm': 'xm',
  }[mimeType]
}
