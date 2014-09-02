# encoding: UTF-8

require File.expand_path(File.dirname(__FILE__) + '/../../qti_helper')
if Qti.migration_executable
describe "HTML Sanitization of" do
  describe "question text" do
    it "should sanitize qti v2p1 escaped html" do
      manifest_node=get_manifest_node('multiple_answer')
      hash = Qti::AssessmentItemConverter.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>html_sanitization_question_dir('escaped'))
      hash[:question_text].should match_ignoring_whitespace("The Media Wizard also allows you to embed images, audio and video from popular websites, such as YouTube and Picasa. You can also link to an image or audio or video file stored on another server. The advantage to linking to a file is that you don't have to copy the original media content to your online course – you just add a link to it. <br><br><b>Question: </b>Respondus can embed video, audio and images from which two popular websites mentioned above? alert('test')")
    end
    it "should sanitize qti v2p1 html nodes" do
      manifest_node=get_manifest_node('essay')
      hash = Qti::AssessmentItemConverter.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>html_sanitization_question_dir('nodes'))
      hash[:question_text].should == "<p class=\"FORMATTED_TEXT_BLOCK\">Who likes to use Blackboard? alert('not me')</p>"
    end
    it "should sanitize other escaped html" do # e.g. angel proprietary
      qti_data = file_as_string(html_sanitization_question_dir('escaped'), 'angel_essay.xml')
      hash = Qti::AssessmentItemConverter.create_instructure_question(:qti_data=>qti_data, :interaction_type=>'essay_question', :custom_type=>'angel')
      hash[:question_text].should == "<div>Rhode Island is neither a road nor an island. Discuss. alert('total pwnage')</div>"
    end
  end
  describe "multiple choice text" do
    it "should sanitize and strip qti v2p1 escaped html" do
      manifest_node=get_manifest_node('multiple_choice')
      hash = Qti::AssessmentItemConverter.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>html_sanitization_question_dir('escaped'))
      hash[:answers].each { |a| a.replace(:html => a[:html], :text => a[:text]) }
      hash[:answers].should == [
        {:html=>"\302\240<img src=\"image0014c114649.jpg\" alt=\"\">",
         :text=>"No answer text provided."},
        {:html=>nil, # script tag removed
         :text=>"No answer text provided."},
        {:html=>"<img src=\"image0034c114649.jpg\" alt=\"\">", # whitespace removed
         :text=>"No answer text provided."}
      ]
    end
    it "should sanitize and strip qti v2p1 html nodes" do
      manifest_node=get_manifest_node('multiple_choice')
      hash = Qti::AssessmentItemConverter.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>html_sanitization_question_dir('nodes'))
      hash[:answers].each { |a| a.replace(:html => a[:html], :text => a[:text]) }
      hash[:answers].should == [
        {:html=>nil, :text=>"nose"}, # no script tags
        {:html=>nil, :text=>"ear"}, # whitespace removed
        {:html=>"<b>eye</b>", :text=>"eye"},
        {:html=>nil, :text=>"mouth"}
      ]
    end
  end
  describe "multiple answer text" do
    it "should sanitize and strip qti v2p1 escaped html" do
      manifest_node=get_manifest_node('multiple_answer')
      hash = Qti::AssessmentItemConverter.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>html_sanitization_question_dir('escaped'))
      hash[:answers].each { |a| a.replace(:html => a[:html], :text => a[:text]) }
      hash[:answers][0][:html].should match_ignoring_whitespace("YouTube <br><object width=\"425\" height=\"344\"><param name=\"movie\" value=\"http://www.youtube.com/v/fTQPCocCwJo?f=videos&amp;app=youtube_gdata&amp;rel=0&amp;autoplay=0&amp;loop=0\">\n<embed src=\"http://www.youtube.com/v/fTQPCocCwJo?f=videos&amp;app=youtube_gdata&amp;rel=0&amp;autoplay=0&amp;loop=0\" type=\"application/x-shockwave-flash\" width=\"425\" height=\"344\"></embed></object>")
      hash[:answers][0][:text].should == "YouTube"
      hash[:answers][1][:html].should match_ignoring_whitespace("Google Picasa<br><span style=\"color: #000000;\"><img src=\"http://lh4.ggpht.com/_U8dXqlIRHu8/Ss4167b2RzI/AAAAAAAAABs/MVyeP6FhYDM/picasa-logo.jpg\" width=\"150\" height=\"59\"></span>\302\240")
      hash[:answers][1][:text].should == "Google Picasa"
      hash[:answers][2][:html].should == nil # sanitized html == text, so we exclude it
      hash[:answers][2][:text].should == "Facebook alert(0xFACE)" # no script tags
      hash[:answers][3][:html].should == nil
      hash[:answers][3][:text].should == "Twitter" # we've stripped off extraneous whitespace
    end
    it "should sanitize and strip qti v2p1 html nodes" do
      manifest_node=get_manifest_node('multiple_answer')
      hash = Qti::AssessmentItemConverter.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>html_sanitization_question_dir('nodes'))
      hash[:answers].each { |a| a.replace(:html => a[:html], :text => a[:text]) }
      hash[:answers].should == [
        {:html=>"<b>house</b>", :text=>"house"}, # whitespace removed
        {:html=>nil, :text=>"garage"}, # no script tags
        {:html=>nil, :text=>"barn"},
        {:html=>nil, :text=>"pond"}
      ]
    end
  end
  describe "matching text" do
    it "should sanitize and strip qti v2p1 escaped html" do
      manifest_node=get_manifest_node('matching')
      hash = Qti::AssessmentItemConverter.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>html_sanitization_question_dir('escaped'))
      hash[:answers].each { |a| a.replace(:html => a[:html], :text => a[:text]) }
      hash[:answers].should == [
        {:html=>"<i>London</i>", :text=>"London"},
        {:html=>"<b>Paris</b>", :text=>"Paris"}, # <b> tag gets closed
        {:html=>nil, :text=>"New York"}, # script tag removed
        {:html=>nil, :text=>"Toronto"},
        {:html=>nil, :text=>"Sydney"}
      ]
    end
    it "should sanitize and strip qti v2p1 html nodes" do
      manifest_node=get_manifest_node('matching')
      hash = Qti::AssessmentItemConverter.create_instructure_question(:manifest_node=>manifest_node, :base_dir=>html_sanitization_question_dir('nodes'))
      hash[:answers].each { |a| a.replace(:html => a[:html], :text => a[:text]) }
      hash[:answers].should == [
        {:html=>nil, :text=>"left 1"},
        {:html=>"<i>left 2</i>", :text=>"left 2"},
        {:html=>nil, :text=>"left 3"},
        {:html=>nil, :text=>"left 4"}
      ]
      hash[:matches].collect{ |m| m[:text]}.should == ["right 1", "right 2", "right 3", "right 4"]
    end
  end
end
end

