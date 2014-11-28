require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

class Subject
  include Api::V1::AssignmentOverride
end

describe "Api::V1::AssignmentOverride" do

  describe "#interpret_assignment_override_data" do

    it "works even with nil date fields" do
      override = {:student_ids => [1],
                  :due_at => nil,
                  :unlock_at => nil,
                  :lock_at => nil
      }
      subj = Subject.new
      subj.stubs(:api_find_all).returns []
      assignment = stub(:context => stub(:students_visible_to) )
      result = subj.interpret_assignment_override_data(assignment, override,'ADHOC')
      expect(result.first[:due_at]).to eq nil
      expect(result.first[:unlock_at]).to eq nil
      expect(result.first[:lock_at]).to eq nil
    end
  end
end
