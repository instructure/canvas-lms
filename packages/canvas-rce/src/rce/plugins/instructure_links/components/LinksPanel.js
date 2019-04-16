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

import {bool, func, node, object, string} from "prop-types";

import React from "react";
import ToggleDetails from "@instructure/ui-toggle-details/lib/components/ToggleDetails";
import View from "@instructure/ui-layout/lib/components/View";
import LinkSet from "./LinkSet";
import NavigationPanel from "./NavigationPanel";
import LinkToNewPage from "./LinkToNewPage";
import formatMessage from "../../../../format-message";

function AccordionSection({
  collection,
  children,
  onChangeAccordion,
  selectedAccordionIndex,
  summary
}) {
  return (
    <View as="div" margin="xx-small none">
      <ToggleDetails
        variant="filled"
        summary={summary}
        expanded={selectedAccordionIndex === collection}
        onToggle={(e, expanded) => onChangeAccordion(expanded ? collection : "")}
      >
        <div style={{maxHeight: '20em', overflow: 'auto'}}>{children}</div>
      </ToggleDetails>
    </View>
  );
}

AccordionSection.propTypes = {
  collection: string.isRequired,
  children: node.isRequired,
  onChangeAccordion: func.isRequired,
  selectedAccordionIndex: string,
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
  contextId: string.isRequired,
  contextType: string.isRequired,
  collections: object.isRequired,
  collection: string.isRequired,
  renderNewPageLink: bool,
  suppressRenderEmpty: bool,
  fetchInitialPage: func,
  fetchNextPage: func,
  onLinkClick: func,
  newPageLinkExpanded: bool,
  toggleNewPageForm: func
};

CollectionPanel.defaultProps = {
  renderNewPageLink: false,
  suppressRenderEmpty: false
};

function LinksPanel(props) {
  const isCourse = props.contextType === "course";
  const isGroup = props.contextType === "group";

  let navigationSummary = ''
  let panelDescription = ''
  if(isCourse) {
    navigationSummary = formatMessage({
      default: "Course Navigation",
      description:
        "Title of Sidebar accordion tab containing links to course pages."
    })
    panelDescription = formatMessage("Link to other content in the course.")
  } else if (isGroup) {
    navigationSummary =formatMessage({
      default: "Group Navigation",
      description:
        "Title of Sidebar accordion tab containing links to group pages."
    })
    panelDescription = formatMessage("Link to other content in the group.")
  }

  return (
    <div>
      <p>
        {panelDescription}
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
  selectedAccordionIndex: string,
  onChangeAccordion: func,
  contextType: string.isRequired,
  contextId: string.isRequired,
  collections: object.isRequired,
  fetchInitialPage: func,
  fetchNextPage: func,
  onLinkClick: func,
  toggleNewPageForm: LinkToNewPage.propTypes.toggleNewPageForm,
  newPageLinkExpanded: bool,
  canCreatePages: bool
};

LinksPanel.defaultProps = {
  selectedAccordionIndex: ""
};

export default LinksPanel;
