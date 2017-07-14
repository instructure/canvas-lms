require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/graphql_type_tester')

describe Types::EnrollmentType do
  let_once(:enrollment) { student_in_course(active_all: true) }
  let(:enrollment_type) { GraphQLTypeTester.new(Types::EnrollmentType, enrollment) }

  it "works" do
    expect(enrollment_type._id).to eq enrollment.id
    expect(enrollment_type.type).to eq "StudentEnrollment"
    expect(enrollment_type.state).to eq "active"
  end
end
