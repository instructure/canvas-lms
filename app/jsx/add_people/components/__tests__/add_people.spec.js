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

import { mount } from "enzyme";
import React from "react";
import AddPeople from "../add_people";

describe("Focus Handling", () => {
  it("sends focus to the modal close button when an api error occurs", () => {
    const props = {
      isOpen: true,
      courseParams: {
        roles: [],
        sections: []
      },
      apiState: {
        isPending: 0
      },
      inputParams: {
        nameList: ""
      },
      validateUsers() {},
      enrollUsers() {},
      reset() {}
    };

    const wrapper = mount(<AddPeople {...props} />);

    wrapper.setProps({
      apiState: {
        error: "Some random error"
      }
    });

    expect(document.activeElement.textContent).toEqual("Cancel");
  });

  it("sends focus to the modal close button when people validation issues happen", () => {
    const props = {
      isOpen: true,
      courseParams: {
        roles: [],
        sections: []
      },
      apiState: {
        isPending: 0
      },
      inputParams: {
        nameList: "",
        searchType: "unique_id",
        role: "student",
        section: "1"
      },
      userValidationResult: {
        missing: {
          "gotta have": "something missing"
        },
        duplicates: {}
      },
      validateUsers() {},
      enrollUsers() {},
      reset() {}
    };

    const wrapper = mount(<AddPeople {...props} />);

    wrapper.setState({
      currentPage: "peoplevalidationissues"
    });

    expect(document.activeElement.textContent).toEqual("Cancel");
  });
});
