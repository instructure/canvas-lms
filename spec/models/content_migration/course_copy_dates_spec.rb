require File.expand_path(File.dirname(__FILE__) + '/course_copy_helper.rb')

describe ContentMigration do
  context "course copy dates" do
    include_examples "course copy"

    describe "date shifting" do
      before :once do
        @old_start = DateTime.parse("01 Jul 2012 06:00:00 UTC +00:00")
        @new_start = DateTime.parse("05 Aug 2012 06:00:00 UTC +00:00")

        @copy_from.require_assignment_group
        @copy_from.assignments.create!(:due_at => @old_start + 1.day,
                                       :unlock_at => @old_start + 2.days,
                                       :lock_at => @old_start + 3.days,
                                       :peer_reviews_due_at => @old_start + 4.days
        )
        @copy_from.quizzes.create!(:due_at => "05 Jul 2012 06:00:00 UTC +00:00",
                                   :unlock_at => @old_start + 1.days,
                                   :lock_at => @old_start + 5.days,
                                   :show_correct_answers_at => @old_start + 6.days,
                                   :hide_correct_answers_at => @old_start + 7.days
        )
        @copy_from.discussion_topics.create!(:title => "some topic",
                                             :message => "<p>some text</p>",
                                             :delayed_post_at => @old_start + 3.days)
        @copy_from.announcements.create!(:title => "hear ye",
                                         :message => "<p>grades will henceforth be in Cyrillic letters</p>",
                                         :delayed_post_at => @old_start + 10.days)
        @copy_from.calendar_events.create!(:title => "an event",
                                           :start_at => @old_start + 4.days,
                                           :end_at => @old_start + 4.days + 1.hour)
        cm = @copy_from.context_modules.build(:name => "some module", :unlock_at => @old_start + 1.days)
        cm.start_at = @old_start + 2.day
        cm.end_at = @old_start + 3.days
        cm.save!
      end

      it "should shift dates" do
        pending unless Qti.qti_enabled?
        options = {
                :everything => true,
                :shift_dates => true,
                :old_start_date => 'Jul 1, 2012',
                :old_end_date => 'Jul 11, 2012',
                :new_start_date => 'Aug 5, 2012',
                :new_end_date => 'Aug 15, 2012'
        }
        @cm.copy_options = options
        @cm.save!

        run_course_copy

        new_asmnt = @copy_to.assignments.first
        new_asmnt.due_at.to_i.should  == (@new_start + 1.day).to_i
        new_asmnt.unlock_at.to_i.should == (@new_start + 2.day).to_i
        new_asmnt.lock_at.to_i.should == (@new_start + 3.day).to_i
        new_asmnt.peer_reviews_due_at.to_i.should == (@new_start + 4.day).to_i

        new_quiz = @copy_to.quizzes.first
        new_quiz.due_at.to_i.should  == (@new_start + 4.day).to_i
        new_quiz.unlock_at.to_i.should == (@new_start + 1.day).to_i
        new_quiz.lock_at.to_i.should == (@new_start + 5.day).to_i
        new_quiz.show_correct_answers_at.to_i.should == (@new_start + 6.day).to_i
        new_quiz.hide_correct_answers_at.to_i.should == (@new_start + 7.day).to_i

        new_disc = @copy_to.discussion_topics.first
        new_disc.delayed_post_at.to_i.should == (@new_start + 3.day).to_i

        new_ann = @copy_to.announcements.first
        new_ann.delayed_post_at.to_i.should == (@new_start + 10.day).to_i

        new_event = @copy_to.calendar_events.first
        new_event.start_at.to_i.should == (@new_start + 4.day).to_i
        new_event.end_at.to_i.should == (@new_start + 4.day + 1.hour).to_i

        new_mod = @copy_to.context_modules.first
        new_mod.unlock_at.to_i.should  == (@new_start + 1.day).to_i
        new_mod.start_at.to_i.should == (@new_start + 2.day).to_i
        new_mod.end_at.to_i.should == (@new_start + 3.day).to_i
      end

      it "should remove dates" do
        pending unless Qti.qti_enabled?
        options = {
            :everything => true,
            :remove_dates => true,
        }
        @cm.copy_options = options
        @cm.save!

        run_course_copy

        new_asmnt = @copy_to.assignments.first
        new_asmnt.due_at.should be_nil
        new_asmnt.unlock_at.should be_nil
        new_asmnt.lock_at.should be_nil
        new_asmnt.peer_reviews_due_at.should be_nil

        new_quiz = @copy_to.quizzes.first
        new_quiz.due_at.should be_nil
        new_quiz.unlock_at.should be_nil
        new_quiz.lock_at.should be_nil
        new_quiz.show_correct_answers_at.should be_nil
        new_quiz.hide_correct_answers_at.should be_nil

        new_disc = @copy_to.discussion_topics.first
        new_disc.delayed_post_at.should be_nil

        new_ann = @copy_to.announcements.first
        new_ann.delayed_post_at.should be_nil

        new_event = @copy_to.calendar_events.first
        new_event.start_at.should be_nil
        new_event.end_at.should be_nil

        new_mod = @copy_to.context_modules.first
        new_mod.unlock_at.should be_nil
        new_mod.start_at.should be_nil
        new_mod.end_at.should be_nil
      end

      it "should not create broken assignments from unpublished quizzes in draft state" do
        @copy_to.enable_feature!(:draft_state)

        options = {
            :everything => true,
            :remove_dates => true,
        }
        @cm.copy_options = options
        @cm.save!

        run_course_copy

        @copy_to.assignments.count.should == 1
      end
    end

    context "should copy time correctly across daylight saving shift" do
      let(:local_time_zone) { ActiveSupport::TimeZone.new 'America/Denver' }

      def copy_assignment(options = {})
        account = @copy_to.account

        old_time_zone = account.default_time_zone
        account.default_time_zone = options.include?(:account_time_zone) ? options[:account_time_zone].name : 'UTC'
        account.save!

        Time.use_zone('UTC') do
          assignment = @copy_from.assignments.create! :title => 'Assignment', :due_at => old_date
          assignment.save!

          opts = {
                  :everything => true,
                  :shift_dates => true,
                  :old_start_date => old_start_date,
                  :old_end_date => old_end_date,
                  :new_start_date => new_start_date,
                  :new_end_date => new_end_date
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

      context "from MST to MDT" do
        let(:old_date)       { local_time_zone.local(2012, 1, 6, 12, 0) } # 6 Jan 2012 12:00
        let(:new_date)       { local_time_zone.local(2012, 4, 6, 12, 0) } # 6 Apr 2012 12:00
        let(:old_start_date) { 'Jan 1, 2012' }
        let(:old_end_date)   { 'Jan 15, 2012' }
        let(:new_start_date) { 'Apr 1, 2012' }
        let(:new_end_date)   { 'Apr 15, 2012' }

        it "using an explicit time zone" do
          new_date.should == copy_assignment(:time_zone => local_time_zone)
          @copy_to.start_at.utc.should == Time.parse('2012-04-01 06:00:00 UTC')
          @copy_to.conclude_at.utc.should == Time.parse('2012-04-15 06:00:00 UTC')
        end

        it "using the account time zone" do
          new_date.should == copy_assignment(:account_time_zone => local_time_zone)
          @copy_to.start_at.utc.should == Time.parse('2012-04-01 06:00:00 UTC')
          @copy_to.conclude_at.utc.should == Time.parse('2012-04-15 06:00:00 UTC')
        end
      end

      context "from MDT to MST" do
        let(:old_date)       { local_time_zone.local(2012, 9, 6, 12, 0) }  # 6 Sep 2012 12:00
        let(:new_date)       { local_time_zone.local(2012, 12, 6, 12, 0) } # 6 Dec 2012 12:00
        let(:old_start_date) { 'Sep 1, 2012' }
        let(:old_end_date)   { 'Sep 15, 2012' }
        let(:new_start_date) { 'Dec 1, 2012' }
        let(:new_end_date)   { 'Dec 15, 2012' }

        it "using an explicit time zone" do
          new_date.should == copy_assignment(:time_zone => local_time_zone)
          @copy_to.start_at.utc.should == Time.parse('2012-12-01 07:00:00 UTC')
          @copy_to.conclude_at.utc.should == Time.parse('2012-12-15 07:00:00 UTC')
        end

        it "using the account time zone" do
          new_date.should == copy_assignment(:account_time_zone => local_time_zone)
          @copy_to.start_at.utc.should == Time.parse('2012-12-01 07:00:00 UTC')
          @copy_to.conclude_at.utc.should == Time.parse('2012-12-15 07:00:00 UTC')
        end
      end

      context "parsing dates with times" do
        context "from MST to MDT" do
          let(:old_date)       { local_time_zone.local(2012, 1, 6, 12, 0) } # 6 Jan 2012 12:00
          let(:new_date)       { local_time_zone.local(2012, 4, 6, 12, 0) } # 6 Apr 2012 12:00
          let(:old_start_date) { '2012-01-01T01:00:00' }
          let(:old_end_date)   { '2012-01-15T01:00:00' }
          let(:new_start_date) { '2012-04-01T01:00:00' }
          let(:new_end_date)   { '2012-04-15T01:00:00' }

          it "using an explicit time zone" do
            new_date.should == copy_assignment(:time_zone => local_time_zone)
            @copy_to.start_at.utc.should == Time.parse('2012-04-01 07:00:00 UTC')
            @copy_to.conclude_at.utc.should == Time.parse('2012-04-15 07:00:00 UTC')
          end

          it "using the account time zone" do
            new_date.should == copy_assignment(:account_time_zone => local_time_zone)
            @copy_to.start_at.utc.should == Time.parse('2012-04-01 07:00:00 UTC')
            @copy_to.conclude_at.utc.should == Time.parse('2012-04-15 07:00:00 UTC')
          end
        end

        context "from MDT to MST" do
          let(:old_date)       { local_time_zone.local(2012, 9, 6, 12, 0) }  # 6 Sep 2012 12:00
          let(:new_date)       { local_time_zone.local(2012, 12, 6, 12, 0) } # 6 Dec 2012 12:00
          let(:old_start_date) { '2012-09-01T01:00:00' }
          let(:old_end_date)   { '2012-09-15T01:00:00' }
          let(:new_start_date) { '2012-12-01T01:00:00' }
          let(:new_end_date)   { '2012-12-15T01:00:00' }

          it "using an explicit time zone" do
            new_date.should == copy_assignment(:time_zone => local_time_zone)
            @copy_to.start_at.utc.should == Time.parse('2012-12-01 08:00:00 UTC')
            @copy_to.conclude_at.utc.should == Time.parse('2012-12-15 08:00:00 UTC')
          end

          it "using the account time zone" do
            new_date.should == copy_assignment(:account_time_zone => local_time_zone)
            @copy_to.start_at.utc.should == Time.parse('2012-12-01 08:00:00 UTC')
            @copy_to.conclude_at.utc.should == Time.parse('2012-12-15 08:00:00 UTC')
          end
        end
      end
    end

    it "should perform day substitutions" do
      pending unless Qti.qti_enabled?
      @copy_from.require_assignment_group
      today = Time.now.utc
      asmnt = @copy_from.assignments.build
      asmnt.due_at = today
      asmnt.workflow_state = 'published'
      asmnt.save!
      @copy_from.reload

      @cm.copy_options = @cm.copy_options.merge(
              :shift_dates => true,
              :day_substitutions => {today.wday.to_s => (today.wday + 1).to_s}
      )
      @cm.save!

      run_course_copy

      new_assignment = @copy_to.assignments.first
      # new_assignment.due_at.should == today + 1.day does not work
      new_assignment.due_at.to_i.should_not == asmnt.due_at.to_i
      (new_assignment.due_at.to_i - (today + 1.day).to_i).abs.should < 60
    end

    it "should correctly copy all day dates for assignments and events" do
      date = "Jun 21 2012 11:59pm"
      date2 = "Jun 21 2012 00:00am"
      asmnt = @copy_from.assignments.create!(:title => 'all day', :due_at => date)
      asmnt.all_day.should be_true

      cal = nil
      Time.use_zone('America/Denver') do
        cal = @copy_from.calendar_events.create!(:title => "haha", :description => "oi", :start_at => date2, :end_at => date2)
        cal.start_at.strftime("%H:%M").should == "00:00"
      end

      Time.use_zone('UTC') do
        run_course_copy
      end

      asmnt_2 = @copy_to.assignments.where(migration_id: mig_id(asmnt)).first
      asmnt_2.all_day.should be_true
      asmnt_2.due_at.strftime("%H:%M").should == "23:59"
      asmnt_2.all_day_date.should == Date.parse("Jun 21 2012")

      cal_2 = @copy_to.calendar_events.where(migration_id: mig_id(cal)).first
      cal_2.all_day.should be_true
      cal_2.all_day_date.should == Date.parse("Jun 21 2012")
      cal_2.start_at.utc.should == cal.start_at.utc
    end

  end
end
