import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import TutorialTrayContent from './TutorialTrayContent'

const FilesTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Files')}
    subheading={I18n.t('Images, Documents, and more')}
    image="/images/tutorial-tray-images/files.svg"
  >
    <Typography as="p">
      {
        I18n.t(`Upload course files, syllabi, readings, or other documents.
          Lock folders to keep them hidden from students. Add files to Modules,
          Assignments, Discussions, or Pages.`)
      }
    </Typography>
  </TutorialTrayContent>
);

export default FilesTray
