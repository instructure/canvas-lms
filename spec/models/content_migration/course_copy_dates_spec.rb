# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "course_copy_helper"

describe ContentMigration do
  context "course copy dates" do
    include_context "course copy"

    describe "date shifting" do
      before :once do
        @old_start = Time.zone.parse("01 Jul 2012 06:00:00 UTC +00:00")
        @new_start = Time.zone.parse("05 Aug 2012 06:00:00 UTC +00:00")

        @copy_from.require_assignment_group
        @copy_from.assignments.create!(due_at: @old_start + 1.day,
                                       unlock_at: @old_start - 2.days,
                                       lock_at: @old_start + 3.days,
                                       peer_reviews_due_at: @old_start + 4.days)

        att = Attachment.create!(context: @copy_from,
                                 filename: "hi.txt",
                                 uploaded_data: StringIO.new("stuff"),
                                 folder: Folder.unfiled_folder(@copy_from))
        att.unlock_at = @old_start - 2.days
        att.lock_at = @old_start + 3.days
        att.save!

        folder = @copy_from.folders.create!(name: "shifty",
                                            unlock_at: @old_start - 3.days,
                                            lock_at: @old_start + 2.days)
        @copy_from.attachments.create!(filename: "blah",
                                       uploaded_data: StringIO.new("blah"),
                                       folder:)

        @copy_from.quizzes.create!(due_at: "05 Jul 2012 06:00:00 UTC +00:00",
                                   unlock_at: @old_start + 1.day,
                                   lock_at: @old_start + 5.days,
                                   show_correct_answers_at: @old_start + 6.days,
                                   hide_correct_answers_at: @old_start + 7.days)
        @copy_from.discussion_topics.create!(title: "some topic",
                                             message: "<p>some text</p>",
                                             delayed_post_at: @old_start + 3.days,
                                             lock_at: @old_start + 7.days)
        @copy_from.announcements.create!(title: "hear ye",
                                         message: "<p>grades will henceforth be in Cyrillic letters</p>",
                                         delayed_post_at: @old_start + 10.days)
        @copy_from.calendar_events.create!(title: "an event",
                                           start_at: @old_start + 4.days,
                                           end_at: @old_start + 4.days + 1.hour)
        @copy_from.wiki_pages.create!(title: "a page",
                                      workflow_state: "unpublished",
                                      todo_date: @old_start + 7.days,
                                      publish_at: @old_start + 3.days)
        cm = @copy_from.context_modules.build(name: "some module", unlock_at: @old_start + 1.day)
        cm.save!

        cm2 = @copy_from.context_modules.build(name: "some module", unlock_at: @old_start + 1.day)
        cm2.save!
      end

      it "shifts dates" do
        skip unless Qti.qti_enabled?
        options = {
          everything: true,
          shift_dates: true,
          old_start_date: "Jul 1, 2012",
          old_end_date: "Jul 11, 2012",
          new_start_date: "Aug 5, 2012",
          new_end_date: "Aug 15, 2012"
        }
        @cm.copy_options = options
        @cm.save!

        run_course_copy

        new_asmnt = @copy_to.assignments.first
        expect(new_asmnt.due_at.to_i).to eq (@new_start + 1.day).to_i
        expect(new_asmnt.unlock_at.to_i).to eq (@new_start - 2.days).to_i
        expect(new_asmnt.lock_at.to_i).to eq (@new_start + 3.days).to_i
        expect(new_asmnt.peer_reviews_due_at.to_i).to eq (@new_start + 4.days).to_i

        new_att = @copy_to.attachments.where(display_name: "hi.txt").first
        expect(new_att.unlock_at.to_i).to eq (@new_start - 2.days).to_i
        expect(new_att.lock_at.to_i).to eq (@new_start + 3.days).to_i

        new_folder = @copy_to.folders.where(name: "shifty").first
        expect(new_folder.unlock_at.to_i).to eq (@new_start - 3.days).to_i
        expect(new_folder.lock_at.to_i).to eq (@new_start + 2.days).to_i

        new_quiz = @copy_to.quizzes.first
        expect(new_quiz.due_at.to_i).to eq (@new_start + 4.days).to_i
        expect(new_quiz.unlock_at.to_i).to eq (@new_start + 1.day).to_i
        expect(new_quiz.lock_at.to_i).to eq (@new_start + 5.days).to_i
        expect(new_quiz.show_correct_answers_at.to_i).to eq (@new_start + 6.days).to_i
        expect(new_quiz.hide_correct_answers_at.to_i).to eq (@new_start + 7.days).to_i

        new_disc = @copy_to.discussion_topics.first
        expect(new_disc.delayed_post_at.to_i).to eq (@new_start + 3.days).to_i
        expect(new_disc.lock_at.to_i).to eq (@new_start + 7.days).to_i

        new_ann = @copy_to.announcements.first
        expect(new_ann.delayed_post_at.to_i).to eq (@new_start + 10.days).to_i

        new_event = @copy_to.calendar_events.first
        expect(new_event.start_at.to_i).to eq (@new_start + 4.days).to_i
        expect(new_event.end_at.to_i).to eq (@new_start + 4.days + 1.hour).to_i

        new_page = @copy_to.wiki_pages.first
        expect(new_page.todo_date.to_i).to eq (@new_start + 7.days).to_i
        expect(new_page.publish_at.to_i).to eq (@new_start + 3.days).to_i

        new_mod = @copy_to.context_modules.first
        expect(new_mod.unlock_at.to_i).to eq (@new_start + 1.day).to_i

        newer_mod = @copy_to.context_modules.last
        expect(newer_mod.unlock_at.to_i).to eq (@new_start + 1.day).to_i
      end

      it "infers a sensible end date if not provided" do
        skip unless Qti.qti_enabled?
        options = {
          everything: true,
          shift_dates: true,
          old_start_date: "Jul 1, 2012",
          old_end_date: nil,
          new_start_date: "Aug 5, 2012",
          new_end_date: nil
        }
        @cm.copy_options = options
        @cm.save!

        run_course_copy

        new_asmnt = @copy_to.assignments.first
        expect(new_asmnt.due_at.to_i).to eq (@new_start + 1.day).to_i
        expect(new_asmnt.unlock_at.to_i).to eq (@new_start - 2.days).to_i
        expect(new_asmnt.lock_at.to_i).to eq (@new_start + 3.days).to_i
        expect(new_asmnt.peer_reviews_due_at.to_i).to eq (@new_start + 4.days).to_i
      end

      it "ignores a bad end date" do
        skip unless Qti.qti_enabled?
        options = {
          everything: true,
          shift_dates: true,
          old_start_date: "Jul 1, 2012",
          old_end_date: nil,
          new_start_date: "Aug 5, 2012",
          new_end_date: "Jul 4, 2012"
        }
        @cm.copy_options = options
        @cm.save!

        run_course_copy

        new_asmnt = @copy_to.assignments.first
        expect(new_asmnt.due_at.to_i).to eq (@new_start + 1.day).to_i
        expect(new_asmnt.unlock_at.to_i).to eq (@new_start - 2.days).to_i
        expect(new_asmnt.lock_at.to_i).to eq (@new_start + 3.days).to_i
        expect(new_asmnt.peer_reviews_due_at.to_i).to eq (@new_start + 4.days).to_i
      end

      it "removes dates" do
        skip unless Qti.qti_enabled?
        options = {
          everything: true,
          remove_dates: true,
        }
        @cm.copy_options = options
        @cm.save!

        run_course_copy

        new_asmnt = @copy_to.assignments.first
        expect(new_asmnt.due_at).to be_nil
        expect(new_asmnt.unlock_at).to be_nil
        expect(new_asmnt.lock_at).to be_nil
        expect(new_asmnt.peer_reviews_due_at).to be_nil

        new_att = @copy_to.attachments.first
        expect(new_att.unlock_at).to be_nil
        expect(new_att.lock_at).to be_nil

        new_folder = @copy_to.folders.where(name: "shifty").first
        expect(new_folder.unlock_at).to be_nil
        expect(new_folder.lock_at).to be_nil

        new_quiz = @copy_to.quizzes.first
        expect(new_quiz.due_at).to be_nil
        expect(new_quiz.unlock_at).to be_nil
        expect(new_quiz.lock_at).to be_nil
        expect(new_quiz.show_correct_answers_at).to be_nil
        expect(new_quiz.hide_correct_answers_at).to be_nil

        new_disc = @copy_to.discussion_topics.first
        expect(new_disc.delayed_post_at).to be_nil
        expect(new_disc.lock_at).to be_nil
        expect(new_disc.locked).to be_falsey

        new_ann = @copy_to.announcements.first
        expect(new_ann.delayed_post_at).to be_nil

        new_event = @copy_to.calendar_events.first
        expect(new_event.start_at).to be_nil
        expect(new_event.end_at).to be_nil

        new_mod = @copy_to.context_modules.first
        expect(new_mod.unlock_at).to be_nil

        newer_mod = @copy_to.context_modules.last
        expect(newer_mod.unlock_at).to be_nil
      end

      it "does not create broken assignments from unpublished quizzes" do
        options = {
          everything: true,
          remove_dates: true,
        }
        @cm.copy_options = options
        @cm.save!

        run_course_copy

        expect(@copy_to.assignments.count).to eq 1
      end
    end

    context "when crossing daylight saving shift" do
      let(:local_time_zone) { ActiveSupport::TimeZone.new "America/Denver" }

      def copy_assignment(options = {})
        account = @copy_to.account

        old_time_zone = account.default_time_zone
        account.default_time_zone = options.include?(:account_time_zone) ? options[:account_time_zone].name : "UTC"
        account.save!

        Time.use_zone("UTC") do
          assignment = @copy_from.assignments.create! title: "Assignment", due_at: old_date
          assignment.save!

          opts = {
            everything: true,
            shift_dates: true,
            old_start_date:,
            old_end_date:,
            new_start_date:,
            new_end_date:
          }
          opts[:time_zone] = options[:time_zone].name if options.include?(:time_zone)
          @cm.copy_options = @cm.copy_options.merge(opts)
          @cm.save!

          run_course_copy

          assignment2 = @copy_to.assignments.where(migration_id: mig_id(assignment)).first
          assignment2.due_at.in_time_zone(local_time_zone)
        end
      ensure
        account.default_time_zone = old_time_zone
        account.save!
      end

      context "when MST to MDT" do
        let(:old_date) { local_time_zone.local(2012, 1, 6, 12, 0) } # 6 Jan 2012 12:00
        let(:new_date) { local_time_zone.local(2012, 4, 6, 12, 0) } # 6 Apr 2012 12:00
        let(:old_start_date) { "Jan 1, 2012" }
        let(:old_end_date) { "Jan 15, 2012" }
        let(:new_start_date) { "Apr 1, 2012" }
        let(:new_end_date) { "Apr 15, 2012" }

        it "using an explicit time zone" do
          expect(new_date).to eq copy_assignment(time_zone: local_time_zone)
          expect(@copy_to.start_at.utc).to eq Time.zone.parse("2012-04-01 06:00:00 UTC")
          expect(@copy_to.conclude_at.utc).to eq Time.zone.parse("2012-04-15 06:00:00 UTC")
        end

        it "using the account time zone" do
          expect(new_date).to eq copy_assignment(account_time_zone: local_time_zone)
          expect(@copy_to.start_at.utc).to eq Time.zone.parse("2012-04-01 06:00:00 UTC")
          expect(@copy_to.conclude_at.utc).to eq Time.zone.parse("2012-04-15 06:00:00 UTC")
        end
      end

      context "when MDT to MST" do
        let(:old_date) { local_time_zone.local(2012, 9, 6, 12, 0) } # 6 Sep 2012 12:00
        let(:new_date) { local_time_zone.local(2012, 12, 6, 12, 0) } # 6 Dec 2012 12:00
        let(:old_start_date) { "Sep 1, 2012" }
        let(:old_end_date) { "Sep 15, 2012" }
        let(:new_start_date) { "Dec 1, 2012" }
        let(:new_end_date) { "Dec 15, 2012" }

        it "using an explicit time zone" do
          expect(new_date).to eq copy_assignment(time_zone: local_time_zone)
          expect(@copy_to.start_at.utc).to eq Time.zone.parse("2012-12-01 07:00:00 UTC")
          expect(@copy_to.conclude_at.utc).to eq Time.zone.parse("2012-12-15 07:00:00 UTC")
        end

        it "using the account time zone" do
          expect(new_date).to eq copy_assignment(account_time_zone: local_time_zone)
          expect(@copy_to.start_at.utc).to eq Time.zone.parse("2012-12-01 07:00:00 UTC")
          expect(@copy_to.conclude_at.utc).to eq Time.zone.parse("2012-12-15 07:00:00 UTC")
        end
      end

      context "when parsing dates with times" do
        context "from MST to MDT" do
          let(:old_date) { local_time_zone.local(2012, 1, 6, 12, 0) } # 6 Jan 2012 12:00
          let(:new_date) { local_time_zone.local(2012, 4, 6, 12, 0) } # 6 Apr 2012 12:00
          let(:old_start_date) { "2012-01-01T01:00:00" }
          let(:old_end_date) { "2012-01-15T01:00:00" }
          let(:new_start_date) { "2012-04-01T01:00:00" }
          let(:new_end_date) { "2012-04-15T01:00:00" }

          it "using an explicit time zone" do
            expect(new_date).to eq copy_assignment(time_zone: local_time_zone)
            expect(@copy_to.start_at.utc).to eq Time.zone.parse("2012-04-01 07:00:00 UTC")
            expect(@copy_to.conclude_at.utc).to eq Time.zone.parse("2012-04-15 07:00:00 UTC")
          end

          it "using the account time zone" do
            expect(new_date).to eq copy_assignment(account_time_zone: local_time_zone)
            expect(@copy_to.start_at.utc).to eq Time.zone.parse("2012-04-01 07:00:00 UTC")
            expect(@copy_to.conclude_at.utc).to eq Time.zone.parse("2012-04-15 07:00:00 UTC")
          end
        end

        context "when MDT to MST" do
          let(:old_date) { local_time_zone.local(2012, 9, 6, 12, 0) } # 6 Sep 2012 12:00
          let(:new_date) { local_time_zone.local(2012, 12, 6, 12, 0) } # 6 Dec 2012 12:00
          let(:old_start_date) { "2012-09-01T01:00:00" }
          let(:old_end_date) { "2012-09-15T01:00:00" }
          let(:new_start_date) { "2012-12-01T01:00:00" }
          let(:new_end_date) { "2012-12-15T01:00:00" }

          it "using an explicit time zone" do
            expect(new_date).to eq copy_assignment(time_zone: local_time_zone)
            expect(@copy_to.start_at.utc).to eq Time.zone.parse("2012-12-01 08:00:00 UTC")
            expect(@copy_to.conclude_at.utc).to eq Time.zone.parse("2012-12-15 08:00:00 UTC")
          end

          it "using the account time zone" do
            expect(new_date).to eq copy_assignment(account_time_zone: local_time_zone)
            expect(@copy_to.start_at.utc).to eq Time.zone.parse("2012-12-01 08:00:00 UTC")
            expect(@copy_to.conclude_at.utc).to eq Time.zone.parse("2012-12-15 08:00:00 UTC")
          end
        end

        context "with UTC date_shift parameters" do
          let(:old_date) { local_time_zone.local(2012, 9, 6, 12, 0) } # 6 Sep 2012 12:00
          let(:new_date) { local_time_zone.local(2012, 12, 6, 12, 0) } # 6 Dec 2012 12:00
          let(:old_start_date) { "2012-09-01T08:00:00Z" }
          let(:old_end_date) { "2012-09-15T08:00:00Z" }
          let(:new_start_date) { "2012-12-01T08:00:00Z" }
          let(:new_end_date) { "2012-12-15T08:00:00Z" }

          it "using an explicit time zone" do
            expect(new_date).to eq copy_assignment(time_zone: local_time_zone)
            expect(@copy_to.start_at.utc).to eq Time.zone.parse("2012-12-01 08:00:00 UTC")
            expect(@copy_to.conclude_at.utc).to eq Time.zone.parse("2012-12-15 08:00:00 UTC")
          end

          it "using the account time zone" do
            expect(new_date).to eq copy_assignment(account_time_zone: local_time_zone)
            expect(@copy_to.start_at.utc).to eq Time.zone.parse("2012-12-01 08:00:00 UTC")
            expect(@copy_to.conclude_at.utc).to eq Time.zone.parse("2012-12-15 08:00:00 UTC")
          end
        end

        context "implicit start date" do
          let(:old_date) { DateTime.new(2021, 3, 3) }
          let(:old_start_date) { nil }
          let(:old_end_date) { nil }
          let(:new_start_date) { nil }
          let(:new_end_date) { "2021-01-01T00:00:00Z" }

          it "doesn't implicitly set course dates based on assignment dates" do
            expect { copy_assignment }.not_to raise_error
            expect(@copy_to.start_at).to be_nil
          end
        end
      end
    end

    it "performs day substitutions" do
      skip unless Qti.qti_enabled?
      @copy_from.require_assignment_group
      today = Time.now.utc
      asmnt = @copy_from.assignments.build
      asmnt.due_at = today
      asmnt.workflow_state = "published"
      asmnt.save!
      @copy_from.reload

      @cm.copy_options = @cm.copy_options.merge(
        shift_dates: true,
        day_substitutions: { today.wday.to_s => (today.wday + 1).to_s }
      )
      @cm.save!

      run_course_copy

      new_assignment = @copy_to.assignments.first
      # new_assignment.due_at.should == today + 1.day does not work
      expect(new_assignment.due_at.to_i).not_to eq asmnt.due_at.to_i
      expect((new_assignment.due_at.to_i - (today + 1.day).to_i).abs).to be < 60
    end

    it "copies all day dates for assignments and events correctly" do
      date = "Jun 21 2012 11:59pm"
      date2 = "Jun 21 2012 00:00am"
      asmnt = @copy_from.assignments.create!(title: "all day", due_at: date)
      expect(asmnt.all_day).to be_truthy

      cal = nil
      Time.use_zone("America/Denver") do
        cal = @copy_from.calendar_events.create!(title: "haha", description: "oi", start_at: date2, end_at: date2)
        expect(cal.start_at.strftime("%H:%M")).to eq "00:00"
      end

      Time.use_zone("UTC") do
        run_course_copy
      end

      asmnt_2 = @copy_to.assignments.where(migration_id: mig_id(asmnt)).first
      expect(asmnt_2.all_day).to be_truthy
      expect(asmnt_2.due_at.strftime("%H:%M")).to eq "23:59"
      expect(asmnt_2.all_day_date).to eq Date.parse("Jun 21 2012")

      cal_2 = @copy_to.calendar_events.where(migration_id: mig_id(cal)).first
      expect(cal_2.all_day).to be_truthy
      expect(cal_2.all_day_date).to eq Date.parse("Jun 21 2012")
      expect(cal_2.start_at.utc).to eq cal.start_at.utc
    end

    it "does not clear destination course dates" do
      start_at = 1.day.ago
      conclude_at = 2.days.from_now
      @copy_to.start_at = start_at
      @copy_to.conclude_at = conclude_at
      @copy_to.save!
      options = {
        everything: true,
        remove_dates: true,
      }
      @cm.copy_options = options
      @cm.save!

      run_course_copy

      @copy_to.reload
      expect(@copy_to.start_at).to eq start_at
      expect(@copy_to.conclude_at).to eq conclude_at
    end

    it "does not break link resolution in quiz_data" do
      skip "Requires QtiMigrationTool" unless Qti.qti_enabled?

      topic = @copy_from.discussion_topics.create!(title: "some topic", message: "<p>some text</p>")

      html = "<a href='/courses/#{@copy_from.id}/discussion_topics/#{topic.id}'>link</a>"

      bank = @copy_from.assessment_question_banks.create!(title: "bank")
      data = { question_name: "test question", question_type: "essay_question", question_text: html }
      bank.assessment_questions.create!(question_data: data)

      quiz = @copy_from.quizzes.create!(due_at: "05 Jul 2012 06:00:00 UTC +00:00")
      quiz.quiz_questions.create!(question_data: data)
      quiz.generate_quiz_data
      quiz.published_at = Time.zone.now
      quiz.workflow_state = "available"
      quiz.save!

      options = {
        everything: true,
        shift_dates: true,
        old_start_date: "Jul 1, 2012",
        old_end_date: "Jul 11, 2012",
        new_start_date: "Aug 5, 2012",
        new_end_date: "Aug 15, 2012"
      }
      @cm.copy_options = options
      @cm.save!

      run_course_copy

      topic_to = @copy_to.discussion_topics.where(migration_id: mig_id(topic)).first
      quiz_to = @copy_to.quizzes.where(migration_id: mig_id(quiz)).first
      data = quiz_to.quiz_data.to_yaml
      expect(data).not_to include("LINK.PLACEHOLDER")
      expect(data).to include("courses/#{@copy_to.id}/discussion_topics/#{topic_to.id}")
    end

    it "works on all_day calendar events" do
      @old_start = Time.zone.parse("01 Jul 2012 06:00:00 UTC +00:00")
      @new_start = Time.zone.parse("05 Aug 2012 06:00:00 UTC +00:00")

      all_day_event = @copy_from.calendar_events.create!(title: "an event",
                                                         start_at: @old_start + 4.days,
                                                         all_day: true)

      options = {
        everything: true,
        shift_dates: true,
        old_start_date: "Jul 1, 2012",
        old_end_date: "Jul 11, 2012",
        new_start_date: "Aug 5, 2012",
        new_end_date: "Aug 15, 2012"
      }
      @cm.copy_options = options
      @cm.save!

      Account.default.tap do |a|
        a.default_time_zone = "America/Denver"
        a.save!
      end
      run_course_copy

      new_event = @copy_to.calendar_events.where(migration_id: mig_id(all_day_event)).first
      expect(new_event.all_day?).to be_truthy
      expect(new_event.all_day_date).to eq (@new_start + 4.days).to_date
    end

    it "removes dates for all-day events" do
      @old_start = Time.zone.parse("01 Jul 2012 06:00:00 UTC +00:00")

      all_day_event = @copy_from.calendar_events.create!(title: "an event",
                                                         start_at: @old_start + 4.days,
                                                         all_day: true)

      options = {
        everything: true,
        remove_dates: true
      }
      @cm.copy_options = options
      @cm.save!

      run_course_copy

      new_event = @copy_to.calendar_events.where(migration_id: mig_id(all_day_event)).first
      expect(new_event.all_day?).to be_truthy
      expect(new_event.all_day_date).to be_nil
    end

    it "triggers cached_due_date changes" do
      assmt = @copy_from.assignments.create!(title: "an event", due_at: 1.day.from_now)

      run_course_copy

      assmt_to = @copy_to.assignments.where(migration_id: mig_id(assmt)).first
      student_in_course(active_all: true, course: @copy_to)
      sub_to = assmt_to.reload.submissions.first
      expect(sub_to.cached_due_date.to_i).to eq assmt.due_at.to_i

      opts = {
        everything: true,
        shift_dates: true,
        old_start_date: 1.week.ago.to_date,
        old_end_date: 1.week.from_now.to_date,
        new_start_date: 2.weeks.from_now.to_date,
        new_end_date: 4.weeks.from_now.to_date
      }
      @cm.copy_options = opts
      @cm.save!

      run_course_copy

      expect(assmt_to.reload.due_at.to_i).to_not eq assmt.due_at.to_i # shifted the date on the assignment
      expect(sub_to.reload.cached_due_date.to_i).to_not eq assmt.due_at.to_i # shifted the cached date too
    end
  end
end
