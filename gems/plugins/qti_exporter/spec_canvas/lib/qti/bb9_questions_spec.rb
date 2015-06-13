require File.expand_path(File.dirname(__FILE__) + '/../../qti_helper')

if Qti.migration_executable
describe "Converting Blackboard 9 qti" do

  it "should convert matching questions" do
    manifest_node=get_manifest_node('matching', :interaction_type => 'choiceInteraction', :bb_question_type => 'Matching')
    hash = Qti::ChoiceInteraction.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>bb9_question_dir)
    # make sure the ids are correctly referencing each other
    matches = []
    hash[:matches].each {|m| matches << m[:match_id]}
    hash[:answers].each do |a|
      expect(matches.include?(a[:match_id])).to be_truthy
    end
    # compare everything else without the ids
    hash[:answers].each {|a|a.delete(:id); a.delete(:match_id)}
    hash[:matches].each {|m|m.delete(:match_id)}
    expect(hash).to eq BB9Expected::MATCHING
  end

  it "should convert matching questions if the divs precede the choice Interactions" do
    manifest_node=get_manifest_node('matching3', :interaction_type => 'choiceInteraction', :bb_question_type => 'Matching')
    hash = Qti::ChoiceInteraction.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>bb9_question_dir)
    # make sure the ids are correctly referencing each other
    matches = []
    hash[:matches].each {|m| matches << m[:match_id]}
    hash[:answers].each do |a|
      expect(matches.include?(a[:match_id])).to be_truthy
    end
    # compare everything else without the ids
    hash[:answers].each {|a|a.delete(:id); a.delete(:match_id)}
    hash[:matches].each {|m|m.delete(:match_id)}
    expect(hash).to eq BB9Expected::MATCHING
  end

  it "should find question references in selection_metadata" do
    hash = get_quiz_data(BB9_FIXTURE_DIR, 'group_with_selection_references')[1][0]
    expect(hash[:questions].first[:questions].first).to eq({:question_type=>"question_reference", :migration_id=>"_428569_1"})
  end

  it "should convert matching questions where the answers are given out of order" do
    hash = get_question_hash(bb9_question_dir, 'matching2', false)
    matches = {}
    hash[:matches].each {|m| matches[m[:match_id]] = m[:text]}
    hash[:answers].each do |a|
      expect(matches[a[:match_id]]).to eq a[:text].sub('left', 'right')
    end
    # compare everything else without the ids
    hash[:answers].each {|a|a.delete(:id); a.delete(:match_id)}
    hash[:matches].each {|m|m.delete(:match_id)}
    expect(hash).to eq BB9Expected::MATCHING2
  end

  it "should convert true/false questions using identifiers, not mattext" do
    hash = get_question_hash(bb9_question_dir, 'true_false', false, :flavor => Qti::Flavors::BBLEARN)
    hash[:answers].each {|m| expect(m[:migration_id]).to eq m[:text].downcase}
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

  MATCHING2 = {:answers=>
                  [{:right=>"right 1", :text=>"left 1", :left=>"left 1", :comments=>""},
                   {:right=>"right 2", :text=>"left 2", :left=>"left 2", :comments=>""},
                   {:right=>"right 3", :text=>"left 3", :left=>"left 3", :comments=>""},
                   {:right=>"right 4", :text=>"left 4", :left=>"left 4", :comments=>""}],
              :correct_comments=>"right",
              :incorrect_comments=>"wrong",
              :points_possible=>10.0,
              :question_type=>"matching_question",
              :question_name=>"",
              :question_text=>"Match these.<br>",
              :migration_id=>"_5085986_1",
              :matches=>
                  [{:text=>"right 1"},
                   {:text=>"right 2"},
                   {:text=>"DISTRACTION"},
                   {:text=>"right 4"},
                   {:text=>"right 3"}]}
end
end
