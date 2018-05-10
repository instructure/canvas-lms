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
import ReactCSSTransitionGroup from "react-transition-group/CSSTransitionGroup";
import formatMessage from "../../format-message";
import Button from "@instructure/ui-buttons/lib/components/Button";
import TextInput from "@instructure/ui-forms/lib/components/TextInput";
import IconAddSolid from "@instructure/ui-icons/lib/Solid/IconAdd";
import scroll from "../../common/scroll";
import { StyleSheet, css } from "aphrodite";

class LinkToNewPage extends Component {
  validScrollTarget(target, parents) {
    return (
      parents.scrolled < 1 && //only want to scroll 1 parent
      (target === window || // top window passes // as does scrollable items
        // the style check(s) is to determine if it's potentially scrollable
        (target.style && target.style.overflow === "auto"))
    );
  }

  componentDidUpdate() {
    if (this.props.newPageLinkExpanded && this.pageInput) {
      let formElem =
        this.pageInput.parentElement &&
        this.pageInput.parentElement.parentElement
          ? this.pageInput.parentElement.parentElement
          : null;
      this.pageInput.focus();
      if (formElem) {
        // second param is config param for 'scroll-into-view' module
        scroll.scrollIntoViewWDelay(formElem, {
          time: 100, // length of time for animating the scroll
          validTarget: this.validScrollTarget,
          align: { top: 0.75 }
        });
      }
    }
  }

  handleLinkClick = (e, link) => {
    if (this.props.onLinkClick) {
      e.preventDefault();
      this.props.onLinkClick(link);
    }
  };

  toggleForm(e) {
    e.preventDefault();
    this.props.toggleNewPageForm();
  }

  isGroup() {
    if (this.props.contextType === "group") {
      return true;
    }
    return false;
  }

  getContextHref() {
    let href = "/";
    if (this.isGroup()) {
      href += "groups/";
    } else {
      href += "courses/";
    }
    href += this.props.contextId + "/";
    href += "pages/";
    return href;
  }

  handleSubmit(e) {
    e.preventDefault();
    if (this.state && this.state.newPageTitle) {
      let newPageTitle = this.state.newPageTitle.trim();
      let newPageHref =
        this.getContextHref() +
        encodeURIComponent(newPageTitle) +
        "?titleize=0";
      this.handleLinkClick(e, { href: newPageHref, title: newPageTitle });
      this.props.toggleNewPageForm();
    }
  }

  updateNewPageTitle(e) {
    this.setState({ ...this.state, newPageTitle: e.target.value });
  }

  renderForm() {
    if (this.props.newPageLinkExpanded) {
      return (
        <form
          id="new_page_drop_down"
          style={{ margin: "5px" }}
          aria-expanded={this.props.newPageLinkExpanded}
          onSubmit={this.handleSubmit.bind(this)}
        >
          <TextInput
            id="new-page-name-input"
            label={formatMessage("What would you like to call the new page?")}
            onChange={this.updateNewPageTitle.bind(this)}
            ref={input => (this.pageInput = input ? input._input : null)}
            size="small"
          />
          <Button size="small" id="rcs-LinkToNewPage-submit" type="submit">
            {formatMessage("Insert Link")}
          </Button>
        </form>
      );
    }
    return null;
  }

  render() {
    return (
      <div className={css(styles.container)}>
        <Button
          size="small"
          id="rcs-LinkToNewPage-btn-link"
          type="button"
          variant="link"
          onClick={e => this.toggleForm(e)}
        >
          <IconAddSolid className={css(styles.icon)} />&nbsp;
          {formatMessage("Link to a New Page")}
        </Button>
        <ReactCSSTransitionGroup
          transitionName={{
            enter: css(styles.slideDownEnter),
            enterActive: css(
              styles.slideDownEnter,
              styles.slideDownEnterActive
            ),
            leave: css(styles.slideDownLeave),
            leaveActive: css(styles.slideDownLeave, styles.slideDownLeaveActive)
          }}
          transitionEnterTimeout={500}
          transitionLeaveTimeout={300}
        >
          {this.renderForm()}
        </ReactCSSTransitionGroup>
      </div>
    );
  }
}

LinkToNewPage.propTypes = {
  onLinkClick: PropTypes.func,
  toggleNewPageForm: PropTypes.func.isRequired,
  newPageLinkExpanded: PropTypes.bool,
  contextId: PropTypes.string.isRequired,
  contextType: PropTypes.string.isRequired
};

export const styles = StyleSheet.create({
  slideDownEnter: {
    maxHeight: 0,
    overflowY: "hidden"
  },
  slideDownEnterActive: {
    maxHeight: "500px",
    transition: "max-height 500ms ease-in"
  },
  slideDownLeave: {
    maxHeight: "500px",
    overflowY: "hidden"
  },
  slideDownLeaveActive: {
    maxHeight: 0,
    transition: "max-height 300ms ease-in"
  },
  container: {
    marginTop: "5px"
  },
  icon: {
    verticalAlign: "middle"
  }
});

export default LinkToNewPage;
