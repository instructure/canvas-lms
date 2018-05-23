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
import jsdomify from "jsdomify";
import sinon from "sinon";
import Bridge from "../../src/bridge";
import ReactDOM from "react-dom";
import * as indicateModule from "../../src/common/indicate";
import * as contentInsertion from "../../src/rce/contentInsertion";
import RCEWrapper from "../../src/rce/RCEWrapper";

const textareaId = "myUniqId";

let React, fakeTinyMCE, execCommandSpy, editorCommandSpy, sd, editor;

// ====================
//        HELPERS
// ====================

function requireReactDeps() {
  React = require("react");
  sd = require("skin-deep");
}

function createBasicElement(opts) {
  let props = Object.assign({ textareaId, tinymce: fakeTinyMCE }, opts);
  return new RCEWrapper(props);
}

function createdMountedElement(additionalProps = {}) {
  let tree = sd.shallowRender(
    React.createElement(RCEWrapper, {
      defaultContent: "an example string",
      textareaId: textareaId,
      tinymce: fakeTinyMCE,
      ...additionalProps
    })
  );
  return tree;
}

describe("RCEWrapper", () => {
  // ====================
  //   SETUP & TEARDOWN
  // ====================

  beforeEach(() => {
    jsdomify.create(`
      <!DOCTYPE html><html><head></head><body>
      <div id="app">
        <textarea id="${textareaId}" />
      </div>
      </body></html>
    `);
    // must create react after jsdom setup
    requireReactDeps();
    editorCommandSpy = sinon.spy();
    editor = {
      content: "I got called with: ",
      id: textareaId,
      dom: {
        getParent: () => {
          return null;
        },
        decode: input => {
          return input;
        }
      },
      selection: {
        getEnd: () => {
          return 0;
        },
        getNode: () => {
          return null;
        },
        getContent: () => {
          return "";
        }
      },
      insertContent: contentToInsert => {
        editor.content = editor.content + contentToInsert;
      },
      getContainer: () => {
        return {};
      },
      setContent: sinon.spy(c => (editor.content = c)),
      getContent: () => editor.content,
      hidden: false,
      isHidden: () => {
        return editor.hidden;
      },
      execCommand: editorCommandSpy,
      serializer: { serialize: sinon.stub() }
    };

    fakeTinyMCE = {
      triggerSave: () => "called",
      execCommand: () => "command executed",
      editors: [editor]
    };

    execCommandSpy = sinon.spy(fakeTinyMCE, "execCommand");
    sinon.spy(editor, "insertContent");
  });

  afterEach(() => {
    jsdomify.destroy();
    execCommandSpy.reset();
    editorCommandSpy.reset();
  });

  // ====================
  //        TESTS
  // ====================

  describe("static methods", () => {
    describe("getByEditor", () => {
      it("gets instances by rendered tinymce object reference", () => {
        const editor = {};
        const wrapper = new RCEWrapper({});
        const options = wrapper.wrapOptions({});
        options.setup(editor);
        assert.equal(RCEWrapper.getByEditor(editor), wrapper);
      });
    });
  });

  describe("tinyMCE instance interactions", () => {
    let element;

    beforeEach(() => {
      element = createBasicElement();
    });

    it("calls toggle on its tinyMCE instance", () => {
      element.toggle();
      assert(
        execCommandSpy.withArgs("mceToggleEditor", false, textareaId).called
      );
    });

    it("syncs content during toggle if coming back from hidden instance", () => {
      element = createdMountedElement().getMountedInstance();
      editor.hidden = true;
      document.getElementById(textareaId).value = "Some Input HTML";
      element.toggle();
      assert.equal(element.getCode(), "Some Input HTML");
    });

    it("calls focus on its tinyMCE instance", () => {
      element = createBasicElement({ textareaId: "myOtherUniqId" });
      element.focus();
      assert(
        execCommandSpy.withArgs("mceFocus", false, "myOtherUniqId").called
      );
    });

    it("resets the doc of the editor on removal", () => {
      element.destroy();
      assert(editorCommandSpy.calledWith("mceNewDocument"));
    });

    it("calls handleUnmount when destroyed", () => {
      const handleUnmount = sinon.spy();
      element = createBasicElement({ handleUnmount });
      element.destroy();
      sinon.assert.called(handleUnmount);
    });

    it("doesnt reset the doc for other commands", () => {
      element.toggle();
      assert(!editorCommandSpy.calledWith("mceNewDocument"));
    });

    it("proxies hidden checks to editor", () => {
      assert.equal(element.isHidden(), false);
    });
  });

  describe("calling methods dynamically", () => {
    it("pipes arguments to specified method", () => {
      const element = createBasicElement();
      sinon.stub(element, "set_code");
      element.call("set_code", "new content");
      assert(element.set_code.calledWith("new content"));
    });

    it("handles 'exists?'", () => {
      const element = createBasicElement();
      sinon.stub(element, "set_code");
      assert(element.call("exists?"));
    });
  });

  describe("getting and setting content", () => {
    let instance;

    beforeEach(() => {
      instance = createdMountedElement().getMountedInstance();
      // no rce ref since it is a shallow render
      instance.refs = {};
      instance.refs.rce = { forceUpdate: () => "no op" };
      instance.indicator = () => {};
    });

    afterEach(() => {
      editor.content = "I got called with: ";
    });

    it("sets code properly", () => {
      const expected = "new content";
      instance.setCode(expected);
      sinon.assert.calledWith(editor.setContent, expected);
    });

    it("gets code properly", () => {
      assert.equal(editor.getContent(), instance.getCode());
    });

    it("inserts code properly", () => {
      const code = {};
      sinon.stub(contentInsertion, "insertContent");
      instance.insertCode(code);
      assert.ok(contentInsertion.insertContent.calledWith(editor, code));
      contentInsertion.insertContent.restore();
    });

    it("inserts links", () => {
      let link = {};
      sinon.stub(contentInsertion, "insertLink");
      instance.insertLink(link);
      assert.ok(contentInsertion.insertLink.calledWith(editor, link));
      contentInsertion.insertLink.restore();
    });

    describe("indicator", () => {
      it("does not indicate() if editor is hidden", () => {
        let indicateDefaultStub = sinon.stub(indicateModule, "default");
        editor.hidden = true;
        sinon.stub(instance, "mceInstance");
        instance.mceInstance.returns(editor);
        instance.indicateEditor(null);
        assert.ok(indicateDefaultStub.neverCalledWith());
        indicateModule.default.restore();
      });

      it("waits until images are loaded to indicate", () => {
        let image = { complete: false };
        sinon.spy(instance, "indicateEditor");
        sinon.stub(contentInsertion, "insertImage").returns(image);
        instance.insertImage(image);
        assert.ok(instance.indicateEditor.notCalled);
        image.onload();
        assert.ok(instance.indicateEditor.called);
        contentInsertion.insertImage.restore();
      });
    });

    describe("broken images", () => {
      it("calls checkImageLoadError when complete", () => {
        let image = { complete: true };
        sinon.spy(instance, "checkImageLoadError");
        sinon.stub(contentInsertion, "insertImage").returns(image);
        instance.insertImage(image);
        assert.ok(instance.checkImageLoadError.called);
        instance.checkImageLoadError.restore();
        contentInsertion.insertImage.restore();
      });

      it("sets an onerror handler when not complete", () => {
        let image = { complete: false };
        sinon.spy(instance, "checkImageLoadError");
        sinon.stub(contentInsertion, "insertImage").returns(image);
        instance.insertImage(image);
        assert.ok(typeof image.onerror === "function");
        image.onerror();
        assert.ok(instance.checkImageLoadError.called);
        instance.checkImageLoadError.restore();
        contentInsertion.insertImage.restore();
      });

      describe("checkImageLoadError", () => {
        it("does not error if called without an element", () => {
          instance.checkImageLoadError();
        });

        it("does not error if called without a non-image element", () => {
          const div = { tagName: "DIV" };
          instance.checkImageLoadError(div);
        });

        it("checks onload for images not done loading", done => {
          const fakeElement = {
            complete: false,
            tagName: "IMG",
            naturalWidth: 0,
            style: {}
          };
          instance.checkImageLoadError(fakeElement);
          assert.equal(Object.keys(fakeElement.style).length, 0);
          fakeElement.complete = true;
          fakeElement.onload();
          setTimeout(() => {
            try {
              assert.ok(fakeElement.style.border === "1px solid #000");
              assert.ok(fakeElement.style.padding === "2px");
              done();
            } catch (err) {
              done(err);
            }
          }, 0);
        });

        it("sets the proper styles when the naturalWidth is 0", done => {
          const fakeElement = {
            complete: true,
            tagName: "IMG",
            naturalWidth: 0,
            style: {}
          };
          instance.checkImageLoadError(fakeElement);
          setTimeout(() => {
            try {
              assert.ok(fakeElement.style.border === "1px solid #000");
              assert.ok(fakeElement.style.padding === "2px");
              done();
            } catch (err) {
              done(err);
            }
          }, 0);
        });
      });
    });
  });

  describe("alias functions", () => {
    it("sets aliases properly", () => {
      const element = createBasicElement();
      const aliases = {
        set_code: "setCode",
        get_code: "getCode",
        insert_code: "insertCode"
      };
      Object.keys(aliases).forEach(k => {
        const v = aliases[k];
        assert(element[v], element[k]);
      });
    });
  });

  describe("is_dirty()", () => {
    it("is true if not hidden and defaultContent is not equal to getConent()", () => {
      const c = createBasicElement({ defaultContent: "different" });
      editor.hidden = false;
      assert(c.is_dirty());
    });

    it("is false if not hidden and defaultContent is equal to getConent()", () => {
      editor.serializer.serialize.returns(editor.content);
      const c = createBasicElement();
      editor.hidden = false;
      assert(!c.is_dirty());
    });

    it("is true if hidden and defaultContent is not equal to textarea value", () => {
      const c = createBasicElement({ textareaId, defaultContent: "default" });
      editor.hidden = true;
      document.getElementById(textareaId).value = "different";
      assert(c.is_dirty());
    });

    it("is false if hidden and defaultContent is equal to textarea value", () => {
      const defaultContent = "default content";
      editor.serializer.serialize.returns(defaultContent);
      const c = createBasicElement({ textareaId, defaultContent });
      editor.hidden = true;
      document.getElementById(textareaId).value = defaultContent;
      assert(!c.is_dirty());
    });

    it("compares content with defaultContent serialized by editor serializer", () => {
      editor.serializer.serialize.returns(editor.content);
      const defaultContent = "foo";
      const c = createBasicElement({ defaultContent });
      editor.hidden = false;
      assert(!c.is_dirty());
      sinon.assert.calledWithExactly(
        editor.serializer.serialize,
        sinon.match(
          el => el.innerHTML === defaultContent,
          `div with "${defaultContent}" as inner html`
        ),
        { getInner: true }
      );
    });
  });

  describe("onFocus", () => {
    beforeEach(() => {
      sinon.stub(Bridge, "focusEditor");
    });

    afterEach(() => {
      Bridge.focusEditor.restore();
    });

    it("calls Bridge.focusEditor with editor", () => {
      const editor = createBasicElement();
      editor.onFocus();
      sinon.assert.calledWith(Bridge.focusEditor, editor);
    });

    it("calls props.onFocus with editor if exists", () => {
      const editor = createBasicElement({ onFocus: sinon.spy() });
      editor.onFocus();
      sinon.assert.calledWith(editor.props.onFocus, editor);
    });
  });

  describe("onRemove", () => {
    let domNode;

    beforeEach(() => {
      domNode = {};
      sinon.stub(ReactDOM, "unmountComponentAtNode");
      sinon.stub(ReactDOM, "findDOMNode").returns(domNode);
      sinon.stub(Bridge, "detachEditor");
    });

    afterEach(() => {
      ReactDOM.unmountComponentAtNode.restore();
      ReactDOM.findDOMNode.restore();
      Bridge.detachEditor.restore();
    });

    it("calls Bridge.detachEditor with editor", () => {
      const editor = createBasicElement();
      editor.onRemove();
      sinon.assert.calledWith(Bridge.detachEditor, editor);
    });

    it("calls props.onRemove with editor if exists", () => {
      const editor = createBasicElement({ onRemove: sinon.spy() });
      editor.onRemove();
      sinon.assert.calledWith(editor.props.onRemove, editor);
    });

    it("unmounts the rce component", () => {
      const editor = createBasicElement();
      editor.refs = { rce: {} };
      editor.onRemove();
      sinon.assert.calledWith(ReactDOM.findDOMNode, editor.refs.rce);
      sinon.assert.calledWith(ReactDOM.unmountComponentAtNode, domNode);
    });
  });

  describe("setup option", () => {
    let editorOptions;

    beforeEach(() => {
      editorOptions = {
        setup: sinon.spy(),
        other: {}
      };
    });

    it("registers editor to allow getting wrapper by editor", () => {
      const editor = {};
      const tree = createdMountedElement({ editorOptions });
      tree.subTree("TinyMCE").props.config.setup(editor);
      assert.equal(RCEWrapper.getByEditor(editor), tree.getMountedInstance());
    });

    it("it calls original setup from editorOptions", () => {
      const editor = {};
      const spy = editorOptions.setup;
      const tree = createdMountedElement({ editorOptions });
      tree.subTree("TinyMCE").props.config.setup(editor);
      sinon.assert.calledWithExactly(spy, editor);
    });

    it("does not throw if options does not have a setup function", () => {
      delete editorOptions.setup;
      createdMountedElement({ editorOptions });
    });

    it("passes other options through unchanged", () => {
      const tree = createdMountedElement({ editorOptions });
      tree.subTree("TinyMCE").props.config.setup(editor);
      assert.equal(
        tree.subTree("TinyMCE").props.config.other,
        editorOptions.other
      );
    });
  });

  describe("textarea", () => {
    let instance, elem;

    function stubEventListeners(elem) {
      sinon.stub(elem, "addEventListener");
      sinon.stub(elem, "removeEventListener");
    }

    beforeEach(() => {
      instance = createBasicElement();
      elem = document.getElementById(textareaId);
      stubEventListeners(elem);
    });

    describe("lifecycle", () => {
      it("adds change listener after mount", () => {
        instance.componentDidMount();
        sinon.assert.calledWith(
          elem.addEventListener,
          "change",
          instance.handleTextareaChange
        );
      });

      it("updates change listener if textarea changes", () => {
        instance.componentDidMount();
        const oldElem = elem;
        const appElem = document.getElementById("app");
        appElem.removeChild(elem);
        elem = document.createElement("textarea");
        elem.id = textareaId;
        stubEventListeners(elem);
        appElem.appendChild(elem);
        instance.componentDidUpdate();
        sinon.assert.calledWith(
          elem.addEventListener,
          "change",
          instance.handleTextareaChange
        );
        sinon.assert.calledWith(
          oldElem.removeEventListener,
          "change",
          instance.handleTextareaChange
        );
      });

      it("removes change listener before component unmounts", () => {
        instance.componentDidMount();
        instance.componentWillUnmount();
        sinon.assert.calledWith(
          elem.removeEventListener,
          "change",
          instance.handleTextareaChange
        );
      });
    });

    describe("handleTextareaChange", () => {
      it("updates the editor content if editor is hidden", () => {
        const value = "foo";
        elem.value = value;
        editor.hidden = true;
        instance.handleTextareaChange();
        sinon.assert.calledWith(editor.setContent, value);
      });

      it("does not update the editor if editor is not hidden", () => {
        editor.hidden = false;
        instance.handleTextareaChange();
        sinon.assert.notCalled(editor.setContent);
      });
    });
  });
});
