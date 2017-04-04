import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import Heading from 'instructure-ui/lib/components/Heading'

  const FilesTray = () => (
    <div>
      <Heading as="h2" level="h1" >{I18n.t('Files')}</Heading>
      <Typography size="large" as="p">
        {I18n.t('Images, Documents, and more')}
      </Typography>
      <Typography as="p">
        {
          I18n.t(`Upload course files, syllabi, readings, or other documents.
            Lock folders to keep them hidden from students. Add files to Modules,
            Assignments, Discussions, or Pages.`)
        }
      </Typography>
    </div>
  );

export default FilesTray
