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

import sinon from "sinon";
import sidebarHandlers from "../../../src/sidebar/containers/sidebarHandlers";

import * as ui from "../../../src/sidebar/actions/ui";
import * as data from "../../../src/sidebar/actions/data";
import * as images from "../../../src/sidebar/actions/images";
import * as upload from "../../../src/sidebar/actions/upload";
import * as flickr from "../../../src/sidebar/actions/flickr";
import * as files from "../../../src/sidebar/actions/files";

describe("sidebarHandlers", () => {
  let handlers, dispatch;

  beforeEach(() => {
    dispatch = sinon.spy();
    handlers = sidebarHandlers(dispatch);
  });

  function testHandler(key, actions, method, ...args) {
    const ret = {};
    sinon.stub(actions, method).returns(ret);
    handlers[key](...args);
    sinon.assert.calledWithExactly(actions[method], ...args);
    sinon.assert.calledWithExactly(dispatch, ret);
    actions[method].restore();
  }

  it("ties ui change tab to store", () => {
    testHandler("onChangeTab", ui, "changeTab", 1);
  });

  it("ties ui change accordion to store", () => {
    testHandler("onChangeAccordion", ui, "changeAccordion", 1);
  });

  it("ties data fetch initial page to store", () => {
    testHandler("fetchInitialPage", data, "fetchInitialPage", "key");
  });

  it("ties data fetch next page to store", () => {
    testHandler("fetchNextPage", data, "fetchNextPage", "key");
  });

  it("ties files toggle folder to store", () => {
    testHandler("toggleFolder", files, "toggle", 1);
  });

  it("ties upload fetch folders to store", () => {
    testHandler("fetchFolders", upload, "fetchFolders");
  });

  it("ties images fetch images to store", () => {
    testHandler("fetchImages", images, "fetchImages", {});
  });

  it("ties upload preflight to store", () => {
    testHandler("startUpload", upload, "uploadPreflight", "images", {
      fi: "le"
    });
  });

  it("ties flickr search to store", () => {
    testHandler("flickrSearch", flickr, "searchFlickr", "cats");
  });

  it("ties toggle flickr form to store", () => {
    testHandler("toggleFlickrForm", flickr, "openOrCloseFlickrForm");
  });

  it("ties toggle upload form to store", () => {
    testHandler("toggleUploadForm", upload, "openOrCloseUploadForm");
  });
});
