define([
  'react',
  'i18n!webzip_exports',
], (React, I18n) => {
  const Errors = (props) => {
    return (
      <p className="webzipexport__errors">
        {I18n.t('An error occurred. Please try again later.')}
      </p>
    )
  }

  return Errors
})
