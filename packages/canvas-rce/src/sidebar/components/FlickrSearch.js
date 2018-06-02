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
import { renderImage as renderImageHtml } from "../../rce/contentRendering";
import dragHtml from "../dragHtml";
import ReactCSSTransitionGroup from "react-transition-group/CSSTransitionGroup";
import formatMessage from "../../format-message";
import Loading from "../../common/components/Loading";
import Button from "@instructure/ui-core/lib/components/Button";
import TextInput from "@instructure/ui-core/lib/components/TextInput";
import IconSearchSolid from "instructure-icons/lib/Solid/IconSearchSolid";
import IconMinimizeSolid from "instructure-icons/lib/Solid/IconMinimizeSolid";
import { StyleSheet, css } from "aphrodite";

class FlickrSearch extends Component {
  toggleForm(e) {
    e.preventDefault();
    this.props.toggleFlickrForm();
  }

  updateSearchTerm(e) {
    this.setState({ searchTerm: e.target.value });
  }

  handleSubmit(e) {
    e.preventDefault();
    if (this.state && this.state.searchTerm) {
      let term = this.state.searchTerm.trim();
      if (term.length > 0) {
        this.props.flickrSearch(term);
      }
    }
  }

  flickrResultClick(result) {
    this.props.onImageEmbed(result);
  }

  flickrResultDrag(ev, result) {
    dragHtml(ev, renderImageHtml(result));
  }

  renderFlickrResult(result) {
    return (
      <div
        key={"flickrPic_" + result.id}
        style={{ float: "left", padding: "2px", cursor: "pointer" }}
        onClick={() => this.flickrResultClick(result)}
      >
        <img
          onDragStart={ev => this.flickrResultDrag(ev, result)}
          src={result.href.replace(".jpg", "_s.jpg")}
          title={"embed " + result.title}
          alt={result.title}
        />
      </div>
    );
  }

  flickrSearchResults() {
    if (this.props.flickr.searching) {
      return <Loading />;
    } else if (this.props.flickr.searchResults) {
      return (
        <div style={{ maxHeight: "400px", overflowY: "auto" }}>
          {this.props.flickr.searchResults.map(this.renderFlickrResult, this)}
        </div>
      );
    }
  }

  renderSubmitButton() {
    if (this.props.flickr.searching) {
      return null;
    } else {
      return (
        <div className={css(styles.searchButtonContainer)}>
          <Button type="submit">{formatMessage("Search")}</Button>
        </div>
      );
    }
  }

  renderForm() {
    if (this.props.flickr.formExpanded) {
      return (
        <div>
          <form onSubmit={this.handleSubmit.bind(this)}>
            <div className={css(styles.titlebar)}>
              <span>Flickr: Creative Commons</span>
            </div>
            <TextInput
              label={formatMessage("Search")}
              placeholder={formatMessage("enter search terms")}
              onChange={this.updateSearchTerm.bind(this)}
            />
            {this.renderSubmitButton()}
          </form>
          {this.flickrSearchResults()}
        </div>
      );
    }
    return null;
  }

  flickrLink() {
    let message = this.props.flickr.formExpanded
      ? formatMessage("Close Flickr form")
      : formatMessage("Search Flickr");
    let icon = this.props.flickr.formExpanded ? (
      <IconMinimizeSolid className={css(styles.icon)} />
    ) : (
      <IconSearchSolid className={css(styles.icon)} />
    );
    return (
      <Button
        variant="link"
        aria-label={formatMessage("Search Flickr")}
        aria-expanded={this.props.flickr.formExpanded}
        onClick={this.toggleForm.bind(this)}
      >
        {icon}
        {" " + message}
      </Button>
    );
  }

  render() {
    return (
      <div className={css(styles.container)}>
        {this.flickrLink()}
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

FlickrSearch.propTypes = {
  flickrSearch: PropTypes.func.isRequired,
  toggleFlickrForm: PropTypes.func.isRequired,
  flickr: PropTypes.shape({
    searchResults: PropTypes.arrayOf(
      PropTypes.shape({
        id: PropTypes.string.isRequired,
        href: PropTypes.string.isRequired,
        title: PropTypes.string.isRequired
      })
    ).isRequired,
    searching: PropTypes.bool.isRequired,
    formExpanded: PropTypes.bool.isRequired
  }).isRequired,
  onImageEmbed: PropTypes.func.isRequired
};

const styles = StyleSheet.create({
  slideDownEnter: {
    maxHeight: 0,
    overflowY: "hidden"
  },
  slideDownEnterActive: {
    maxHeight: "1000px",
    transition: "max-height 500ms ease-in"
  },
  slideDownLeave: {
    maxHeight: "1000px",
    overflowY: "hidden"
  },
  slideDownLeaveActive: {
    maxHeight: 0,
    transition: "max-height 300ms ease-in"
  },
  container: {
    marginTop: "12px"
  },
  searchButtonContainer: {
    marginTop: "5px"
  },
  titlebar: {
    marginTop: "10px",
    fontFamily: '"Helvetica Neue",Helvetica,Arial,sans-serif',
    fontSize: "18px"
  },
  icon: {
    verticalAlign: "middle"
  }
});

export default FlickrSearch;
