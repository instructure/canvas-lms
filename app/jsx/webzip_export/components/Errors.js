import React from 'react'
import I18n from 'i18n!webzip_exports'
  const Errors = (props) => {
    return (
      <p className="webzipexport__errors">
        {I18n.t('An error occurred. Please try again later.')}
      </p>
    )
  }

export default Errors
