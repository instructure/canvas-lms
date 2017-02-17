require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20140815192313_fix_content_tags_without_content.rb'

describe 'FixContentTagsWithoutContents' do
  describe "up" do
    it "should delete corrupt content tags from migrations" do
      course_factory
      mod = @course.context_modules.create!
      tag = mod.content_tags.new(:context => @course)
      tag.save(:validate => false)
      FixContentTagsWithoutContent.new.up

      expect(ContentTag.find_by_id(tag.id)).to be_nil
    end
  end
end
