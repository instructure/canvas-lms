require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe "Enrollment::QueryBuilder" do
  describe "#conditions" do
    let(:conditions)     { Enrollment::QueryBuilder.new(state, options).conditions }
    let(:options)        { {} }
    let(:account_id)     { create_record(Account, name: "Account") }
    let(:term_id)        { create_record(EnrollmentTerm, name: "default", root_account_id: account_id) }
    let(:user)           { create_record(User, {name: "User", workflow_state: "active"}, :record) }
    let(:enrollment_map) { {} }

    # each item corresponds to a unique course the user is enrolled in
    def create_enrollments(*matrix)
      course_ids = create_records(Course, matrix.map{ |e_state, c_state, type|
        {
          name: "Course",
          account_id: account_id,
          workflow_state: c_state,
          root_account_id: account_id,
          enrollment_term_id: term_id
        }
      })

      section_ids = create_records(CourseSection, course_ids.each_with_index.map{ |course_id, i|
        {
          course_id: course_ids[i],
          root_account_id: account_id,
          name: "Section"
        }
      })

      enrollment_ids = create_records(Enrollment, matrix.each_with_index.map{ |(e_state, _, type), i|
        {
          user_id: user.id,
          course_id: course_ids[i],
          type: type,
          workflow_state: e_state,
          course_section_id: section_ids[i],
          root_account_id: account_id
        }
      })

      enrollment_ids.each_with_index do |id, i|
        enrollment_map[id] = matrix[i]
      end
    end

    def matches_for(scope)
      enrollment_map.values_at(*scope.pluck(:id)).sort
    end

    def enrollments(course_workflow_state = nil)
      scope = user.enrollments.joins(:course)
      if course_workflow_state
        scope = scope.where("courses.workflow_state = ?", course_workflow_state)
      end
      scope
    end

    shared_examples_for "enforce_course_workflow_state" do
      let(:options){ {strict_checks: false} }

      context "with :enforce_course_workflow_state=true" do
        it "should reject enrollments in courses with a different workflow_state" do
          create_enrollments(
            [state.to_s, "available", "StudentEnrollment"]
          )
          options[:course_workflow_state] = 'unknown'
          options[:enforce_course_workflow_state] = true

          result = enrollments.where(conditions)
          result.should be_empty
        end
      end
    end

    context "with :active" do
      let(:state){ :active }

      before do
        create_enrollments(
          %w{active           available StudentEnrollment},
          %w{active           available TeacherEnrollment},
          %w{active           claimed   StudentEnrollment},
          %w{active           claimed   TeacherEnrollment},
          %w{invited          available StudentEnrollment}
        )
      end

      context "with strict_checks:true" do
        let(:options){ {strict_checks: true} }

        it "should return sensible defaults" do
          result = enrollments.where(conditions)
          matches_for(result).should == [
            %w{active           available StudentEnrollment},
            %w{active           available TeacherEnrollment},
            %w{active           claimed   TeacherEnrollment}
          ]
        end

        it "should return active enrollments in available courses" do
          options[:course_workflow_state] = 'available'
          result = enrollments('available').where(conditions)
          matches_for(result).should == [
            %w{active           available StudentEnrollment},
            %w{active           available TeacherEnrollment}
          ]
        end

        it "should return visible enrollments in unpublished courses" do
          options[:course_workflow_state] = 'claimed'
          result = enrollments('claimed').where(conditions)
          matches_for(result).should == [
            %w{active           claimed   TeacherEnrollment}
          ]
        end

        it "should return nothing for other course workflow states" do
          options[:course_workflow_state] = 'deleted'
          conditions.should be_nil
        end
      end

      context "with strict_checks:false" do
        let(:options){ {strict_checks: false} }

        it "should return sensible defaults" do
          result = enrollments.where(conditions)
          matches_for(result).should == [
            %w{active           available StudentEnrollment},
            %w{active           available TeacherEnrollment},
            %w{active           claimed   StudentEnrollment},
            %w{active           claimed   TeacherEnrollment}
          ]
        end

        it "should not return anything if the course is deleted" do
          options[:course_workflow_state] = 'deleted'
          conditions.should be_nil
        end

        it "should return all active enrollments in non-deleted courses" do
          options[:course_workflow_state] = 'claimed' # not enforcing state, so we get both claimed and available
          result = enrollments.where(conditions)
          matches_for(result).should == [
            %w{active           available StudentEnrollment},
            %w{active           available TeacherEnrollment},
            %w{active           claimed   StudentEnrollment},
            %w{active           claimed   TeacherEnrollment}
          ]
        end
      end

      it_should_behave_like "enforce_course_workflow_state"
    end

    context "with :invited" do
      let(:state){ :invited }

      before do
        create_enrollments(
          %w{creation_pending available StudentEnrollment},
          %w{creation_pending available TeacherEnrollment},
          %w{creation_pending claimed   StudentEnrollment},
          %w{creation_pending claimed   TeacherEnrollment},
          %w{invited          available StudentEnrollment},
          %w{invited          available TeacherEnrollment},
          %w{invited          claimed   StudentEnrollment},
          %w{invited          claimed   TeacherEnrollment},
          %w{active           available StudentEnrollment}
        )
      end

      context "with strict_checks:true" do
        let(:options){ {strict_checks: true} }

        it "should return sensible defaults" do
          result = enrollments.where(conditions)
          matches_for(result).should == [
            %w{invited          available StudentEnrollment},
            %w{invited          available TeacherEnrollment},
            %w{invited          claimed   TeacherEnrollment}
          ]
        end

        it "should return invitations in published courses" do
          options[:course_workflow_state] = 'available'
          result = enrollments('available').where(conditions)
          matches_for(result).should == [
            %w{invited          available StudentEnrollment},
            %w{invited          available TeacherEnrollment}
          ]
        end

        it "should return invitations for admins in unpublished courses" do
          options[:course_workflow_state] = 'claimed'
          result = enrollments('claimed').where(conditions)
          matches_for(result).should == [
            %w{invited          claimed   TeacherEnrollment}
          ]
        end

        it "should not return anything if the course is deleted" do
          options[:course_workflow_state] = 'deleted'
          conditions.should be_nil
        end
      end

      context "with strict_checks:false" do
        let(:options){ {strict_checks: false} }

        it "should return sensible defaults" do
          options[:course_workflow_state] = 'available'
          result = enrollments.where(conditions)
          matches_for(result).should == [
            %w{creation_pending available StudentEnrollment},
            %w{creation_pending available TeacherEnrollment},
            %w{creation_pending claimed   StudentEnrollment},
            %w{creation_pending claimed   TeacherEnrollment},
            %w{invited          available StudentEnrollment},
            %w{invited          available TeacherEnrollment},
            %w{invited          claimed   StudentEnrollment},
            %w{invited          claimed   TeacherEnrollment}
          ]
        end

        it "should not return anything if the course is deleted" do
          options[:course_workflow_state] = 'deleted'
          conditions.should be_nil
        end

        it "should return all invitation enrollments in non-deleted courses" do
          options[:course_workflow_state] = 'available'
          result = enrollments.where(conditions)
          matches_for(result).should == [
            %w{creation_pending available StudentEnrollment},
            %w{creation_pending available TeacherEnrollment},
            %w{creation_pending claimed   StudentEnrollment},
            %w{creation_pending claimed   TeacherEnrollment},
            %w{invited          available StudentEnrollment},
            %w{invited          available TeacherEnrollment},
            %w{invited          claimed   StudentEnrollment},
            %w{invited          claimed   TeacherEnrollment}
          ]
        end
      end

      it_should_behave_like "enforce_course_workflow_state"
    end

    [:deleted, :rejected, :completed, :creation_pending, :inactive].each do |state|
      context "with #{state.inspect}" do
        let(:state){ state }

        it "should only return #{state} enrollments" do
          create_enrollments(
            %w{active     available    StudentEnrollment},
            [state.to_s, "available", "StudentEnrollment"]
          )

          result = enrollments.where(conditions)
          result.should be_present
          matches_for(result).should == [
            [state.to_s, "available", "StudentEnrollment"]
          ]
        end

        it_should_behave_like "enforce_course_workflow_state"
      end
    end

    context "with :current_and_invited" do
      let(:state) { :current_and_invited }

      it "should return sensible defaults" do
        create_enrollments(
          %w{active           available StudentEnrollment},
          %w{active           available TeacherEnrollment},
          %w{active           claimed   StudentEnrollment},
          %w{active           claimed   TeacherEnrollment},
          %w{invited          available StudentEnrollment},
          %w{invited          available TeacherEnrollment},
          %w{invited          claimed   StudentEnrollment},
          %w{invited          claimed   TeacherEnrollment},
          %w{creation_pending available StudentEnrollment}
        )

        result = enrollments.where(conditions)
        matches_for(result).should == [
          %w{active           available StudentEnrollment},
          %w{active           available TeacherEnrollment},
          %w{active           claimed   TeacherEnrollment},
          %w{invited          available StudentEnrollment},
          %w{invited          available TeacherEnrollment},
          %w{invited          claimed   TeacherEnrollment}
        ]
      end
    end

    context "with :current_and_future" do
      let(:state) { :current_and_future }

      it "should return sensible defaults" do
        create_enrollments(
          %w{active           available StudentEnrollment},
          %w{active           available TeacherEnrollment},
          %w{active           claimed   StudentEnrollment},
          %w{active           claimed   TeacherEnrollment},
          %w{invited          available StudentEnrollment},
          %w{invited          available TeacherEnrollment},
          %w{invited          claimed   StudentEnrollment},
          %w{invited          claimed   TeacherEnrollment},
          %w{creation_pending available StudentEnrollment}
        )

        result = enrollments.where(conditions)
        matches_for(result).should == [
          %w{active           available StudentEnrollment},
          %w{active           available TeacherEnrollment},
          %w{active           claimed   StudentEnrollment}, # students can see that they have an active enrollment in an unpublished course
          %w{active           claimed   TeacherEnrollment},
          %w{invited          available StudentEnrollment},
          %w{invited          available TeacherEnrollment},
          %w{invited          claimed   TeacherEnrollment}
        ]
      end
    end

    context "with :current_and_concluded" do
      let(:state) { :current_and_concluded }

      it "should return sensible defaults" do
        create_enrollments(
          %w{active           available StudentEnrollment},
          %w{active           available TeacherEnrollment},
          %w{active           claimed   StudentEnrollment},
          %w{active           claimed   TeacherEnrollment},
          %w{invited          available StudentEnrollment},
          %w{completed        available StudentEnrollment}
        )

        result = enrollments.where(conditions)
        matches_for(result).should == [
          %w{active           available StudentEnrollment},
          %w{active           available TeacherEnrollment},
          %w{active           claimed   TeacherEnrollment},
          %w{completed        available StudentEnrollment}
        ]
      end
    end
  end
end
