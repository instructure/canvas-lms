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

import "@instructure/ui-themes/lib/canvas";
import { renderIntoDiv, renderSidebarIntoDiv } from "../src/async";
import CanvasRce from "../src/rce/CanvasRce";
import * as fakeSource from "../src/sidebar/sources/fake";
import React, { Component } from "react";
import ReactDOM from "react-dom";
import { Button, Select, TextInput } from "@instructure/ui-core/lib/components";
import Url from "url";

function getProps(textareaId, language = "en") {
  return {
    language,
    editorOptions: () => {
      return {
        height: "250px",
        plugins:
          "instructure_equation, instructure_image, instructure_equella, link, textcolor, instructure_external_tools, instructure_record, instructure_links, table",
        // todo: add "instructure_embed" when the wiki sidebar work is done
        external_plugins: {},
        menubar: true,
        // todo: the toolbar building and automatic splitting functions should come into the service
        toolbar: [
          // basic buttons
          "bold,italic,underline,forecolor,backcolor,removeformat,alignleft,aligncenter,alignright,outdent,indent,superscript,subscript,bullist,numlist,fontsizeselect,formatselect",

          // plugin buttons ("instructure_links" will be changed to "link", but this is how
          //   it's currently sent over from canvas.  Once that's no longer true, the test
          //  page can just use "link" instead)
          "table, link, unlink, instructure_equation, instructure_image, instructure_equella, instructure_record"
        ]
      };
    },
    textareaClassName: "exampleClassOne exampleClassTwo",
    textareaId
  };
}

function renderDemos(
  host,
  jwt,
  language = "en",
  contextType = "course",
  contextId = 1
) {
  renderIntoDiv(
    document.getElementById("editor1"),
    getProps("textarea1", language)
  );
  renderIntoDiv(
    document.getElementById("editor2"),
    getProps("textarea2", language)
  );
  ReactDOM.render(
    <CanvasRce rceProps={getProps("textarea3")} />,
    document.getElementById("editor3")
  );

  const parsedUrl = Url.parse(window.location.href, true);
  if (parsedUrl.query.sidebar === "no") {
    return;
  }

  const sidebarEl = document.getElementById("sidebar");
  ReactDOM.render(<div />, sidebarEl);
  renderSidebarIntoDiv(sidebarEl, {
    source: jwt ? undefined : fakeSource,
    host,
    jwt,
    contextType,
    contextId,
    canUploadFiles: true
  });
}

class DemoOptions extends Component {
  constructor(props) {
    super(props);
    this.state = {
      expanded: false
    };
    this.inputs = {};
    this.handleChange = this.handleChange.bind(this);
    this.toggle = this.toggle.bind(this);
  }

  handleChange() {
    renderDemos(
      this.inputs.host.value,
      this.inputs.jwt.value,
      this.inputs.language.value,
      this.inputs.contextType.value,
      this.inputs.contextId.value
    );
  }

  componentDidMount() {
    this.handleChange();
  }

  toggle() {
    this.setState({ expanded: !this.state.expanded });
  }

  render() {
    return (
      <div>
        <Button size="small" onClick={this.toggle}>
          {this.state.expanded ? "Hide Options" : "Show Options"}
        </Button>
        <div style={{ display: this.state.expanded ? undefined : "none" }}>
          <Select
            ref={r => (this.inputs.language = r)}
            label="Language"
            defaultValue="en"
          >
            <option>ar</option>
            <option>da</option>
            <option>de</option>
            <option>en-AU</option>
            <option>en-GB</option>
            <option>en-GB-x-lbs</option>
            <option>en</option>
            <option>es</option>
            <option>fa</option>
            <option>fr</option>
            <option>he</option>
            <option>hy</option>
            <option>ja</option>
            <option>ko</option>
            <option>mi</option>
            <option>nb</option>
            <option>nl</option>
            <option>pl</option>
            <option>pt-BR</option>
            <option>pt</option>
            <option>ru</option>
            <option>sv</option>
            <option>tr</option>
            <option>zh-Hans</option>
            <option>zh-Hant</option>
          </Select>
          <TextInput
            ref={r => (this.inputs.host = r)}
            label="API Host"
            defaultValue="https://rich-content-iad.inscloudgate.net"
          />
          <TextInput ref={r => (this.inputs.jwt = r)} label="Canvas JWT" />
          <Select
            ref={r => (this.inputs.contextType = r)}
            label="Context Type"
            defaultValue="course"
          >
            <option>course</option>
            <option>group</option>
            <option>user</option>
          </Select>
          <TextInput
            ref={r => (this.inputs.contextId = r)}
            label="Context ID"
            defaultValue="1"
          />
          <Button onClick={this.handleChange}>Update</Button>
        </div>
      </div>
    );
  }
}

ReactDOM.render(<DemoOptions />, document.getElementById("options"));
