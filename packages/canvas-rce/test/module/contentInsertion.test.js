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

import assert from "assert";
import * as contentInsertion from "../../src/rce/contentInsertion";

describe("contentInsertion", () => {
  let editor, node;

  beforeEach(() => {
    node = {
      content: "",
      className: "",
      id: ""
    };

    editor = {
      content: "",
      classes: "",
      isHidden: () => {
        return false;
      },
      selection: {
        getNode: () => {
          return null;
        },
        getContent: () => {
          return "";
        },
        getEnd: () => {
          return node;
        },
        getRng: () => ({})
      },
      dom: {
        getParent: () => {
          return null;
        },
        decode: input => {
          return input;
        },
        $: () => {
          return {
            is: () => {
              return false;
            }
          };
        }
      },
      insertContent: content => {
        editor.content = editor.content + content;
      },
      iframeElement: {
        getBoundingClientRect: () => {
          return { left: 0, top: 0, bottom: 0, right: 0 };
        }
      }
    };
  });

  describe("insertLink", () => {
    let link;

    beforeEach(() => {
      link = {
        href: "/some/path",
        url: "/other/path",
        title: "Here Be Links",
        contents: "Click On Me"
      };
    });

    it("builds an anchor link with appropriate embed class", () => {
      link.embed = { type: "image" };
      contentInsertion.insertLink(editor, link);
      assert.equal(
        editor.content,
        '<a href="/some/path" title="Here Be Links" class="instructure_file_link instructure_image_thumbnail">Click On Me</a>'
      );
    });

    it("uses link data to build html", () => {
      link.embed = { type: "scribd" };
      contentInsertion.insertLink(editor, link);
      assert.equal(
        editor.content,
        '<a href="/some/path" title="Here Be Links" class="instructure_file_link instructure_scribd_file">Click On Me</a>'
      );
    });

    it("can use url if no href", () => {
      link.href = undefined;
      contentInsertion.insertLink(editor, link);
      assert.equal(
        editor.content,
        '<a href="/other/path" title="Here Be Links">Click On Me</a>'
      );
    });

    it("cleans a url with no protocol", () => {
      link.href = "www.google.com";
      contentInsertion.insertLink(editor, link);
      assert.equal(
        editor.content,
        '<a href="http://www.google.com" title="Here Be Links">Click On Me</a>'
      );
    });

    it("sets embed id with media entry id for videos", () => {
      link.embed = { type: "video", id: "0_22h0jy7g" };
      contentInsertion.insertLink(editor, link);
      assert.ok(editor.content.match(link.embed.id));
    });

    it("sets embed id with media entry id for audio", () => {
      link.embed = { type: "audio", id: "0_22h0jy7g" };
      contentInsertion.insertLink(editor, link);
      assert.ok(editor.content.match(link.embed.id));
    });
  });

  describe("insertContent", () => {
    it("accepts string content", () => {
      let content = "Some Chunk Of Content";
      contentInsertion.insertContent(editor, content);
      assert.equal(editor.content, "Some Chunk Of Content");
    });

    it("calls replaceTextareaSelection() when editor is hidden", () => {
      let content = "blah";
      let elem = { selectionStart: 0, selectionEnd: 3, value: "subcontent" };
      editor.isHidden = () => {
        return true;
      };
      editor.getElement = () => {
        return elem;
      };
      contentInsertion.insertContent(editor, content);
      assert.equal("blahcontent", elem.value);
    });
  });

  describe("insertImage", () => {
    let image;
    beforeEach(() => {
      image = {
        href: "/some/path",
        url: "/other/path",
        title: "Here Be Images"
      };
    });

    it("builds image html from image data", () => {
      contentInsertion.insertImage(editor, image);
      assert.equal(
        editor.content,
        '<img alt="Here Be Images" src="/some/path"/>'
      );
    });

    it("uses url if no href", () => {
      image.href = undefined;
      contentInsertion.insertImage(editor, image);
      assert.equal(
        editor.content,
        '<img alt="Here Be Images" src="/other/path"/>'
      );
    });

    it("builds linked image html from linked image data", () => {
      const containerElem = {
        nodeName: "A",
        getAttribute: () => {
          return "http://bogus.edu";
        }
      };
      let ed = Object.assign({}, editor);
      ed.insertContent = content => {
        ed.content = ed.content + content;
      };
      ed.selection.getNode = () => {
        return Object.assign({}, node, { nodeName: "IMG" });
      };
      ed.selection.getRng = () => ({
        startContainer: containerElem,
        endContainer: containerElem
      });

      contentInsertion.insertImage(ed, image);
      assert.equal(
        ed.content,
        '<a href="http://bogus.edu" data-mce-href="http://bogus.edu"><img alt="Here Be Images" src="/some/path"/></a>'
      );
    });
  });

  describe("existingContentToLink", () => {
    it("returns true if content selected", () => {
      editor.selection.getContent = () => {
        return "content";
      };
      assert.equal(true, contentInsertion.existingContentToLink(editor));
    });
    it("returns false if content not selected", () => {
      assert.equal(false, contentInsertion.existingContentToLink(editor));
    });
  });

  describe("existingContentToLinkIsImg", () => {
    it("returns false if no content selected", () => {
      assert.equal(false, contentInsertion.existingContentToLinkIsImg(editor));
    });
    it("returns false if selected content is not img", () => {
      editor.selection.getContent = () => {
        return "content";
      };
      assert.equal(false, contentInsertion.existingContentToLinkIsImg(editor));
    });
    it("returns true if selected content is img", () => {
      editor.selection.getContent = () => {
        return "content";
      };
      editor.dom.$ = () => {
        return {
          is: () => {
            return true;
          }
        };
      };
      assert.equal(true, contentInsertion.existingContentToLinkIsImg(editor));
    });
  });
});
