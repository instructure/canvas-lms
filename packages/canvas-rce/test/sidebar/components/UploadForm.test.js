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
import React from "react";
import UploadForm from "../../../src/sidebar/components/UploadForm";
import sinon from "sinon";
import sd from "skin-deep";
import jsdom from "mocha-jsdom";

describe("UploadForm", () => {
  let noop = () => {};
  let fakeEvent = {
    preventDefault() {}
  };
  let upload, defaultProps;

  jsdom();

  beforeEach(() => {
    upload = {
      folders: {},
      uploading: false,
      formExpanded: true,
      rootFolderId: null,
      folderTree: {}
    };

    defaultProps = {
      messages: {
        expand: "Click Here",
        expandScreenreader: "Click There",
        collapse: "Nevermind",
        collapseScreenreader: "Nevermind FRD"
      },
      upload: upload,
      fetchFolders: noop,
      startImageUpload: noop,
      startUpload: noop,
      toggleUploadForm: noop,
      showAltTextForm: true
    };
  });

  describe("form rendering", () => {
    it("renders form if expanded", () => {
      upload.formExpanded = true;
      let uploadComp = sd.shallowRender(<UploadForm {...defaultProps} />);
      let instance = uploadComp.getMountedInstance();
      let uploadForm = sd.shallowRender(instance.renderForm());
      assert.ok(uploadForm.subTree("form"));
    });

    it("is blank if form collapsed", () => {
      upload.formExpanded = false;
      let uploadComp = sd.shallowRender(<UploadForm {...defaultProps} />);
      let instance = uploadComp.getMountedInstance();
      assert.equal(null, instance.renderForm());
    });

    it("uses aria-expanded to communicate collapsed state", () => {
      upload.formExpanded = true;
      let uploadComp = sd.shallowRender(<UploadForm {...defaultProps} />);
      let button = uploadComp.subTree("Button");
      assert.ok(/aria-expanded={true}/.test(button.toString()));

      upload.formExpanded = false;
      uploadComp = sd.shallowRender(<UploadForm {...defaultProps} />);
      button = uploadComp.subTree("Button");
      assert.ok(/aria-expanded={false}/.test(button.toString()));
    });

    it("calls for folders on mounting", () => {
      let foldersSpy = sinon.spy();
      sd.shallowRender(
        <UploadForm {...defaultProps} fetchFolders={foldersSpy} />
      );
      assert.ok(foldersSpy.called);
    });

    it("toggles form on expand link click", () => {
      let toggleSpy = sinon.spy();
      let uploadComp = sd.shallowRender(
        <UploadForm {...defaultProps} toggleUploadForm={toggleSpy} />
      );
      let vdom = uploadComp.getRenderOutput();
      vdom.props.children[0].props.onClick(fakeEvent);
      assert.ok(toggleSpy.called);
    });

    it("renders an option per folder", () => {
      upload.formExpanded = true;
      upload.folders = {
        "1": { id: 1, name: "folder 1", parentId: null },
        "2": { id: 2, name: "folder 2", parentId: 1 },
        "3": { id: 3, name: "folder 3", parentId: 1 }
      };
      upload.rootFolderId = 1;
      upload.folderTree = { "1": [2, 3], "2": [], "3": [] };
      let uploadComp = sd.shallowRender(<UploadForm {...defaultProps} />);
      let instance = uploadComp.getMountedInstance();
      let uploadForm = sd.shallowRender(instance.renderForm());
      let options = uploadForm.subTree("Select").everySubTree("option");
      assert(options.length === 3);
    });

    it("renders nested folders as options correctly", () => {
      upload.formExpanded = true;
      upload.folders = {
        "1": { id: 1, name: "folder 1", parentId: null },
        "2": { id: 2, name: "folder 2", parentId: 1 },
        "3": { id: 3, name: "folder 3", parentId: 2 }
      };
      upload.rootFolderId = 1;
      upload.folderTree = { "1": [2], "2": [3], "3": [] };
      let uploadComp = sd.shallowRender(<UploadForm {...defaultProps} />);
      let instance = uploadComp.getMountedInstance();
      let uploadForm = sd.shallowRender(instance.renderForm());
      let options = uploadForm.subTree("Select").everySubTree("option");
      assert.equal(
        options[0].toString(),
        "<option value={1}>\n  folder 1\n</option>"
      );
      assert.equal(
        options[1].toString(),
        "<option value={2}>\n  \n  folder 2\n</option>"
      );
      assert.equal(
        options[2].toString(),
        "<option value={3}>\n    \n  folder 3\n</option>"
      );
    });

    it("renders even if folderTree is incomplete", () => {
      upload.formExpanded = true;
      upload.folders = {
        "2": { id: 2, name: "folder 2", parentId: 1 },
        "3": { id: 3, name: "folder 3", parentId: 2 }
      };
      upload.rootFolderId = 1;
      upload.folderTree = { "2": [3], "3": [] };
      let uploadComp = sd.shallowRender(<UploadForm {...defaultProps} />);
      let instance = uploadComp.getMountedInstance();
      let uploadForm = sd.shallowRender(instance.renderForm());
      assert.ok(uploadForm.subTree("form"));
    });

    it("renders usage rights form if required", () => {
      defaultProps.usageRightsRequired = true;
      const uploadForm = sd.shallowRender(<UploadForm {...defaultProps} />);
      const rightsForm = uploadForm.subTree("UsageRightsForm");
      assert(rightsForm);
    });

    it("does not render usage rights form is not required", () => {
      defaultProps.usageRightsRequired = false;
      const uploadForm = sd.shallowRender(<UploadForm {...defaultProps} />);
      const rightsForm = uploadForm.subTree("UsageRightsForm");
      assert(!rightsForm);
    });

    it("shows loading component if uploading is true", () => {
      upload.uploading = true;
      const tree = sd.shallowRender(<UploadForm {...defaultProps} />);
      assert(tree.subTree("Loading"));
    });
  });

  describe("form interaction", () => {
    let upload, fileChangeEvent, emptyFileChangeEvent, mountedInstance;
    beforeEach(() => {
      upload = {
        uploads: [],
        folders: { "2": { id: 2, name: "Test Folder", parentId: null } },
        uploading: false,
        formExpanded: true
      };

      fileChangeEvent = {
        target: {
          files: [
            {
              name: "testfile",
              size: "24800",
              type: "jpeg"
            }
          ]
        }
      };

      emptyFileChangeEvent = {
        target: {
          files: []
        }
      };
      mountedInstance = sd
        .shallowRender(<UploadForm {...defaultProps} upload={upload} />)
        .getMountedInstance();
    });

    it("uses the first folder if none is selected", () => {
      mountedInstance.handleFileChange(fileChangeEvent);
      assert.equal(mountedInstance.state.file.parentFolderId, "2");
    });

    it("disables the upload button on initial display", () => {
      const vdom = sd
        .shallowRender(mountedInstance.renderForm())
        .subTree("Button")
        .getRenderOutput();
      assert.equal(vdom.props.disabled, true); // button should be disabled
    });

    it("disables the upload button with only a file selected", () => {
      mountedInstance.handleFileChange(fileChangeEvent); // add a file to the form
      const vdom = sd
        .shallowRender(mountedInstance.renderForm())
        .subTree("Button")
        .getRenderOutput();
      assert.equal(vdom.props.disabled, true); // button should be disabled
    });

    it("disables the upload button with only alt text resolved", () => {
      mountedInstance.setAltResolved(true); // resolve alt text
      const vdom = sd
        .shallowRender(mountedInstance.renderForm())
        .subTree("Button")
        .getRenderOutput();
      assert.equal(vdom.props.disabled, true); // button should be disabled
    });

    it("enables the upload button once you choose a file and resolve alt text", () => {
      mountedInstance.handleFileChange(fileChangeEvent); // add a file to the form
      mountedInstance.setAltResolved(true); // resolve alt text
      const vdom = sd
        .shallowRender(mountedInstance.renderForm())
        .subTree("Button")
        .getRenderOutput();
      assert.equal(vdom.props.disabled, false); // button should be enabled now
    });

    it("disables the upload button when canceling file choice", () => {
      mountedInstance.handleFileChange(fileChangeEvent); //add a file to the form
      mountedInstance.setAltResolved(true);
      let vdom = sd
        .shallowRender(mountedInstance.renderForm())
        .subTree("Button")
        .getRenderOutput();
      assert.equal(vdom.props.disabled, false); // button should be enabled
      mountedInstance.handleFileChange(emptyFileChangeEvent); //cancel/remove file from the form
      vdom = sd
        .shallowRender(mountedInstance.renderForm())
        .subTree("Button")
        .getRenderOutput();
      assert.equal(vdom.props.disabled, true); // button should be disabled
    });

    it("disables the upload button when alt text resolution is reversed", () => {
      mountedInstance.handleFileChange(fileChangeEvent); //add a file to the form
      mountedInstance.setAltResolved(true);
      let vdom = sd
        .shallowRender(mountedInstance.renderForm())
        .subTree("Button")
        .getRenderOutput();
      assert.equal(vdom.props.disabled, false); // button should be enabled
      mountedInstance.setAltResolved(false);
      vdom = sd
        .shallowRender(mountedInstance.renderForm())
        .subTree("Button")
        .getRenderOutput();
      assert.equal(vdom.props.disabled, true); // button should be disabled
    });

    it("disables the upload button when form is collapsed", () => {
      mountedInstance.handleFileChange(fileChangeEvent); // add a file to the form
      mountedInstance.setAltResolved(true);
      let vdom = sd
        .shallowRender(mountedInstance.renderForm())
        .subTree("Button")
        .getRenderOutput();
      assert.equal(vdom.props.disabled, false); // button should be enabled
      mountedInstance.showForm({ preventDefault: () => {} });
      vdom = sd
        .shallowRender(mountedInstance.renderForm())
        .subTree("Button")
        .getRenderOutput();
      assert.equal(vdom.props.disabled, true); // button should be disabled
    });

    it("disables the upload button when FilesPanel and no file selected", () => {
      const instance = sd
        .shallowRender(
          <UploadForm
            {...defaultProps}
            upload={upload}
            showAltTextForm={false}
          />
        )
        .getMountedInstance();
      const vdom = sd
        .shallowRender(instance.renderForm())
        .subTree("Button")
        .getRenderOutput();
      assert.equal(vdom.props.disabled, true);
    });

    it("enables the upload button when FilesPanel and file is selected", () => {
      const instance = sd
        .shallowRender(
          <UploadForm
            {...defaultProps}
            upload={upload}
            showAltTextForm={false}
          />
        )
        .getMountedInstance();
      instance.handleFileChange(fileChangeEvent);
      const vdom = sd
        .shallowRender(instance.renderForm())
        .subTree("Button")
        .getRenderOutput();
      assert.equal(vdom.props.disabled, false);
    });

    it("disables the upload button when FilesPanel and file is canceled", () => {
      const instance = sd
        .shallowRender(
          <UploadForm
            {...defaultProps}
            upload={upload}
            showAltTextForm={false}
          />
        )
        .getMountedInstance();
      instance.handleFileChange(fileChangeEvent);
      let vdom = sd
        .shallowRender(instance.renderForm())
        .subTree("Button")
        .getRenderOutput();
      assert.equal(vdom.props.disabled, false);
      instance.handleFileChange(emptyFileChangeEvent);
      vdom = sd
        .shallowRender(instance.renderForm())
        .subTree("Button")
        .getRenderOutput();
      assert.equal(vdom.props.disabled, true);
    });
  });

  describe("handleUpload()", () => {
    it("gets value from usage rights form if it is rendered", () => {
      const startUpload = sinon.spy();
      const usageRights = { usageRight: "foo" };
      const instance = new UploadForm({ startUpload });
      instance._usageRights = { value: () => usageRights }; // fake ref
      instance.handleUpload({ preventDefault: () => {} });
      sinon.assert.calledWithMatch(startUpload, { usageRights });
    });
  });

  describe("parentFolderId", () => {
    it("returns parentFolderId from file state if exists", () => {
      const parentFolderId = 47;
      const obj = { state: { file: { parentFolderId } } };
      assert.equal(
        UploadForm.prototype.parentFolderId.call(obj),
        parentFolderId
      );
    });

    it("returns first folder if not in file state", () => {
      const obj = {
        state: { file: {} },
        props: { upload: { folders: { foo: { id: 74 } } } }
      };
      assert.equal(UploadForm.prototype.parentFolderId.call(obj), 74);
    });

    it("returns null if there are no upload folders", () => {
      const obj = {
        state: { file: {} },
        props: { upload: { folders: {} } }
      };
      assert.equal(UploadForm.prototype.parentFolderId.call(obj), null);
    });
  });

  describe("handleFolderChange", () => {
    let ev, form, value;

    beforeEach(() => {
      value = 123;
      ev = {
        preventDefault: sinon.spy(),
        target: { value }
      };
      form = new UploadForm({});
      sinon.stub(form, "setState");
      form.handleFolderChange(ev);
    });

    it("prevents default on event", () => {
      sinon.assert.called(ev.preventDefault);
    });

    it("sets parentFolderId in file state from event targets value", () => {
      sinon.assert.calledWithMatch(form.setState, {
        file: sinon.match({ parentFolderId: value })
      });
    });
  });

  describe("handleFileClick", () => {
    it("emptys the file state except for parentFolderId", () => {
      const folderId = 123;
      const form = new UploadForm({
        upload: { folders: { folder: { id: folderId } } }
      });
      const ev = { target: {} };
      sinon.stub(form, "setState");
      form.handleFileClick(ev);
      sinon.assert.calledWithMatch(form.setState, {
        file: sinon.match({ parentFolderId: folderId })
      });
    });

    it("returns selected folder if selected", () => {
      const folderId = 123;
      const form = new UploadForm({});
      const ev = { target: {} };
      sinon.stub(form, "setState");
      form.state = { file: { parentFolderId: folderId } };
      form.handleFileClick(ev);
      sinon.assert.calledWithMatch(form.setState, {
        file: sinon.match({ parentFolderId: folderId })
      });
    });
  });
});
