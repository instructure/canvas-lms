require_relative '../../../app/models/assignment/filter_with_overrides_by_due_at'

describe Assignment::FilterWithOverridesByDueAt do
  describe '#filter_assignments' do
    subject(:assignments) do
      Assignment::FilterWithOverridesByDueAt.new(params).filter_assignments
    end

    let(:params) do
      {
        assignments: course.assignments,
        grading_period: period,
        differentiated_assignments: differentiated_assignments
      }
    end

    let!(:first_period) do
      group.grading_periods.create!(
        start_date: Time.zone.local(2015, 1, 1),
        end_date:   Time.zone.local(2015, 1, 31),
        title: 'first period'
      )
    end

    let!(:last_period) do
      group.grading_periods.create!(
        start_date: Time.zone.local(2015, 2, 1),
        end_date:   Time.zone.local(2015, 2, 28),
        title: 'last period'
      )
    end

    let(:group) { course.grading_period_groups.create! }
    let(:date_inside_first_range) { Time.zone.local(2015, 1, 15) }
    let(:date_inside_last_range) { Time.zone.local(2015, 2, 15) }
    let(:date_outside_range) { Time.zone.local(2999, 12, 31) }

    let(:course) { account.courses.create! }
    let(:account) { Account.create! }

    let(:assignment_graph_builder) do
      -> (assignment_property:, override_property:, period:) do
        date_inside_range = date_range_selector.call(period)

        assignment = assignment_builder.call(
          assignment_property,
          date_inside_range
        )

        assignment = override_builder.call(
          assignment,
          override_property,
          date_inside_range
        )

        assignment
      end
    end

    let(:date_range_selector) do
      -> (period) do
        if period.last?
          date_inside_last_range
        else
          date_inside_first_range
        end
      end
    end

    let(:assignment_builder) do
      -> (assignment_property, date_inside_range) do
        case assignment_property
        when :in
          course.assignments.create!(
            due_at: date_inside_range,
            workflow_state: 'active'
          )
        when nil
          course.assignments.create!(
            due_at: nil,
            workflow_state: 'active'
          )
        when :out
          course.assignments.create!(
            due_at: date_outside_range,
            workflow_state: 'active'
          )
        else
          raise AssignmentCaseNotFound
        end
      end
    end

    let(:override_builder) do
      -> (assignment, override_property, date_inside_range) do
        case override_property
        when :in
          assignment.assignment_overrides.build do |override|
            override.due_at = date_inside_range
            override.workflow_state = 'active'
            override.title = 'override inside range'
          end.save!
          assignment
        when nil
          assignment.assignment_overrides.build do |override|
            override.due_at = nil
            override.workflow_state = 'active'
            override.title = 'override with nil due_at'
          end.save!
          assignment
        when :none
          assignment
        when :out
          assignment.assignment_overrides.build do |override|
            override.due_at = date_outside_range
            override.workflow_state = 'active'
            override.title = 'override with nil due_at'
          end.save!
          assignment
        else
          raise OverrideCaseNotFound
        end
      end
    end

    let(:builder_params) do
      {
        assignment_property: assignment_property,
        override_property:   override_property,
        period:              period
      }
    end

    context 'differentiated assignments is false' do
      # differentiated assignments implies :none for override_property
      let(:differentiated_assignments) { false }
      let(:override_property) { :none }

      context 'not the last grading period' do
        let(:period) { first_period }

        context 'given an assignment with no due at' do
          let(:assignment_property) { nil }
          it 'does not select assignments' do
            assignment_graph_builder.call(builder_params)
            expect(assignments).to be_empty
          end
        end

        context 'given an assignment with a due at in range' do
          let(:assignment_property) { :in }
          it 'selects the assignment' do
            assignment = assignment_graph_builder.call(builder_params)
            expect(assignments).to eql [assignment]
          end
        end

        context 'given an assignment with a due at outside the range' do
          let(:assignment_property) { :out }
          it 'does not select the assignment' do
            assignment_graph_builder.call(builder_params)
            expect(assignments).to be_empty
          end
        end
      end

      context 'last grading period' do
        let(:period) { last_period }

        context 'given an assignment with no due at' do
          let(:assignment_property) { nil }
          it 'selects the assignment' do
            assignment_with_nil_due_at = assignment_graph_builder
              .call(builder_params)
            expect(assignments).to eql [assignment_with_nil_due_at]
          end
        end

        context 'given an assignment with a due at in range' do
          let(:assignment_property) { :in }
          it 'selects the assignment' do
            assignment_in_range = assignment_graph_builder
              .call(builder_params)
            expect(assignments).to eql [assignment_in_range]
          end
        end

        context 'given an assignment with a due at outside the range' do
          let(:assignment_property) { :out }
          it 'selects the assignment' do
            assignment_graph_builder.call(builder_params)
            expect(assignments).to eql []
          end
        end
      end
    end

    context 'differentiated assignments is true' do
      let(:differentiated_assignments) { true }

      context 'not the last grading period' do
        let(:period) { first_period }

        context 'given an assignment with no due at' do
          let(:assignment_property) { nil }

          context 'given an override with no due at' do
            let(:override_property) { nil }
            it 'does not select assignment' do
              assignment_graph_builder.call(builder_params)
              expect(assignments).to eql []
            end
          end

          context 'given an override in range' do
            let(:override_property) { :in }
            it 'selects the assignment' do
              assignment_with_no_due_at_and_an_override_in_range =
                assignment_graph_builder.call(builder_params)
              expect(assignments)
                .to eql [assignment_with_no_due_at_and_an_override_in_range]
            end
          end

          context 'given an override outside the range' do
            let(:override_property) { :out }
            it 'does not select the assignment' do
              assignment_graph_builder.call(builder_params)
              expect(assignments).to eql []
            end
          end
        end

        context 'given an assignment in range' do
          let(:assignment_property) { :in }
          context 'given an override with no due at' do
            let(:override_property) { nil }
            it 'selects the assignment' do
              assignment_in_range = assignment_graph_builder
                .call(builder_params)
              expect(assignments).to eql [assignment_in_range]
            end
          end

          context 'given an override in range' do
            let(:override_property) { :in }
            it 'selects the assignment' do
              assignment_in_range_with_an_override_in_range =
                assignment_graph_builder.call(builder_params)
              expect(assignments)
                .to eql [assignment_in_range_with_an_override_in_range]
            end
          end

          context 'given an override outside the range' do
            let(:override_property) { :out }
            it 'selects the assignment' do
              assignment_in_range_and_override_outside_range =
                assignment_graph_builder.call(builder_params)
              expect(assignments)
                .to eql [assignment_in_range_and_override_outside_range]
            end
          end
        end

        context 'given an assignment outside the range' do
          let(:assignment_property) { :out }

          context 'given an override with no due at' do
            let(:override_property) { nil }
            it 'does not select assignment' do
              assignment_graph_builder.call(builder_params)
              expect(assignments).to eql []
            end
          end

          context 'given an override in the range' do
            let(:override_property) { :in }
            it 'selects the assignment' do
              assignment_with_override_in_range =
                assignment_graph_builder.call(builder_params)
              expect(assignments)
                .to eql [assignment_with_override_in_range]
            end
          end

          context 'given an override outside the range' do
            let(:override_property) { :out }
            it 'does not select the assignment' do
              assignment_graph_builder.call(builder_params)
              expect(assignments).to be_empty
            end
          end
        end
      end

      context 'when the grading period is the last in the group' do
        let(:period) { last_period }

        context 'given an assignment with no due at' do
          let(:assignment_property) { nil }

          context 'given an override with no due at' do
            let(:override_property) { nil }
            it 'selects the assignment' do
              assignment_with_override_and_no_due_ats =
                assignment_graph_builder.call(builder_params)
              expect(assignments)
                .to eql [assignment_with_override_and_no_due_ats]
            end
          end

          context 'given an override in range' do
            let(:override_property) { :in }
            it 'selects the assignment' do
              assignment_with_no_due_at_and_override_in_range =
                assignment_graph_builder.call(builder_params)
              expect(assignments)
                .to eql [assignment_with_no_due_at_and_override_in_range]
            end
          end

          context 'given an override outside the range' do
            let(:override_property) { :out }
            it 'selects the assignment' do
              assignment_with_no_due_at_and_override_outside_range =
                assignment_graph_builder.call(builder_params)
              expect(assignments)
                .to eql [assignment_with_no_due_at_and_override_outside_range]
            end
          end

          context 'given no override' do
            let(:override_property) { :none }
            it 'selects the assignment' do
              assignment_with_no_due_at_and_no_override =
                assignment_graph_builder.call(builder_params)
              expect(assignments)
                .to eql [assignment_with_no_due_at_and_no_override]
            end
          end
        end

        context 'given an assignment in the date range' do
          let(:assignment_property) { :in }

          context 'given an override with no due at' do
            let(:override_property) { nil }
            it 'selects the assignment' do
              assignment_in_date_range_and_override_with_no_due_at =
                assignment_graph_builder.call(builder_params)
              expect(assignments)
                .to eql [assignment_in_date_range_and_override_with_no_due_at]
            end
          end

          context 'given an override in range' do
            let(:override_property) { :in }
            it 'selects the assignment' do
              assignment_with_override_both_inside_range =
                assignment_graph_builder.call(builder_params)
              expect(assignments)
                .to eql [assignment_with_override_both_inside_range]
            end
          end

          context 'given an override outside the range' do
            let(:override_property) { :out }
            it 'selects the assignment' do
              assignment_inside_range_and_override_outside_range =
                assignment_graph_builder.call(builder_params)
              expect(assignments)
                .to eql [assignment_inside_range_and_override_outside_range]
            end
          end

          context 'given no override' do
            let(:override_property) { :in }
            it 'selects the assignment' do
              assignment_in_range_and_no_override =
                assignment_graph_builder.call(builder_params)
              expect(assignments)
                .to eql [assignment_in_range_and_no_override]
            end
          end
        end

        context 'given an assignment outside the date range' do
          let(:assignment_property) { :out }

          context 'given an override with no due at' do
            let(:override_property) { nil }
            it 'selects the assignment' do
              assignment_outside_date_range_and_override_with_no_due_at =
                assignment_graph_builder.call(builder_params)
              expect(assignments)
                .to eql [assignment_outside_date_range_and_override_with_no_due_at]
            end
          end

          context 'given no override' do
            let(:override_property) { :none }
            it 'selects the assignment' do
              assignment_graph_builder.call(builder_params)
              expect(assignments).to be_empty
            end
          end

          context 'given an override in range' do
            let(:override_property) { :in }
            it 'selects the assignment' do
              assignment_outside_and_override_inside_range =
                assignment_graph_builder.call(builder_params)
              expect(assignments)
                .to eql [assignment_outside_and_override_inside_range]
            end
          end

          context 'given an override outside the range' do
            let(:override_property) { :out }
            it 'does not select the assignment' do
              assignment_graph_builder.call(builder_params)
              expect(assignments).to be_empty
            end
          end
        end

      end
    end
  end
end
