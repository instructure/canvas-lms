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

import React, { Component, PropTypes } from "react";
import TabList from "@instructure/ui-core/lib/components/TabList";
import TabPanel from "@instructure/ui-core/lib/components/TabList/TabPanel";
import LinkSet from "./LinkSet";
import NavigationPanel from "./NavigationPanel";
import LinkToNewPage from "./LinkToNewPage";
import formatMessage from "../../format-message";

class LinksPanel extends Component {
  isCourse() {
    return this.props.contextType === "course";
  }

  isGroup() {
    return this.props.contextType === "group";
  }

  linkToText() {
    switch (this.props.contextType) {
      case "course":
        return formatMessage("Link to other content in the course.");
      case "group":
        return formatMessage("Link to other content in the group.");
      default:
        // user
        return "";
    }
  }

  instructions() {
    return (
      <p>
        {this.linkToText()}{" "}
        {formatMessage("Click any page to insert a link to that page.")}
      </p>
    );
  }

  tabPanel(key, title, component) {
    return (
      <TabPanel maxHeight="20em" key={key} title={title}>
        {component}
      </TabPanel>
    );
  }

  boundFetchInitialPage(collection) {
    if (this.props.fetchInitialPage) {
      return () => this.props.fetchInitialPage(collection);
    } else {
      return null;
    }
  }

  boundFetchNextPage(collection) {
    if (this.props.fetchNextPage) {
      return () => this.props.fetchNextPage(collection);
    } else {
      return null;
    }
  }

  newPageLink() {
    return (
      <LinkToNewPage
        onLinkClick={this.props.onLinkClick}
        toggleNewPageForm={this.props.toggleNewPageForm}
        newPageLinkExpanded={this.props.newPageLinkExpanded}
        contextId={this.props.contextId}
        contextType={this.props.contextType}
      />
    );
  }

  collectionPanel(
    collection,
    title,
    renderNewPageLink = false,
    suppressRenderEmpty = false
  ) {
    return this.tabPanel(
      collection,
      title,
      <div>
        <LinkSet
          fetchInitialPage={this.boundFetchInitialPage(collection)}
          fetchNextPage={this.boundFetchNextPage(collection)}
          collection={this.props.collections[collection]}
          onLinkClick={this.props.onLinkClick}
          suppressRenderEmpty={suppressRenderEmpty}
        />
        {renderNewPageLink && this.newPageLink()}
      </div>
    );
  }

  wikiPagesPanel() {
    const showCreatePageLink = this.props.canCreatePages !== false;
    const suppressRenderEmpty = showCreatePageLink;
    return this.collectionPanel(
      "wikiPages",
      formatMessage({
        default: "Pages",
        description:
          "Title of Sidebar accordion tab containing links to wiki pages."
      }),
      showCreatePageLink,
      suppressRenderEmpty
    );
  }

  assignmentsPanel() {
    return this.collectionPanel(
      "assignments",
      formatMessage({
        default: "Assignments",
        description:
          "Title of Sidebar accordion tab containing links to assignments."
      })
    );
  }

  quizzesPanel() {
    return this.collectionPanel(
      "quizzes",
      formatMessage({
        default: "Quizzes",
        description:
          "Title of Sidebar accordion tab containing links to quizzes."
      })
    );
  }

  announcementsPanel() {
    return this.collectionPanel(
      "announcements",
      formatMessage({
        default: "Announcements",
        description:
          "Title of Sidebar accordion tab containing links to announcements."
      })
    );
  }

  discussionsPanel() {
    return this.collectionPanel(
      "discussions",
      formatMessage({
        default: "Discussions",
        description:
          "Title of Sidebar accordion tab containing links to discussions."
      })
    );
  }

  modulesPanel() {
    return this.collectionPanel(
      "modules",
      formatMessage({
        default: "Modules",
        description:
          "Title of Sidebar accordion tab containing links to course modules."
      })
    );
  }

  navigationTitle() {
    if (this.isGroup()) {
      return formatMessage({
        default: "Group Navigation",
        description:
          "Title of Sidebar accordion tab containing links to group pages."
      });
    } else {
      // TODO what if contextType === 'user'?
      return formatMessage({
        default: "Course Navigation",
        description:
          "Title of Sidebar accordion tab containing links to course pages."
      });
    }
  }

  navigationPanel() {
    return this.tabPanel(
      "navigation",
      this.navigationTitle(),
      <NavigationPanel
        contextType={this.props.contextType}
        contextId={this.props.contextId}
        onLinkClick={this.props.onLinkClick}
      />
    );
  }

  tabPanels() {
    let tabPanels = [];
    if (this.isCourse() || this.isGroup()) {
      tabPanels.push(this.wikiPagesPanel());
      if (this.isCourse()) {
        tabPanels.push(this.assignmentsPanel());
        tabPanels.push(this.quizzesPanel());
      }
      tabPanels.push(this.announcementsPanel());
      tabPanels.push(this.discussionsPanel());
      if (this.isCourse()) {
        tabPanels.push(this.modulesPanel());
      }
    }
    tabPanels.push(this.navigationPanel());
    return tabPanels;
  }

  render() {
    return (
      <div>
        {this.instructions()}
        <TabList
          variant="accordion"
          defaultSelectedIndex={this.props.selectedIndex}
          onChange={this.props.onChange}
        >
          {this.tabPanels()}
        </TabList>
      </div>
    );
  }
}

LinksPanel.propTypes = {
  selectedIndex: PropTypes.number,
  onChange: PropTypes.func,
  contextType: PropTypes.string.isRequired,
  contextId: PropTypes.string.isRequired,
  collections: PropTypes.object.isRequired,
  fetchInitialPage: PropTypes.func,
  fetchNextPage: PropTypes.func,
  onLinkClick: PropTypes.func,
  toggleNewPageForm: LinkToNewPage.propTypes.toggleNewPageForm,
  newPageLinkExpanded: PropTypes.bool,
  canCreatePages: PropTypes.bool
};

LinksPanel.defaultProps = {
  selectedIndex: 0
};

export default LinksPanel;
