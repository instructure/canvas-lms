require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::CoursePermissionsType do
  let_once(:course) { course_with_student(active_all: true); @course }

  def view_all_grades(user)
    loader = Loaders::CoursePermissionsLoader.new(
      @course,
      current_user: user, session: nil
    )
    GraphQL::Batch.batch {
      Types::CoursePermissionsType.fields["viewAllGrades"]
        .resolve(loader, nil, nil)
    }
  end

  it "works" do
    expect(view_all_grades(nil)).to eq false
    expect(view_all_grades(@student)).to eq false
    expect(view_all_grades(@teacher)).to eq true
  end
end
