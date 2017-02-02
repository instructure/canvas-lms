import React from 'react'
import createStore from './createStore'

  var { string, shape } = React.PropTypes;

  var TermsStore = createStore({
    getUrl() {
      return `/api/v1/accounts/${this.context.accountId}/terms`;
    },

    jsonKey: "enrollment_terms"
  });

  TermsStore.PropType = shape({
    id: string.isRequired,
    name: string.isRequired
  });

export default TermsStore
