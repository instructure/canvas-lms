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
import FlickrSearch from "../../../src/sidebar/components/FlickrSearch";
import sinon from "sinon";
import sd from "skin-deep";
import jsdom from "mocha-jsdom";

describe("FlickrSearch", () => {
  let noop = () => {};
  let fakeEvent = {
    preventDefault() {}
  };
  let flickr, defaultProps;

  jsdom();

  beforeEach(() => {
    flickr = {
      formExpanded: true,
      searching: false,
      searchResults: []
    };

    defaultProps = {
      flickr: flickr,
      flickrSearch: noop,
      toggleFlickrForm: noop,
      onImageEmbed: noop
    };
  });

  afterEach(() => {
    // skin deep sets up a global
    // when you "fillField" for document,
    // which then breaks jsdom tests
    global.document = undefined;
  });

  describe("form rendering", () => {
    it("renders form if expanded", () => {
      flickr.formExpanded = true;
      let flickrComp = sd.shallowRender(<FlickrSearch {...defaultProps} />);
      let instance = flickrComp.getMountedInstance();
      let searchForm = sd.shallowRender(instance.renderForm());
      assert.ok(searchForm.subTree("form"));
    });

    it("is null if not expanded", () => {
      flickr.formExpanded = false;
      let flickrComp = sd.shallowRender(<FlickrSearch {...defaultProps} />);
      let instance = flickrComp.getMountedInstance();
      assert.equal(null, instance.renderForm());
    });

    it("uses aria-expanded to communicate collapsed state", () => {
      flickr.formExpanded = true;
      let flickrComp = sd.shallowRender(<FlickrSearch {...defaultProps} />);
      let button = flickrComp.subTreeLike("Button", { "aria-expanded": true });
      assert.ok(button);

      flickr.formExpanded = false;
      flickrComp = sd.shallowRender(<FlickrSearch {...defaultProps} />);
      button = flickrComp.subTreeLike("Button", { "aria-expanded": false });
      assert.ok(button);
    });

    it("fires the handler when you click the expand link", () => {
      flickr.formExpanded = false;
      let clicked = false;
      let toggleForm = () => {
        clicked = true;
      };
      let flickrComp = sd.shallowRender(
        <FlickrSearch
          flickr={flickr}
          flickrSearch={noop}
          toggleFlickrForm={toggleForm}
          onImageEmbed={noop}
        />
      );
      let vdom = flickrComp.getRenderOutput();
      vdom.props.children[0].props.onClick(fakeEvent);
      assert.ok(clicked);
    });
  });

  describe("search form use", () => {
    beforeEach(() => {
      flickr.formExpanded = true;
    });

    it("passes search term to search handler", () => {
      const spy = sinon.spy();
      const instance = sd
        .shallowRender(<FlickrSearch flickr={flickr} flickrSearch={spy} />)
        .getMountedInstance();
      const value = "chess";
      instance.updateSearchTerm({ target: { value } });
      instance.handleSubmit({ preventDefault() {} });
      sinon.assert.calledWith(spy, value);
    });

    it("does not pass null/empty search term to search handler", () => {
      let searchStub = sinon.stub();
      let instance = sd
        .shallowRender(
          <FlickrSearch
            flickr={flickr}
            flickrSearch={searchStub}
            toggleFlickrForm={noop}
            onImageEmbed={noop}
          />
        )
        .getMountedInstance();
      let value = "";
      instance.handleSubmit(fakeEvent); // search with null state object
      instance.updateSearchTerm({ target: { value } });
      instance.handleSubmit(fakeEvent); // search with blank text
      value = " ";
      instance.updateSearchTerm({ target: { value } });
      instance.handleSubmit(fakeEvent); // search with text that will be trimmed
      assert.ok(searchStub.neverCalledWith()); // test to show that none of those searches above actually called flickr
    });

    it("has no button if already searching", () => {
      flickr.searching = true;
      let flickrComp = sd.shallowRender(
        <FlickrSearch
          flickr={flickr}
          flickrSearch={noop}
          toggleFlickrForm={noop}
          onImageEmbed={noop}
        />
      );
      let instance = flickrComp.getMountedInstance();
      let searchForm = sd.shallowRender(instance.renderForm());
      assert.ok(!searchForm.subTree("#flickr-search-submit-btn"));
    });

    describe("with search results", () => {
      beforeEach(() => {
        flickr.searchResults = [
          { id: "1", href: "asdf.jpg", title: "asdf" },
          { id: "2", href: "fdas.jpg", title: "fdas" }
        ];
      });

      it("renders results", () => {
        let flickrComp = sd.shallowRender(
          <FlickrSearch
            flickr={flickr}
            flickrSearch={noop}
            toggleFlickrForm={noop}
            onImageEmbed={noop}
          />
        );
        let instance = flickrComp.getMountedInstance();
        let searchForm = sd.shallowRender(instance.renderForm());
        assert.ok(searchForm.subTreeLike("img", { alt: "asdf" }));
        assert.ok(searchForm.subTreeLike("img", { alt: "fdas" }));
      });

      it("adds a flickr thumbnail signal to href", () => {
        let flickrComp = sd.shallowRender(
          <FlickrSearch
            flickr={flickr}
            flickrSearch={noop}
            toggleFlickrForm={noop}
            onImageEmbed={noop}
          />
        );
        let instance = flickrComp.getMountedInstance();
        let searchForm = sd.shallowRender(instance.renderForm());
        let flickrResult1 = searchForm.subTreeLike("img", {
          src: "asdf_s.jpg"
        });
        assert.ok(flickrResult1);
      });

      it("handles a result click through callback", () => {
        let clickSpy = sinon.spy();
        let flickrComp = sd.shallowRender(
          <FlickrSearch
            flickr={flickr}
            flickrSearch={noop}
            toggleFlickrForm={noop}
            onImageEmbed={clickSpy}
          />
        );
        let instance = flickrComp.getMountedInstance();
        let searchForm = sd.shallowRender(instance.renderForm());
        let vdom = searchForm.getRenderOutput();
        vdom.props.children[1].props.children[0].props.onClick(fakeEvent); // click on a result
        assert.ok(clickSpy.called);
      });

      it("uses the correct image URL on the drag event", () => {
        let flickrComp = sd.shallowRender(<FlickrSearch {...defaultProps} />);
        let instance = flickrComp.getMountedInstance();
        let imageData = null;
        let dndEvent = {
          dataTransfer: {
            getData: () => {
              return `<img src="http://canvas.docker/images/thumbnails/show/55/BI8re30hgKqgYgEYMf8AwTr7wvFjqFSdSZvNU96R">`;
            },
            setData: (type, data) => {
              imageData = data;
            }
          }
        };
        let result = { href: "http://a.better.url", title: "image title" };
        instance.flickrResultDrag(dndEvent, result);
        assert.equal(
          imageData,
          `<img alt="image title" src="http://a.better.url"/>`
        );
      });
    });
  });
});
