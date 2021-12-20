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
import K5Uploader from '@instructure/k5uploader';
import { fileEmbed } from "../common/mimeClass.js";
/* eslint no-console: 0 */

export default class Bridge {
  constructor() {
    this.insertLink = link => {
      if (this.focusedEditor) {
        var _this$controller;

        const _this$focusedEditor$p = this.focusedEditor.props.tinymce.get(this.focusedEditor.props.textareaId),
              selection = _this$focusedEditor$p.selection;

        link.selectionDetails = {
          node: selection.getNode(),
          range: selection.getRng()
        };

        if (!link.text) {
          link.text = link.title || link.href;
        }

        this.focusedEditor.insertLink(link);
        (_this$controller = this.controller(this.focusedEditor.id)) === null || _this$controller === void 0 ? void 0 : _this$controller.hideTray();
      } else {
        console.warn('clicked sidebar link without a focused editor');
      }
    };

    this.insertFileLink = link => {
      const embedData = fileEmbed(link);

      if (embedData.type === 'image') {
        return this.insertImage(link);
      } else if (embedData.type === 'video' || embedData.type === 'audio') {
        link.embedded_iframe_url = link.embedded_iframe_url || link.href;
        return this.embedMedia(link);
      }

      return this.insertLink(link);
    };

    this.embedImage = image => {
      if (this.existingContentToLink() && !this.existingContentToLinkIsImg()) {
        this.insertLink({
          title: image.display_name,
          href: image.href,
          embed: {
            type: 'image'
          }
        });
      } else {
        this.insertImage(image);
      }
    };

    this.embedMedia = media => {
      const embedData = fileEmbed(media);

      if (embedData.type === 'video') {
        this.insertVideo(media);
      } else {
        this.insertAudio(media);
      }
    };

    this.insertEmbedCode = embedCode => {
      this.focusedEditor.insertEmbedCode(embedCode);
    };

    this.insertVideo = video => {
      if (this.focusedEditor) {
        var _this$controller2;

        this.focusedEditor.insertVideo(video);
        (_this$controller2 = this.controller(this.focusedEditor.id)) === null || _this$controller2 === void 0 ? void 0 : _this$controller2.hideTray();
      }
    };

    this.insertAudio = audio => {
      if (this.focusedEditor) {
        var _this$controller3;

        this.focusedEditor.insertAudio(audio);
        (_this$controller3 = this.controller(this.focusedEditor.id)) === null || _this$controller3 === void 0 ? void 0 : _this$controller3.hideTray();
      }
    };

    this.focusedEditor = null; // the RCEWrapper, not tinymce

    this.resolveEditorRendered = null;
    this._editorRendered = new Promise(resolve => {
      this.resolveEditorRendered = resolve;
    });
    this.trayProps = new WeakMap();
    this._languages = [];
    this._controller = {};
    this._uploadMediaTranslations = null;
  }

  get editorRendered() {
    return this._editorRendered;
  }

  controller(editorId) {
    return this._controller[editorId];
  }

  activeEditor() {
    return this.focusedEditor;
  }

  focusEditor(editor) {
    if (this.focusedEditor !== editor) {
      this.hideTrays();
    }

    this.focusedEditor = editor;
  }

  blurEditor(editor) {
    if (this.focusedEditor === editor) {
      this.hideTrays();
      this.focusedEditor = null;
    }
  }

  focusActiveEditor(skipFocus = false) {
    var _this$focusedEditor, _this$focusedEditor$m, _this$focusedEditor$m2;

    (_this$focusedEditor = this.focusedEditor) === null || _this$focusedEditor === void 0 ? void 0 : (_this$focusedEditor$m = _this$focusedEditor.mceInstance) === null || _this$focusedEditor$m === void 0 ? void 0 : (_this$focusedEditor$m2 = _this$focusedEditor$m.call(_this$focusedEditor)) === null || _this$focusedEditor$m2 === void 0 ? void 0 : _this$focusedEditor$m2.focus(skipFocus);
  }

  get mediaServerSession() {
    return this._mediaServerSession;
  }

  get mediaServerUploader() {
    return this._mediaServerUploader;
  }

  setMediaServerSession(session) {
    this._mediaServerSession = session;

    if (this._mediaServerUploader) {
      this._mediaServerUploader.destroy();

      this._mediaServerUploader = null;
    }

    this._mediaServerUploader = new K5Uploader(session);
  }

  get languages() {
    return this._languages;
  }

  set languages(langs) {
    this._languages = langs;
  } // we have to defer importing mediaTranslations until they are asked for
  // or they get imported before the locale has been setup and all the strings
  // are in English


  get uploadMediaTranslations() {
    if (!this._uploadMediaTranslations) {
      const module = require('../rce/plugins/instructure_record/mediaTranslations');

      this._uploadMediaTranslations = module.default;
    }

    return this._uploadMediaTranslations;
  }

  detachEditor(editor) {
    if (editor === this.focusedEditor) {
      this.focusedEditor = null;
    }
  }

  getEditor() {
    return this.focusedEditor;
  }

  renderEditor(editor) {
    this.resolveEditorRendered();

    if (this.focusedEditor === null) {
      this.focusEditor(editor);
    }
  }

  attachController(controller, editorId) {
    this._controller[editorId] = controller;
  }

  detachController(editorId) {
    delete this._controller[editorId];
  }

  showTrayForPlugin(plugin, editorId) {
    var _this$_controller$edi;

    (_this$_controller$edi = this._controller[editorId]) === null || _this$_controller$edi === void 0 ? void 0 : _this$_controller$edi.showTrayForPlugin(plugin);
  }

  hideTrays() {
    Object.keys(this._controller).forEach(eid => {
      this._controller[eid].hideTray(true);
    });
  }

  existingContentToLink() {
    if (this.focusedEditor) {
      return this.focusedEditor.existingContentToLink();
    }

    return false;
  }

  existingContentToLinkIsImg() {
    if (this.focusedEditor) {
      return this.focusedEditor.existingContentToLinkIsImg();
    }

    return false;
  }

  insertImage(image) {
    if (this.focusedEditor) {
      var _this$controller4;

      this.focusedEditor.insertImage(image);
      (_this$controller4 = this.controller(this.focusedEditor.id)) === null || _this$controller4 === void 0 ? void 0 : _this$controller4.hideTray();
    } else {
      console.warn('clicked sidebar image without a focused editor');
    }
  }

  insertImagePlaceholder(fileMetaProps) {
    if (this.focusedEditor) {
      // don't insert a placeholder if the user has selected content
      if (!this.existingContentToLink()) {
        this.focusedEditor.insertImagePlaceholder(fileMetaProps);
      }
    } else {
      console.warn('clicked sidebar image without a focused editor');
    }
  }

  removePlaceholders(name) {
    if (this.focusedEditor) {
      this.focusedEditor.removePlaceholders(name);
    }
  }

  showError(err) {
    if (this.focusedEditor) {
      this.focusedEditor.addAlert({
        text: err.toString(),
        type: 'error'
      });
    }
  }

}