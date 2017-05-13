import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Typography from 'instructure-ui/lib/components/Typography'
import TutorialTrayContent from './TutorialTrayContent'

const GradesTray = () => (
  <TutorialTrayContent
    heading={I18n.t('Grades')}
    subheading={I18n.t('Track individual student and class progress')}
    image="/images/tutorial-tray-images/grades.svg"
  >
    <Typography as="p">
      {
        I18n.t(`Input and distribute grades for students. Display grades as
          points, percentages, complete or incomplete, pass or fail, GPA scale,
          and letter grades. Group assignments for grade weighting.`)
      }
    </Typography>
  </TutorialTrayContent>
);

export default GradesTray
