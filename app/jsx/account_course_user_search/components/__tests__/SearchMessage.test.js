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

import React from "react";
import { mount } from "enzyme";
import SearchMessage from "../SearchMessage";

const getProps = () => ({
  collection: {
    data: [1, 2, 3],
    links: {
      current: {
        url: "abc",
        page: "5"
      },
      last: {
        url: "abc10",
        page: "10"
      }
    }
  },
  setPage: jest.fn(),
  noneFoundMessage: "None Found!",
  dataType: "Course"
});

let flashElements;
beforeEach(() => {
  flashElements = document.createElement("div");
  flashElements.setAttribute("id", "flash_screenreader_holder");
  flashElements.setAttribute("role", "alert");
  document.body.appendChild(flashElements);
});

afterEach(() => {
  document.body.removeChild(flashElements);
});

describe("Pagination Handling", () => {
  it("shows the loading spinner on the page that is becoming current", () => {
    const props = getProps();
    const wrapper = mount(<SearchMessage {...props} />);
    wrapper.setProps({}); // Make sure it triggers componentWillReceiveProps
    wrapper.instance().handleSetPage(6);
    const buttons = wrapper.find("PaginationButton").map(x => x.text());
    expect(buttons).toEqual(["1", "5", "Loading...", "7", "8", "9", "10"]);
  });
});

describe("Screenreader Alerting", () => {
  it("renders a screenreader only alert indicating when results are updated", () => {
    const props = getProps();
    props.collection.loading = true;
    const wrapper = mount(<SearchMessage {...props} />);
    const alert = wrapper.find("Alert");
    expect(alert.exists()).toBe(false);
  });
  it("renders a screenreader only alert when there are errors", () => {
    const props = getProps();
    props.collection.error = true;
    const wrapper = mount(<SearchMessage {...props} />);
    const alert = wrapper.find("Alert");
    expect(alert.exists()).toBe(true);
    expect(
      document.getElementById("flash_screenreader_holder").textContent
    ).toBe("There was an error with your query; please try a different search");
  });
  it("renders a screenreader only result when there are no additional pages of results", () => {
    const props = getProps();
    props.collection.links = undefined;
    const wrapper = mount(<SearchMessage {...props} />);
    const alert = wrapper.find("Alert");
    expect(alert.exists()).toBe(true);
    expect(
      document.getElementById("flash_screenreader_holder").textContent
    ).toBe("Course results updated.");
  });
  it("renders a screenreader only message when there are no results", () => {
    const props = getProps();
    props.collection.data = [];
    const wrapper = mount(<SearchMessage {...props} />);
    const alert = wrapper.find("Alert");
    expect(alert.exists()).toBe(true);
    expect(
      document.getElementById("flash_screenreader_holder").textContent
    ).toBe("None Found!");
  });

  it('renders the proper message when the dataType prop is "User"', () => {
    const props = getProps();
    props.dataType = "User";
    const wrapper = mount(<SearchMessage {...props} />);
    const alert = wrapper.find("Alert");
    expect(alert.exists()).toBe(true);
    expect(
      document.getElementById("flash_screenreader_holder").textContent
    ).toBe("User results updated.");
  });
});
