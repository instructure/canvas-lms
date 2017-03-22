import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import TutorialTrayContent from './TutorialTrayContent'

const HomeTray = () => (
  <TutorialTrayContent
    name="Home"
    heading={I18n.t('Home')}
    subheading={I18n.t('This is your course landing page')}
    image="/images/tutorial-tray-images/publish.png"
  >
    <Typography as="p">
      {
        I18n.t(`When people visit your course, this is the first page they'll see.
          We've set your homepage to Modules, but you have the option to change it.`)
      }
    </Typography>
    <Typography as="p">
      {
        I18n.t(`You can publish your course from the home page whenever you’re ready
          to share it with students. Until your course is published, only instructors will be able to access it.`)
      }
    </Typography>
  </TutorialTrayContent>
);

export default HomeTray
