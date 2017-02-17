define([
  'react', //for React.createElement outputted by jsx
  "i18n!account_course_user_search",
], function(React, I18n) {

  return function(collection, loadMore, noneFoundMessage) {
    if (!collection || collection.loading) {
      return (
        <div className="text-center pad-box">
          {I18n.t("Loading...")}
        </div>
      );
    } else if (collection.error) {
      return (
        <div className="text-center pad-box">
          <div className="alert alert-error">
            {I18n.t("There was an error with your query; please try a different search")}
          </div>
        </div>
      );
    } else if (!collection.data.length) {
      return (
        <div className="text-center pad-box">
          <div className="alert alert-info">
            {noneFoundMessage}
          </div>
        </div>
      );
    } else if (collection.next) {
      return (
        <div className="text-center pad-box">
          <button
            className="Button--link load_more"
            onClick={loadMore}
          >
            <i className="icon-refresh"/>
            {" "}
            {I18n.t("Load more...")}
          </button>
        </div>
      );
    }
  }
});

