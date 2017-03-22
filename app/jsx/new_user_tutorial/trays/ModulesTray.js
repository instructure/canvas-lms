import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import TutorialTrayContent from './TutorialTrayContent'

const ModulesTray = () => (
  <TutorialTrayContent
    name="Modules"
    heading={I18n.t('Modules')}
    subheading={I18n.t('Organize your course content')}
    image="/images/tutorial-tray-images/module_tutorial.svg"
  >
    <Typography as="p">
      {
          I18n.t(`Organize and segment your course by topic, unit, chapter,
                  or week. Sequence select modules by defining criteria and
                  prerequisites.`)
        }
    </Typography>
  </TutorialTrayContent>
);

export default ModulesTray
