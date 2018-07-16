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

import PropTypes from "prop-types";

import React, { Component } from "react";
import ToggleDetails from "@instructure/ui-toggle-details/lib/components/ToggleDetails";
import View from "@instructure/ui-layout/lib/components/View";
import LinkSet from "./LinkSet";
import NavigationPanel from "./NavigationPanel";
import LinkToNewPage from "./LinkToNewPage";
import formatMessage from "../../format-message";

function AccordionSection({
  collection,
  children,
  onChange,
  selectedIndex,
  summary
}) {
  return (
    <View as="div" margin="xx-small none">
      <ToggleDetails
        variant="filled"
        summary={summary}
        expanded={selectedIndex === collection}
        onToggle={(e, expanded) => onChange(expanded ? collection : "")}
      >
        <div style={{maxHeight: '20em', overflow: 'auto'}}>{children}</div>
      </ToggleDetails>
    </View>
  );
}

AccordionSection.propTypes = {
  collection: PropTypes.string.isRequired,
  children: PropTypes.node.isRequired,
  selectedIndex: PropTypes.string,
  summary: ToggleDetails.propTypes.summary
};

function CollectionPanel(props) {
  return (
    <AccordionSection {...props}>
      <LinkSet
        fetchInitialPage={
          props.fetchInitialPage &&
          (() => props.fetchInitialPage(props.collection))
        }
        fetchNextPage={
          props.fetchNextPage && (() => props.fetchNextPage(props.collection))
        }
        collection={props.collections[props.collection]}
        onLinkClick={props.onLinkClick}
        suppressRenderEmpty={props.suppressRenderEmpty}
      />
      {props.renderNewPageLink && (
        <LinkToNewPage
          onLinkClick={props.onLinkClick}
          toggleNewPageForm={props.toggleNewPageForm}
          newPageLinkExpanded={props.newPageLinkExpanded}
          contextId={props.contextId}
          contextType={props.contextType}
        />
      )}
    </AccordionSection>
  );
}

CollectionPanel.propTypes = {
  collection: PropTypes.string.isRequired,
  renderNewPageLink: PropTypes.bool,
  suppressRenderEmpty: PropTypes.bool
};

CollectionPanel.defaultProps = {
  renderNewPageLink: false,
  suppressRenderEmpty: false
};

function LinksPanel(props) {
  const isCourse = props.contextType === "course";
  const isGroup = props.contextType === "group";

  const navigationSummary = isCourse
    ? formatMessage({
        default: "Course Navigation",
        description:
          "Title of Sidebar accordion tab containing links to course pages."
      })
    : isGroup
      ? formatMessage({
          default: "Group Navigation",
          description:
            "Title of Sidebar accordion tab containing links to group pages."
        })
      : "";

  return (
    <div>
      <p>
        {props.contextType === "course"
          ? formatMessage("Link to other content in the course.")
          : props.contextType === "group"
            ? formatMessage("Link to other content in the group.")
            : ""}
        {formatMessage("Click any page to insert a link to that page.")}
      </p>
      <div>
        {(isCourse || isGroup) && (
          <CollectionPanel
            {...props}
            collection="wikiPages"
            summary={formatMessage({
              default: "Pages",
              description:
                "Title of Sidebar accordion tab containing links to wiki pages."
            })}
            renderNewPageLink={props.canCreatePages !== false}
            suppressRenderEmpty={props.canCreatePages !== false}
          />
        )}
        {isCourse && (
          <CollectionPanel
            {...props}
            collection="assignments"
            summary={formatMessage({
              default: "Assignments",
              description:
                "Title of Sidebar accordion tab containing links to assignments."
            })}
          />
        )}
        {isCourse && (
          <CollectionPanel
            {...props}
            collection="quizzes"
            summary={formatMessage({
              default: "Quizzes",
              description:
                "Title of Sidebar accordion tab containing links to quizzes."
            })}
          />
        )}
        {(isCourse || isGroup) && (
          <CollectionPanel
            {...props}
            collection="announcements"
            summary={formatMessage({
              default: "Announcements",
              description:
                "Title of Sidebar accordion tab containing links to announcements."
            })}
          />
        )}
        {(isCourse || isGroup) && (
          <CollectionPanel
            {...props}
            collection="discussions"
            summary={formatMessage({
              default: "Discussions",
              description:
                "Title of Sidebar accordion tab containing links to discussions."
            })}
          />
        )}
        {isCourse && (
          <CollectionPanel
            {...props}
            collection="modules"
            summary={formatMessage({
              default: "Modules",
              description:
                "Title of Sidebar accordion tab containing links to course modules."
            })}
          />
        )}
        <AccordionSection
          {...props}
          collection="navigation"
          summary={navigationSummary}
        >
          <NavigationPanel
            contextType={props.contextType}
            contextId={props.contextId}
            onLinkClick={props.onLinkClick}
          />
        </AccordionSection>
      </div>
    </div>
  );
}

LinksPanel.propTypes = {
  selectedIndex: PropTypes.string,
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
  selectedIndex: ""
};

export default LinksPanel;
