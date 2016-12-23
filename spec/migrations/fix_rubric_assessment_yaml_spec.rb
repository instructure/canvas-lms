require_relative '../spec_helper'

describe DataFixup::FixRubricAssessmentYAML do
  it 'should fix-up comments_html strings that were improperly serialized' do
    assignment_model
    @teacher = user_factory(active_all: true)
    @course.enroll_teacher(@teacher).accept
    @student = user_factory(active_all: true)
    @course.enroll_student(@student).accept
    rubric_model
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)
    @assessment = @association.assess({
      :user => @student,
      :assessor => @teacher,
      :artifact => @assignment.find_or_create_submission(@student),
      :assessment => {
        :assessment_type => 'grading',
        :criterion_crit1 => {
          :points => 5,
          :comments => "yes",
        }
      }
    })

    old_data = @assessment.data

    bad_yaml = RubricAssessment.where(:id => @assessment).pluck("data as d").first.gsub(":comments_html: !str", ":comments_html:")
    bad_yaml += Syckness::TAG # for old times' sake
    bad_data = YAML.load(bad_yaml)
    expect(bad_data.first[:comments_html]).to_not eq "yes" # it's reading it as a boolean
    RubricAssessment.where(:id => @assessment).update_all(['data = ?', bad_yaml])

    DataFixup::FixRubricAssessmentYAML.run

    @assessment.reload
    expect(@assessment.data.first[:comments_html]).to eq "yes" # should be fixed now
    expect(@assessment.data).to eq old_data

    DataFixup::FixRubricAssessmentYAML.run # running again won't change anything

    @assessment.reload
    expect(@assessment.data).to eq old_data
  end
end
