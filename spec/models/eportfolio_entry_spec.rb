# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

describe EportfolioEntry do
  describe "validation" do
    before(:once) do
      eportfolio_model
      @long_string = 'qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm
                      qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm
                      qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm
                      qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm
                      qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm'
    end

    it "validates the length of attributes" do
      @eportfolio_entry.name = @long_string
      @eportfolio_entry.slug = @long_string
      expect { @eportfolio_entry.save! }.to raise_error("Validation failed: Name is too long (maximum is 255 characters), Slug is too long (maximum is 255 characters)")
    end

    it "validates the length of slug" do
      @eportfolio_entry.slug = @long_string
      expect { @eportfolio_entry.save! }.to raise_error("Validation failed: Slug is too long (maximum is 255 characters)")
    end

    it "validates the length of name" do
      @eportfolio_entry.name = @long_string
      expect { @eportfolio_entry.save! }.to raise_error("Validation failed: Name is too long (maximum is 255 characters)")
    end
  end

  context "parse_content" do
    before :once do
      eportfolio_model
    end

    it "accepts valid attachments" do
      eportfolio_model
      attachment_model(context: @user)
      @eportfolio_entry.parse_content({ section_count: 1, section_1: { section_type: "attachment", attachment_id: @attachment.id } })
      expect(@eportfolio_entry.content).not_to be_nil
      expect(@eportfolio_entry.content.length).to be(1)
      expect(@eportfolio_entry.content[0][:section_type]).to eql("attachment")
      expect(@eportfolio_entry.content[0][:attachment_id]).to eql(@attachment.id)
    end

    it "does not accept invalid attachments" do
      attachment_model(context: User.create)
      @eportfolio_entry.parse_content({ section_count: 1, section_1: { section_type: "attachment", attachment_id: @attachment.id } })
      expect(@eportfolio_entry.content).not_to be_nil
      expect(@eportfolio_entry.content.length).to be(1)
      expect(@eportfolio_entry.content[0]).to eql("No Content Added Yet")

      @eportfolio_entry.parse_content({ section_count: 1, section_1: { section_type: "attachment" } })
      expect(@eportfolio_entry.content).not_to be_nil
      expect(@eportfolio_entry.content.length).to be(1)
      expect(@eportfolio_entry.content[0]).to eql("No Content Added Yet")
    end

    it "accepts valid submissions" do
      submission_model(user: @user)
      @eportfolio_entry.parse_content({ section_count: 1, section_1: { section_type: "submission", submission_id: @submission.id } })
      expect(@eportfolio_entry.content).not_to be_nil
      expect(@eportfolio_entry.content.length).to be(1)
      expect(@eportfolio_entry.content[0][:section_type]).to eql("submission")
      expect(@eportfolio_entry.content[0][:submission_id]).to eql(@submission.id)
    end

    it "does not accept invalid submissions" do
      submission_model
      @bad_submission = @submission
      eportfolio_model
      submission_model(user: @user)
      @eportfolio_entry.parse_content({ section_count: 1, section_1: { section_type: "submission", submission_id: @bad_submission.id } })
      expect(@eportfolio_entry.content).not_to be_nil
      expect(@eportfolio_entry.content.length).to be(1)
      expect(@eportfolio_entry.content[0]).to eql("No Content Added Yet")

      @eportfolio_entry.parse_content({ section_count: 1, section_1: { section_type: "submission" } })
      expect(@eportfolio_entry.content).not_to be_nil
      expect(@eportfolio_entry.content.length).to be(1)
      expect(@eportfolio_entry.content[0]).to eql("No Content Added Yet")
    end

    it "accepts valid html content" do
      @eportfolio_entry.parse_content({ section_count: 1, section_1: { section_type: "html", content: "<a onclick='javascript: alert(5);' href='#bob;'>link</a>" } })
      expect(@eportfolio_entry.content).not_to be_nil
      expect(@eportfolio_entry.content.length).to be(1)
      expect(@eportfolio_entry.content[0][:section_type]).to eql("html")
      expect(@eportfolio_entry.content[0][:content]).to match(/\#bob/)
      expect(@eportfolio_entry.content[0][:content]).to match(/link/)
      expect(@eportfolio_entry.content[0][:content]).not_to match(/alert/)
      expect(@eportfolio_entry.content[0][:content]).not_to match(/javascript/)
    end

    it "does not accept invalid html content" do
      @eportfolio_entry.parse_content({ section_count: 1, section_1: { section_type: "html" } })
      expect(@eportfolio_entry.content).not_to be_nil
      expect(@eportfolio_entry.content.length).to be(1)
      expect(@eportfolio_entry.content[0]).to eql("No Content Added Yet")
    end

    it "accepts valid rich content" do
      @eportfolio_entry.parse_content({ section_count: 1, section_1: { section_type: "rich_text", content: "<a onclick='javascript: alert(5);' href='#bob;'>link</a>" } })
      expect(@eportfolio_entry.content).not_to be_nil
      expect(@eportfolio_entry.content.length).to be(1)
      expect(@eportfolio_entry.content[0][:section_type]).to eql("rich_text")
      expect(@eportfolio_entry.content[0][:content]).to match(/\#bob/)
      expect(@eportfolio_entry.content[0][:content]).to match(/link/)
      expect(@eportfolio_entry.content[0][:content]).not_to match(/alert/)
      expect(@eportfolio_entry.content[0][:content]).not_to match(/javascript/)
    end

    it "does not accept invalid rich content" do
      @eportfolio_entry.parse_content({ section_count: 1, section_1: { section_type: "rich_text", content: "<blink/>" } })
      expect(@eportfolio_entry.content).not_to be_nil
      expect(@eportfolio_entry.content.length).to be(1)
      expect(@eportfolio_entry.content[0]).to eql("No Content Added Yet")
    end
  end

  it "updates eportfolio date" do
    eportfolio_model
    old_time = 1.day.ago
    @eportfolio.update_attribute(:updated_at, old_time)
    @eportfolio_entry.name = "update test"
    @eportfolio_entry.save!
    expect(@eportfolio.updated_at.to_i).not_to eq(old_time.to_i)
  end

  describe "callbacks" do
    before(:once) do
      eportfolio_model
    end

    describe "#check_for_spam" do
      let(:spam_status) { @eportfolio.reload.spam_status }
      let(:entry) { @eportfolio_entry }

      context "when the setting has a value" do
        before do
          Setting.set("eportfolio_title_spam_keywords", "bad, verybad, worse")
          Setting.set("eportfolio_content_spam_keywords", "injurious,deleterious")
        end

        it "marks the owning portfolio as possible spam when the title matches any title keywords" do
          entry.update!(name: "my verybad page")
          expect(spam_status).to eq "flagged_as_possible_spam"
        end

        it "marks the owning portfolio as possible spam when a content section matches any content keywords" do
          entry.parse_content(
            section_count: 1,
            section_1: {
              section_type: "html",
              content: "<p>This is my deleterious page</p>"
            }
          )
          entry.save!
          expect(spam_status).to eq "flagged_as_possible_spam"
        end

        it "does not mark as spam when neither the title nor the content match their respective offending keywords" do
          expect do
            entry.update!(name: "my injurious page")
            entry.parse_content(
              section_count: 1,
              section_1: {
                section_type: "html",
                content: "<p>This is my bad page</p>"
              }
            )
            entry.save!
          end.not_to change { spam_status }
        end

        it "does not mark as spam if a spam_status already exists" do
          @eportfolio.update!(spam_status: "marked_as_safe")

          expect do
            entry.update!(name: "actually a bad page")
          end.not_to change { spam_status }
        end
      end

      it "does not attempt to mark as spam when the setting is empty" do
        expect do
          entry.update!(name: "actually a bad page")
        end.not_to change { spam_status }
      end
    end
  end
end
