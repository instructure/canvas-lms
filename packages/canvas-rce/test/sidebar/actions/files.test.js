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
import * as actions from "../../../src/sidebar/actions/files";
import sinon from "sinon";
import { spiedStore } from "./utils";

describe("Sidebar files actions", () => {
  describe("createToggle()", () => {
    it("has the right type", () => {
      const action = actions.createToggle();
      assert(action.type === actions.TOGGLE);
    });

    it("includes id from first argument", () => {
      const id = 47;
      assert(actions.createToggle(id).id === id);
    });
  });

  describe("createAddFile()", () => {
    const file = {
      id: 47,
      name: "foo",
      url: "bar.com",
      type: "text/plain",
      embed: { type: "scribd" }
    };

    it("has the right type", () => {
      const action = actions.createAddFile({});
      assert(action.type === actions.ADD_FILE);
    });

    it("includes properties from file object", () => {
      const action = actions.createAddFile(file);
      assert(action.id === file.id);
      assert(action.name === file.name);
      assert(action.url === file.url);
      assert(action.fileType === file.type);
    });

    it("passes the embed through to the action", () => {
      const action = actions.createAddFile(file);
      assert.equal(action.embed, file.embed);
    });
  });

  describe("createRequestFiles()", () => {
    it("has the right type", () => {
      const action = actions.createRequestFiles();
      assert(action.type === actions.REQUEST_FILES);
    });

    it("includes id from first argument", () => {
      const id = 47;
      assert(actions.createRequestFiles(id).id === id);
    });
  });

  describe("createReceiveFiles()", () => {
    it("has the right type", () => {
      const action = actions.createReceiveFiles(null, []);
      assert(action.type === actions.RECEIVE_FILES);
    });

    it("includes id from first argument", () => {
      const id = 47;
      const action = actions.createReceiveFiles(id, []);
      assert(action.id === id);
    });

    it("inclues a fileIds array plucked from the files array", () => {
      const files = [{ id: 1 }, { id: 2 }, { id: 3 }];
      const action = actions.createReceiveFiles(null, files);
      assert.deepStrictEqual(action.fileIds, [1, 2, 3]);
    });
  });

  describe("createAddFolder()", () => {
    it("has the right type", () => {
      const action = actions.createAddFolder({});
      assert(action.type === actions.ADD_FOLDER);
    });

    it("includes properties from folder object", () => {
      const folder = {
        id: 47,
        name: "foo",
        parentId: 42,
        filesUrl: "bar.com/files",
        foldersUrl: "bar.com/folders"
      };
      const action = actions.createAddFolder(folder);
      assert(action.id === folder.id);
      assert(action.name === folder.name);
      assert(action.filesUrl === folder.filesUrl);
      assert(action.foldersUrl === folder.foldersUrl);
      assert(action.parentId === folder.parentId);
    });
  });

  describe("createRequestSubfolders()", () => {
    it("has the right type", () => {
      const action = actions.createRequestSubfolders();
      assert(action.type === actions.REQUEST_SUBFOLDERS);
    });

    it("includes id from first argument", () => {
      const id = 47;
      assert(actions.createRequestSubfolders(id).id === id);
    });
  });

  describe("createReceiveSubfolders()", () => {
    it("has the right type", () => {
      const action = actions.createReceiveSubfolders(null, []);
      assert(action.type === actions.RECEIVE_SUBFOLDERS);
    });

    it("includes id from first argument", () => {
      const id = 47;
      const action = actions.createReceiveSubfolders(id, []);
      assert(action.id === id);
    });

    it("inclues a folderIds array plucked from the folders array", () => {
      const folders = [{ id: 1 }, { id: 2 }, { id: 3 }];
      const action = actions.createReceiveSubfolders(null, folders);
      assert.deepStrictEqual(action.folderIds, [1, 2, 3]);
    });
  });

  describe("createSetRoot()", () => {
    it("has the right type", () => {
      const action = actions.createSetRoot();
      assert(action.type === actions.SET_ROOT);
    });

    it("includes id from first argument", () => {
      const id = 47;
      assert(actions.createSetRoot(id).id === id);
    });
  });

  describe("async actions", () => {
    const id = 47;
    const noopPromise = new Promise(() => {});

    let source;
    let folders;
    let state;
    let store;

    beforeEach(() => {
      source = {
        fetchPage: sinon.stub().returns(noopPromise),
        fetchFiles: sinon.stub().returns(noopPromise)
      };
      folders = {
        [id]: {
          id,
          filesUrl: "filesUrl",
          foldersUrl: "foldersUrl"
        }
      };
      state = { source, folders };
      store = spiedStore(state);
    });

    describe("requestFiles()", () => {
      it("dispatches a REQUEST_FILES action", () => {
        store.dispatch(actions.requestFiles(id));
        sinon.assert.calledWithMatch(store.spy, {
          id,
          type: actions.REQUEST_FILES
        });
      });

      it("calls fetchFiles for source with filesUrl", () => {
        store.dispatch(actions.requestFiles(id));
        sinon.assert.calledWith(source.fetchFiles, folders[id].filesUrl);
      });

      it("calls fetchFiles for source with optional bookmark", () => {
        const bookmark = "bookmarkUrl";
        store.dispatch(actions.requestFiles(id, bookmark));
        sinon.assert.calledWith(source.fetchFiles, bookmark);
      });

      it("dispatches ADD_FILE for each file from fetchFiles", done => {
        const files = [{}, {}, {}];
        source.fetchFiles.returns(new Promise(r => r({ files })));
        store
          .dispatch(actions.requestFiles(id))
          .then(() => {
            const addFileCount = store.spy.args.filter(args => {
              return args[0].type === actions.ADD_FILE;
            }).length;
            assert(files.length === addFileCount);
            done();
          })
          .catch(done);
      });

      it("dispatches RECEIVE_FILES action", done => {
        const files = [{}, {}, {}];
        source.fetchFiles.returns(new Promise(r => r({ files })));
        store
          .dispatch(actions.requestFiles(id))
          .then(() => {
            sinon.assert.calledWithMatch(store.spy, {
              type: actions.RECEIVE_FILES,
              id
            });
            done();
          })
          .catch(done);
      });

      it("calls fetchFiles w/ bookmark if returnd by fetchFiles", done => {
        const files = [];
        const bookmark = "someurl";
        source.fetchFiles.onCall(0).returns(
          new Promise(resolve => {
            resolve({ files, bookmark });
          })
        );
        source.fetchFiles.onCall(1).returns(
          new Promise(resolve => {
            resolve({ files });
          })
        );
        store
          .dispatch(actions.requestFiles(id))
          .then(() => {
            sinon.assert.calledWith(source.fetchFiles, bookmark);
            done();
          })
          .catch(done);
      });
    });

    describe("requestSubfolders()", () => {
      it("dispatches a REQUEST_SUBFOLDERS action", () => {
        store.dispatch(actions.requestSubfolders(id));
        sinon.assert.calledWithMatch(store.spy, {
          id,
          type: actions.REQUEST_SUBFOLDERS
        });
      });

      it("calls fetchPage for source with foldersUrl", () => {
        store.dispatch(actions.requestSubfolders(id));
        sinon.assert.calledWith(source.fetchPage, folders[id].foldersUrl);
      });

      it("calls fetchPage for source with optional bookmark", () => {
        const bookmark = "bookmarkUrl";
        store.dispatch(actions.requestSubfolders(id, bookmark));
        sinon.assert.calledWith(source.fetchPage, bookmark);
      });

      it("dispatches ADD_FOLDER for each folder from fetchPage", done => {
        const folders = [{}, {}, {}];
        source.fetchPage.returns(new Promise(r => r({ folders })));
        store
          .dispatch(actions.requestSubfolders(id))
          .then(() => {
            const addFolderCount = store.spy.args.filter(args => {
              return args[0].type === actions.ADD_FOLDER;
            }).length;
            assert(folders.length === addFolderCount);
            done();
          })
          .catch(done);
      });

      it("dispatches RECEIVE_SUBFOLDERS action", done => {
        const folders = [{}, {}, {}];
        source.fetchPage.returns(new Promise(r => r({ folders })));
        store
          .dispatch(actions.requestSubfolders(id))
          .then(() => {
            sinon.assert.calledWithMatch(store.spy, {
              type: actions.RECEIVE_SUBFOLDERS,
              id
            });
            done();
          })
          .catch(done);
      });

      it("calls fetchPage w/ bookmark if returnd by fetchPage", done => {
        const folders = [];
        const bookmark = "someurl";
        source.fetchPage.onCall(0).returns(
          new Promise(resolve => {
            resolve({ folders, bookmark });
          })
        );
        source.fetchPage.onCall(1).returns(
          new Promise(resolve => {
            resolve({ folders });
          })
        );
        store
          .dispatch(actions.requestSubfolders(id))
          .then(() => {
            source.fetchPage.calledWith(bookmark);
            done();
          })
          .catch(done);
      });
    });

    describe("toggle()", () => {
      it("dispatches TOGGLE action", () => {
        store.dispatch(actions.toggle(id));
        store.spy.calledWithMatch({
          id,
          type: actions.TOGGLE
        });
      });

      it("requests subfolders/files if not requested and expanded", () => {
        folders[id].requested = false;
        folders[id].expanded = true;
        store.dispatch(actions.toggle(id));
        sinon.assert.calledWithMatch(store.spy, {
          id,
          type: actions.REQUEST_FILES
        });
        sinon.assert.calledWithMatch(store.spy, {
          id,
          type: actions.REQUEST_SUBFOLDERS
        });
      });

      it("does not request subfolders/files if already requested", () => {
        folders[id].requested = true;
        folders[id].expanded = true;
        store.dispatch(actions.toggle(id));
        sinon.assert.neverCalledWithMatch(store.spy, {
          id,
          type: actions.REQUEST_FILES
        });
        sinon.assert.neverCalledWithMatch(store.spy, {
          id,
          type: actions.REQUEST_FOLDERS
        });
      });
    });

    describe("init()", () => {
      beforeEach(() => {
        source.fetchRootFolder = sinon.stub().returns(noopPromise);
      });

      it("calls fetchRootFolder for source with state", () => {
        store.dispatch(actions.init);
        sinon.assert.calledWith(source.fetchRootFolder, state);
      });

      it("calls dispatches SET_ROOT", () => {
        const id = 47;
        const folders = [{ id }];
        source.fetchRootFolder.returns(new Promise(r => r({ folders })));
        return store.dispatch(actions.init).then(() => {
          sinon.assert.calledWithMatch(store.spy, {
            id,
            type: actions.SET_ROOT
          });
        });
      });

      it("dispatches ADD_FOLDER for root folder", () => {
        const id = 47;
        const folders = [{ id }];
        source.fetchRootFolder.returns(new Promise(r => r({ folders })));
        return store.dispatch(actions.init).then(() => {
          sinon.assert.calledWithMatch(store.spy, {
            id,
            type: actions.ADD_FOLDER
          });
        });
      });

      it("dispatches TOGGLE for root folder", () => {
        const id = 47;
        const folders = [{ id }];
        source.fetchRootFolder.returns(new Promise(r => r({ folders })));
        return store.dispatch(actions.init).then(() => {
          sinon.assert.calledWithMatch(store.spy, {
            id,
            type: actions.TOGGLE
          });
        });
      });
    });
  });
});
