require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20130405213030_fix_broken_file_links_in_assignments.rb'

describe 'DataFixup::FixBrokenFileLinksInAssignments' do
  
  it "should find assignments without verifiers" do
    assignment_model
    @assignment.description = '<a id="l16" href="/files/1/download">oi</a>'
    @assignment.save!
    expect(DataFixup::FixBrokenFileLinksInAssignments.broken_assignment_scope.count).to eq 1
  end
  
  it "should find assignments with verifiers" do
    assignment_model
    @assignment.description = '<a id="l16" href="/files/1/download?verifier=hahaha">oi</a>'
    @assignment.save!
    expect(DataFixup::FixBrokenFileLinksInAssignments.broken_assignment_scope.count).to eq 1
  end
  
  it "should not find assignments with only normal links" do
    assignment_model
    @assignment.description = '<a id="l16" href="/courses/1/files/1/download?wrap=1>oi</a>'
    @assignment.save!
    expect(DataFixup::FixBrokenFileLinksInAssignments.broken_assignment_scope.count).to eq 0
  end
  
  it "should fix links in assignment descriptions that point to deleted files with a verifier param" do
    course1 = course
    att1 = attachment_model(:context => course1)
    att3 = attachment_model(:context => course1)
    course2 = course
    att2 = att1.clone_for(course2, nil, :overwrite => true)
    att2.save!

    att4 = attachment_model(:context => course1, :filename => "somethingelse.doc")
    att4.destroy
    att5 = Attachment.create!(:folder => att4.folder, :context => att4.context, :filename => att4.filename, :uploaded_data => StringIO.new("first"))
    att6 = att5.clone_for(course2, nil, :overwrite => true)
    att6.save!

    assignment_model(:course => course2)
    @assignment.description =<<-HTML
    <!-- in the current course context -->
    <a id="l1" href="/courses/#{course2.id}/files/#{att2.id}/download?wrap=1">context, no verifier</a>
    <a id="l2" href="/courses/#{course2.id}/files/#{att2.id}/download?verifier=hurpdurpdurp">context, verifier</a>
    <a id="l3" href="/files/#{att2.id}/download?verifier=hurpdurpdurp">no context, verifier</a>
    <a id="l4" href="/files/#{att2.id}/download">not context, no verifier</a>
    <!-- in a different context but attachment was cloned -->
    <a id="l5" href="/courses/#{course1.id}/files/#{att1.id}/download?verifier=hurpdurpdurp">context, verifier</a>
    <a id="l6" href="/courses/#{course1.id}/files/#{att1.id}/download">context, no verifier</a>
    <a id="l7" href="/files/#{att1.id}/download?verifier=hurpdurpdurp">no context, verifier</a>
    <a id="l8" href="/files/#{att1.id}/download">no context, no verifier</a>
    <!-- in a different context but attachment was not cloned -->
    <a id="l9" href="/courses/#{course1.id}/files/#{att3.id}/download?verifier=hurpdurpdurp">context, verifier</a>
    <a id="l10" href="/courses/#{course1.id}/files/#{att3.id}/download">context, no verifier</a>
    <a id="l11" href="/files/#{att3.id}/download?verifier=hurpdurpdurp">no context, verifier</a>
    <a id="l12" href="/files/#{att3.id}/download">no context, no verifier</a>
    <!-- in a different context but attachment was destroyed and reupdated and then cloned -->
    <a id="l13" href="/courses/#{course1.id}/files/#{att4.id}/download?verifier=hurpdurpdurp">context, verifier</a>
    <a id="l14" href="/courses/#{course1.id}/files/#{att4.id}/download">context, no verifier</a>
    <a id="l15" href="/files/#{att4.id}/download?verifier=hurpdurpdurp">no context, verifier</a>
    <a id="l16" href="/files/#{att4.id}/download">no context, no verifier</a>
    HTML
    @assignment.save!

    FixBrokenFileLinksInAssignments.up

    @assignment.reload
    node = Nokogiri::HTML(@assignment.description)
    expect(node.at_css('#l1 @href').text).to eq "/courses/#{course2.id}/files/#{att2.id}/download?wrap=1"
    expect(node.at_css('#l2 @href').text).to eq "/courses/#{course2.id}/files/#{att2.id}/download?wrap=1"
    expect(node.at_css('#l3 @href').text).to eq "/courses/#{course2.id}/files/#{att2.id}/download?wrap=1"
    expect(node.at_css('#l4 @href').text).to eq "/courses/#{course2.id}/files/#{att2.id}/download?wrap=1"
    # other context cloned
    expect(node.at_css('#l5 @href').text).to eq "/courses/#{course2.id}/files/#{att2.id}/download?wrap=1"
    expect(node.at_css('#l6 @href').text).to eq "/courses/#{course2.id}/files/#{att2.id}/download?wrap=1"
    expect(node.at_css('#l7 @href').text).to eq "/courses/#{course2.id}/files/#{att2.id}/download?wrap=1"
    expect(node.at_css('#l8 @href').text).to eq "/courses/#{course2.id}/files/#{att2.id}/download?wrap=1"
    # other context not cloned
    expect(node.at_css('#l9 @href').text).to eq "/courses/#{course1.id}/files/#{att3.id}/download?verifier=hurpdurpdurp"
    expect(node.at_css('#l10 @href').text).to eq "/courses/#{course1.id}/files/#{att3.id}/download"
    expect(node.at_css('#l11 @href').text).to eq "/courses/#{course1.id}/files/#{att3.id}/download?verifier=hurpdurpdurp"
    expect(node.at_css('#l12 @href').text).to eq "/courses/#{course1.id}/files/#{att3.id}/download"

    expect(node.at_css('#l13 @href').text).to eq "/courses/#{course2.id}/files/#{att6.id}/download?wrap=1"
    expect(node.at_css('#l14 @href').text).to eq "/courses/#{course2.id}/files/#{att6.id}/download?wrap=1"
    expect(node.at_css('#l15 @href').text).to eq "/courses/#{course2.id}/files/#{att6.id}/download?wrap=1"
    expect(node.at_css('#l16 @href').text).to eq "/courses/#{course2.id}/files/#{att6.id}/download?wrap=1"
  end

  it "should find new courses's attachment by old attachment cloned_item_id" do
    course1 = course
    att1 = attachment_model(:context => course1)
    course2 = course
    att2 = att1.clone_for(course2, nil, :overwrite => true)
    att2.save!

    course2.reload
    att1.reload

    att2_2 = course2.attachments.find_by_cloned_item_id(att1.cloned_item_id) if att1.cloned_item_id
    expect(att2_2).to eq att2
  end

  it "shouldn't break a discussion assignment" do
    course1 = course
    att1 = attachment_model(:context => course1)
    assignment_model(:context => course1, :submission_types => "discussion_topic", :description => "<a id=\"l3\" href=\"/files/#{att1.id}/download?verifier=hurpdurpdurp\">no context, verifier</a>")
    topic = @assignment.discussion_topic

    topic.reload
    expect(topic.assignment).not_to be_nil

    FixBrokenFileLinksInAssignments.up

    @assignment.reload
    expect(@assignment.description).to eq "<a id=\"l3\" href=\"/courses/#{course1.id}/files/#{att1.id}/download?wrap=1\">no context, verifier</a>"

    topic.reload
    expect(topic.assignment).not_to be_nil
  end
end
