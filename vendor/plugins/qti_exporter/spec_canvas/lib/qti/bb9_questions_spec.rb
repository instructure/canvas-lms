require File.dirname(__FILE__) + '/../../qti_helper'
if Qti.migration_executable
describe "Converting Blackboard 9 qti" do

  it "should convert matching questions" do
    manifest_node=get_manifest_node('matching', :interaction_type => 'choiceInteraction', :bb_question_type => 'Matching')
    hash = Qti::ChoiceInteraction.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>bb9_question_dir)
    # make sure the ids are correctly referencing each other
    matches = []
    hash[:matches].each {|m| matches << m[:match_id]}
    hash[:answers].each do |a|
      matches.include?(a[:match_id]).should be_true
    end
    # compare everything else without the ids
    hash[:answers].each {|a|a.delete(:id); a.delete(:match_id)}
    hash[:matches].each {|m|m.delete(:match_id)}
    hash.should == BB9Expected::MATCHING
  end

  it "should find question references in selection_metadata" do
    hash = get_quiz_data(BB9_FIXTURE_DIR, 'group_with_selection_references')[1][0]
    hash[:questions].first[:questions].first.should == {:question_type=>"question_reference", :migration_id=>"_428569_1"}
  end

end

module BB9Expected
  # removed ids on the answers
  MATCHING = {:question_text=>"<p class=\"FORMATTED_TEXT_BLOCK\">Match the correct satellite with the correct planet.</p>",
              :correct_comments=>"",
              :migration_id=>"_bb9_matching_",
              :incorrect_comments=>"",
              :matches=>
                      [{:text=>"Mimas"},
                       {:text=>"Phobos"},
                       {:text=>"Luna"},
                       {:text=>"Ganymede"}],
              :points_possible=>25.0,
              :question_type=>"matching_question",
              :answers=>
                      [{:right=>"Mimas", :text=>"Mars", :left=>"Mars", :comments=>""},
                       {:right=>"Phobos", :text=>"Saturn", :left=>"Saturn", :comments=>""},
                       {:right=>"Luna", :text=>"Earth", :left=>"Earth", :comments=>""},
                       {:right=>"Ganymede", :text=>"Jupiter", :left=>"Jupiter", :comments=>""}],
              :question_name=>""}
end
end