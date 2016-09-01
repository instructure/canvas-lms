module Api::V1
  module GradebookHistory
    include Api
    include Api::V1::Assignment
    include Api::V1::Submission

    def days_json(course, api_context)
      day_hash = Hash.new{|hash, date| hash[date] = {:graders => {}} }
      submissions_set(course, api_context).
        each_with_object(day_hash) { |submission, day| update_graders_hash(day[day_string_for(submission)][:graders], submission, api_context) }.
        each do |date, date_hash|
          compress(date_hash, :graders)
          date_hash[:graders].each { |grader| compress(grader, :assignments) }
        end

      day_hash.map { |date, hash| hash.merge(:date => date) }.sort_by { |a| a[:date] }.reverse
    end

    def json_for_date(date, course, api_context)
      submissions_set(course, api_context, :date => date).
        each_with_object({}) { |sub, memo| update_graders_hash(memo, sub, api_context) }.values.
        each { |grader| compress(grader, :assignments) }
    end

    def version_json(course, version, api_context, opts={})
      submission = opts[:submission] || version.versionable
      assignment = opts[:assignment] || submission.assignment
      student = opts[:student] || submission.user
      current_grader = submission.grader || default_grader

      model = version.model
      json = model.without_versioned_attachments do
        submission_attempt_json(model, assignment, api_context.user, api_context.session, course).with_indifferent_access
      end
      grader = (json[:grader_id] && json[:grader_id] > 0 && user_cache[json[:grader_id]]) || default_grader

      json = json.merge(
        :grader => grader.name,
        :assignment_name => assignment.title,
        :user_name => student.name,
        :current_grade => submission.grade,
        :current_graded_at => submission.graded_at,
        :current_grader => current_grader.name
      )
      json
    end

    def versions_json(course, versions, api_context, opts={})
      # preload for efficiency
      unless opts[:submission]
        ActiveRecord::Associations::Preloader.new.preload(versions, :versionable)
        submissions = versions.map(&:versionable)
        ActiveRecord::Associations::Preloader.new.preload(submissions, :assignment) unless opts[:assignment]
        ActiveRecord::Associations::Preloader.new.preload(submissions, :user) unless opts[:student]
        ActiveRecord::Associations::Preloader.new.preload(submissions, :grader)
        ::Submission.bulk_load_versioned_attachments(versions.map(&:model))
      end

      versions.map do |version|
        submission = opts[:submission] || version.versionable
        assignment = opts[:assignment] || submission.assignment
        student = opts[:student] || submission.user
        version_json(course, version, api_context, :submission => submission, :assignment => assignment, :student => student)
      end
    end

    def submissions_for(course, api_context, date, grader_id, assignment_id)
      assignment = ::Assignment.find(assignment_id)
      options = {:date => date, :assignment_id => assignment_id, :grader_id => grader_id}
      submissions = submissions_set(course, api_context, options)

      # load all versions for the given submissions and back-populate their
      # versionable associations
      submission_index = submissions.index_by(&:id)
      versions = Version.where(:versionable_type => 'Submission', :versionable_id => submissions).order(:number)
      versions.each{ |version| version.versionable = submission_index[version.versionable_id] }

      # convert them all to json and then group by submission
      versions = versions_json(course, versions, api_context, :assignment => assignment)
      versions_hash = versions.group_by{ |version| version[:id] }

      # populate previous_* and new_* keys and convert hash to array of objects
      versions_hash.inject([]) do |memo, (submission_id, submission_versions)|
        prior = HashWithIndifferentAccess.new
        filtered_versions = submission_versions.each_with_object([]) do |version, new_array|
          if version[:score]
            if prior[:id].nil? || prior[:score] != version[:score]
              if prior[:id].nil? || prior[:graded_at].nil? || version[:graded_at].nil?
                PREVIOUS_VERSION_ATTRS.each { |attr| version["previous_#{attr}".to_sym] = nil }
              elsif prior[:score] != version[:score]
                PREVIOUS_VERSION_ATTRS.each { |attr| version["previous_#{attr}".to_sym] = prior[attr] }
              end
              NEW_ATTRS.each { |attr| version["new_#{attr}".to_sym] = version[attr] }
              new_array << version
            end
          end
          prior.merge!(version.slice(:grade, :score, :graded_at, :grader, :id))
        end.reverse

        memo << { :submission_id => submission_id, :versions => filtered_versions }
      end
    end

    def day_string_for(submission)
      graded_at = submission.graded_at
      return '' if graded_at.nil?
      graded_at.in_time_zone.to_date.as_json
    end

    def submissions_set(course, api_context, options = {})
      collection = ::Submission.for_course(course).order("graded_at DESC")

      if options[:date]
        date = options[:date]
        collection = collection.where("graded_at<? AND graded_at>?", date.end_of_day, date.beginning_of_day)
      else
        collection = collection.where("graded_at IS NOT NULL")
      end

      if assignment_id = options[:assignment_id]
        collection = collection.where(assignment_id: assignment_id)
      end

      if grader_id = options[:grader_id]
        if grader_id.to_s == '0'
          # yes, this is crazy.  autograded submissions have the grader_id of (quiz_id x -1)
          collection = collection.where("submissions.grader_id<=0")
        else
          collection = collection.where(grader_id: grader_id)
        end
      end

      api_context.paginate(collection)
    end


    private

    PREVIOUS_VERSION_ATTRS = [:grade, :graded_at, :grader]
    NEW_ATTRS = [:grade, :graded_at, :grader, :score]

    DEFAULT_GRADER = Struct.new(:name, :id)

    def default_grader
      @default_grader ||= DEFAULT_GRADER.new(I18n.t('gradebooks.history.graded_on_submission', 'Graded on submission'), 0)
    end

    def user_cache
      @user_cache ||= Hash.new{ |hash, user_id| hash[user_id] = ::User.find(user_id) }
    end

    def assignment_cache
      @assignment_cache ||= Hash.new{ |hash, assignment_id| hash[assignment_id] = ::Assignment.find(assignment_id) }
    end

    def update_graders_hash(hash, submission, api_context)
      grader = submission.grader || default_grader
      hash[grader.id] ||= {
        :name => grader.name,
        :id => grader.id,
        :assignments => {}
      }

      hash[grader.id][:assignments][submission.assignment_id] ||= begin
        assignment = assignment_cache[submission.assignment_id]
        assignment_json(assignment, api_context.user, api_context.session)
      end
    end

    def compress(hash, key)
      hash[key] = hash[key].values
    end

  end
end
