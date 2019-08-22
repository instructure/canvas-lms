namespace :data do
  namespace :export do

    desc 'Extract project component scores out into a separate table'
    task :project_scores, [:course_id] => :environment do |t, args|

      admin = User.find 1
      scores_model_by_id = {
        56 => Course56ProjectScore,
        57 => Course57ProjectScore,
        58 => Course58ProjectScore,
        71 => Course71ProjectScore,
        73 => Course73ProjectScore
      }
      course_id = args[:course_id].to_i
      klass = scores_model_by_id[course_id]

      puts("Exporting data for Course #{course_id}")
      output = Export::GradeDownload.csv(admin, course_id: course_id)

      # we want to truncate and not just delete so that the ids start back at 1
      # the way Periscope syncing works means that old rows will get overwritten this
      # way so that we don't waste space
      ActiveRecord::Base.connection.execute("TRUNCATE #{klass.table_name}")
      puts("Transferring to database table")
      skip_row = true # skip the header
      CSV.parse(output) do |row|
        unless skip_row then
          colnames_minus_id = klass.column_names.delete('id')
          vals_by_colname = Hash[klass.column_names.zip row]
          klass.create!(vals_by_colname)
        end
        skip_row = false
      end
    end
  end
end
