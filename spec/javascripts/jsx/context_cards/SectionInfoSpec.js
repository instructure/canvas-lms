define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/context_cards/SectionInfo'
], (React, ReactDOM, TestUtils, SectionInfo) => {

  QUnit.module('StudentContextTray/SectionInfo', (hooks) => {
    let subject

    hooks.afterEach(() => {
      if (subject) {
        const componentNode = ReactDOM.findDOMNode(subject)
        if (componentNode) {
          ReactDOM.unmountComponentAtNode(componentNode.parentNode)
        }
      }
      subject = null
    })

    QUnit.module('sections', () => {
      test('should be empty array by default', () => {
        subject = TestUtils.renderIntoDocument(
          <SectionInfo />
        )
        ok(subject.sections.length == 0)
      })

      test('returns sections found in both course & user enrollments', () => {
        const includedSection = {
          id: 1, name: 'Section One'
        }
        const excludedSection = {
          id: 2, name: 'Section Two'
        }
        subject = TestUtils.renderIntoDocument(
          <SectionInfo
            course={{
              sections: [includedSection, excludedSection]
            }}
            user={{
              enrollments: [{
                course_section_id: includedSection.id
              }]
            }}
          />
        )
        const sectionIds = subject.sections.map((section) => { return section.id })
        ok(sectionIds.includes(includedSection.id))
        notOk(sectionIds.includes(excludedSection.id))
      })
    })
  })
})
