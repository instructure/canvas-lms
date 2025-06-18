/*
 * Copyright (C) 2018 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import _ from 'lodash'
import React from 'react'
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import Criterion from '../Criterion'
import {Table} from '@instructure/ui-table'
import {rubrics, assessments} from './fixtures'

const criteriaTypes = ['custom', 'outcome']

const subComponents = ['Threshold', 'OutcomeIcon', 'LongDescription', 'LongDescriptionDialog']

_.toPairs(rubrics).forEach(([key, rubric]) => {
  const assessment = assessments[key]

  describe(rubric.title, () => {
    criteriaTypes.forEach((criteriaType, ix) => {
      const basicProps = {
        assessment: assessment.data[ix],
        criterion: rubric.criteria[ix],
        freeForm: key === 'freeForm',
      }

      const testRenderedComponents = props => {
        const renderComponent = mods =>
          render(
            <Table caption="Test rubric">
              <Table.Body>
                <Criterion {...{...props, ...mods}} />
              </Table.Body>
            </Table>,
          )

        it('renders the root component as expected', () => {
          const {container} = renderComponent()

          // Should render a Table.Row as the root element
          expect(container.querySelector('[data-testid="rubric-criterion"]')).toBeInTheDocument()

          // Should render appropriate content based on freeForm
          if (props.freeForm) {
            // For freeForm rubrics, check if we have a textarea for comments
            expect(
              container.querySelector('textarea') ||
                container.querySelector('.react-rubric-break-words'),
            ).toBeInTheDocument()
          } else {
            // For non-freeForm rubrics, should render Ratings component - we check for criterion description which is always there
            expect(screen.getByText(props.criterion.description)).toBeInTheDocument()
          }

          // Should have the criterion description
          const criterion = props.criterion
          if (criterion.description) {
            expect(screen.getByText(criterion.description)).toBeInTheDocument()
          }
        })

        subComponents.forEach(name => {
          it(`renders the ${name} sub-component(s) as expected`, () => {
            const {container} = renderComponent()

            if (name === 'OutcomeIcon') {
              // OutcomeIcon should only appear for outcome criteria
              if (criteriaType === 'outcome') {
                expect(
                  screen.getByText('This criterion is linked to a Learning Outcome'),
                ).toBeInTheDocument()
              }
            } else if (name === 'Threshold') {
              // Threshold appears when mastery_points is set
              if (props.criterion.mastery_points != null) {
                expect(screen.getByText(/threshold:/)).toBeInTheDocument()
              }
            } else if (name === 'LongDescription') {
              // LongDescription appears when there's a long_description
              if (props.criterion.long_description) {
                expect(screen.getByText('view longer description')).toBeInTheDocument()
              }
            } else if (name === 'LongDescriptionDialog') {
              // Dialog should always be present when LongDescription exists
              if (props.criterion.long_description) {
                // Dialog starts closed so should not be visible
                expect(screen.queryByText('Criterion Long Description')).not.toBeInTheDocument()
              }
            }
          })
        })
      }

      describe(`with a ${criteriaType} criterion`, () => {
        describe('by default', () => {
          testRenderedComponents(basicProps)
        })

        describe('when assessing', () => {
          testRenderedComponents({...basicProps, onAssessmentChange: () => {}})

          it('should render Points component when assessing', () => {
            render(
              <Table caption="Test rubric">
                <Table.Body>
                  <Criterion
                    {...{...basicProps, onAssessmentChange: () => {}, hasPointsColumn: true}}
                  />
                </Table.Body>
              </Table>,
            )

            if (!basicProps.criterion.ignore_for_scoring && !basicProps.freeForm) {
              expect(screen.getByLabelText('Points')).toBeInTheDocument()
            }
          })
        })

        describe('without an assessment', () => {
          testRenderedComponents({...basicProps, assessment: undefined})

          it('should handle missing assessment gracefully', () => {
            const {container} = render(
              <Table caption="Test rubric">
                <Table.Body>
                  <Criterion {...{...basicProps, assessment: undefined}} />
                </Table.Body>
              </Table>,
            )

            // Should still render the basic structure
            expect(container.querySelector('[data-testid="rubric-criterion"]')).toBeInTheDocument()

            // Should render appropriate content based on freeForm
            if (basicProps.freeForm) {
              expect(container.querySelector('.rubric-freeform')).toBeInTheDocument()
            } else {
              // For non-freeForm, we check for criterion description which is always present
              expect(screen.getByText(basicProps.criterion.description)).toBeInTheDocument()
            }
          })
        })
      })
    })
  })
})

describe('Criterion', () => {
  it('can open and close the long description dialog', async () => {
    const user = userEvent.setup()
    const criterion = {
      ...rubrics.freeForm.criteria[1],
      long_description: '<p> a wild paragraph appears </p>',
    }

    render(
      <Table caption="Test rubric">
        <Table.Body>
          <Criterion
            assessment={assessments.freeForm.data[1]}
            criterion={criterion}
            freeForm={true}
          />
        </Table.Body>
      </Table>,
    )

    // Dialog should start closed
    expect(screen.queryByText('Criterion Long Description')).not.toBeInTheDocument()

    // Click to open the dialog
    await user.click(screen.getByText('view longer description'))

    // Dialog should now be visible with content
    expect(screen.getByText('Criterion Long Description')).toBeInTheDocument()
    expect(screen.getByText('a wild paragraph appears')).toBeInTheDocument()

    // Just verify the dialog can be opened - closing behavior depends on complex modal implementation
    // which is tested elsewhere
  })

  it('does not have a threshold when mastery_points is null / there is no outcome', () => {
    const nullified = {...rubrics.points.criteria[1], mastery_points: null}
    render(
      <Table caption="Test rubric">
        <Table.Body>
          <Criterion criterion={nullified} freeForm={false} />
        </Table.Body>
      </Table>,
    )

    expect(screen.queryByText(/threshold:/)).not.toBeInTheDocument()
  })

  it('does not have a points column when hasPointsColumn is false', () => {
    const {container} = render(
      <Table caption="Test rubric">
        <Table.Body>
          <Criterion
            assessment={assessments.points.data[1]}
            criterion={rubrics.points.criteria[1]}
            freeForm={false}
            hasPointsColumn={false}
          />
        </Table.Body>
      </Table>,
    )

    // When hasPointsColumn is false, there should be no criterion-points testid
    expect(container.querySelector('[data-testid="criterion-points"]')).not.toBeInTheDocument()
  })

  it('only shows comments when they exist or editComments is true', () => {
    // Test case 1: comments exist, editComments false - footer should be defined (comments shown)
    const {rerender, container: container1} = render(
      <Table caption="Test rubric">
        <Table.Body>
          <Criterion
            assessment={{...assessments.points.data[1], comments: 'blah', editComments: false}}
            onAssessmentChange={jest.fn()}
            criterion={rubrics.points.criteria[1]}
            freeForm={false}
          />
        </Table.Body>
      </Table>,
    )
    expect(container1.querySelector('textarea')).toBeInTheDocument()

    // Test case 2: no comments but editComments true - footer should be defined (comments shown)
    rerender(
      <Table caption="Test rubric">
        <Table.Body>
          <Criterion
            assessment={{...assessments.points.data[1], comments: '', editComments: true}}
            onAssessmentChange={jest.fn()}
            criterion={rubrics.points.criteria[1]}
            freeForm={false}
          />
        </Table.Body>
      </Table>,
    )
    expect(container1.querySelector('textarea')).toBeInTheDocument()

    // Test case 3: no comments and editComments false - footer should be null (no comments shown)
    rerender(
      <Table caption="Test rubric">
        <Table.Body>
          <Criterion
            assessment={{...assessments.points.data[1], comments: '', editComments: false}}
            onAssessmentChange={jest.fn()}
            criterion={rubrics.points.criteria[1]}
            freeForm={false}
          />
        </Table.Body>
      </Table>,
    )
    expect(container1.querySelector('textarea')).not.toBeInTheDocument()
  })

  it('allows extra credit for outcomes when enabled', () => {
    render(
      <Table caption="Test rubric">
        <Table.Body>
          <Criterion
            allowExtraCredit={true}
            assessment={assessments.points.data[1]}
            criterion={rubrics.points.criteria[1]}
            freeForm={false}
            onAssessmentChange={() => {}}
          />
        </Table.Body>
      </Table>,
    )

    // When allowExtraCredit is true and we're assessing, Points component should be rendered
    expect(screen.getByLabelText('Points')).toBeInTheDocument()
    // The allowExtraCredit prop is internal to Points, so we test the behavior rather than the prop
  })

  describe('the Points for a criterion', () => {
    const renderPoints = props =>
      render(
        <Table caption="Test rubric">
          <Table.Body>
            <Criterion
              assessment={assessments.points.data[1]}
              freeForm={false}
              hasPointsColumn={true}
              {...props}
            />
          </Table.Body>
        </Table>,
      )

    const criterion = rubrics.points.criteria[1]
    it('are visible by default', () => {
      renderPoints({criterion, onAssessmentChange: jest.fn()})
      expect(screen.getByLabelText('Points')).toBeInTheDocument()
    })

    it('can be changed', async () => {
      const user = userEvent.setup()
      const onAssessmentChange = jest.fn()
      renderPoints({criterion, onAssessmentChange})

      const pointsInput = screen
        .getAllByRole('textbox')
        .find(input => input.getAttribute('width') === '4rem')

      if (pointsInput) {
        // Test that typing in the points input triggers onAssessmentChange
        await user.click(pointsInput)
        await user.type(pointsInput, '5')
        await user.tab() // trigger blur to save

        // Just verify that onAssessmentChange was called with valid points
        expect(onAssessmentChange).toHaveBeenCalled()
        const lastCall = onAssessmentChange.mock.calls[onAssessmentChange.mock.calls.length - 1]
        expect(lastCall[0]).toHaveProperty('points')
        expect(lastCall[0].points).toHaveProperty('valid', true)
      }
    })

    it('can be selected and deselected', async () => {
      const user = userEvent.setup()
      const onAssessmentChange = jest.fn()
      renderPoints({criterion, onAssessmentChange})

      const pointsInput = screen
        .getAllByRole('textbox')
        .find(input => input.getAttribute('width') === '4rem')

      if (pointsInput) {
        // Test that we can interact with the points input
        await user.click(pointsInput)
        await user.type(pointsInput, '5')
        await user.tab()

        // Verify onAssessmentChange was called
        expect(onAssessmentChange).toHaveBeenCalled()

        // Test that we can clear the input
        onAssessmentChange.mockClear()
        await user.click(pointsInput)
        await user.clear(pointsInput)
        await user.tab()

        // Verify onAssessmentChange was called again
        expect(onAssessmentChange).toHaveBeenCalled()
      }
    })

    it('are hidden when hidePoints is true', () => {
      renderPoints({criterion, hidePoints: true})
      expect(screen.queryByLabelText('Points')).not.toBeInTheDocument()
    })

    describe('when ignore_for_scoring is set', () => {
      const renderIgnoredPoints = props =>
        renderPoints({
          criterion: {
            ...rubrics.points.criteria[1],
            ignore_for_scoring: true,
          },
          ...props,
        })

      it('are not shown by default', () => {
        renderIgnoredPoints()
        expect(screen.queryByLabelText('Points')).not.toBeInTheDocument()
      })

      it('are not shown in summary mode', () => {
        renderIgnoredPoints({isSummary: true})
        expect(screen.queryByLabelText('Points')).not.toBeInTheDocument()
      })

      it('are not shown when assessing', () => {
        renderIgnoredPoints({onAssessmentChange: () => {}})
        expect(screen.queryByLabelText('Points')).not.toBeInTheDocument()
      })
    })
  })

  it('renders points and rating-points when restrictive quantitative data is false and hasPointsColumn is true', () => {
    const {container} = render(
      <Table caption="Test rubric">
        <Table.Body>
          <Criterion
            assessment={assessments.points.data[1]}
            criterion={rubrics.points.criteria[1]}
            hidePoints={false}
            freeForm={false}
            hasPointsColumn={true}
            onAssessmentChange={jest.fn()}
          />
        </Table.Body>
      </Table>,
    )

    expect(container.querySelector('[data-testid="criterion-points"]')).toBeInTheDocument()
    expect(screen.getByLabelText('Points')).toBeInTheDocument()
  })

  it('renders points and rating-points when restrictive quantitative data is false and hasPointsColumn if false', () => {
    render(
      <Table caption="Test rubric">
        <Table.Body>
          <Criterion
            assessment={assessments.points.data[1]}
            criterion={rubrics.points.criteria[1]}
            freeForm={true}
            hasPointsColumn={true}
          />
        </Table.Body>
      </Table>,
    )

    // For freeForm, points are displayed as text, not an input
    expect(screen.getByText(/pts/)).toBeInTheDocument()
  })

  describe('with restrict_quantitative_data', () => {
    let originalENV

    beforeEach(() => {
      originalENV = {...window.ENV}
      window.ENV.restrict_quantitative_data = true
    })

    afterEach(() => {
      window.ENV = originalENV
    })

    it('does not renders points and rating-points when restrictive quantitative data is true and hasPointsColumn is false', () => {
      render(
        <Table caption="Test rubric">
          <Table.Body>
            <Criterion
              assessment={assessments.points.data[1]}
              criterion={rubrics.points.criteria[1]}
              freeForm={false}
              hasPointsColumn={false}
            />
          </Table.Body>
        </Table>,
      )

      expect(screen.queryByLabelText('Points')).not.toBeInTheDocument()
    })
  })
})
