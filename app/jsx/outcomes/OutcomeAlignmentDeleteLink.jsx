/** @jsx React.DOM */

define([
  'react',
  'i18n!outcomes'
], (React, I18n) => {
  var OutcomeAlignmentDeleteLink = React.createClass({
    handleClick(e) {
      var $li = $(e.target).parents('li.alignment');

      e.preventDefault();
      $(e.target).confirmDelete({
        success: function(data) {
          $li.fadeOut('slow', function() {
            this.remove();
          });
        },
        url: this.props.url
      });
    },

    hasRubricAssociation() {
      return this.props.has_rubric_association;
    },

    render() {
      if (this.hasRubricAssociation()) {
        return (
          <span>
            <img src="/images/delete_circle_gray.png" title={I18n.t(
              "Can't delete alignments based on rubric associations.  To remove these associations you need to remove the row from the asset's rubric"
            )} />
          </span>
        );
      } else {
        return (
          <a className="delete_alignment_link no-hover"
            href="" onClick={this.handleClick}>
            <img src="/images/delete_circle.png" />
          </a>
        );
      }
    }
  });

  return OutcomeAlignmentDeleteLink;
});
