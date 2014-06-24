class CourseDataController < ApplicationController
  before_filter :require_user
  include Common
  
  def base_dir
    "/usr/local/canvas/course-data"
  end

  def csv_separator
    ":::"
  end

  def csv_major_separator
    ":_:"
  end

  def sis_separator
    '-'
  end

  def search
    data_arr = []
    queries = []
    term = params[:term]
    queries = params[:query].to_s.downcase.split unless params[:query].nil?
    file_name = "#{base_dir}/#{term}/all.lst"
    if File.exists? file_name
      File.open(file_name).each_line do |line|
        course_data = line.split(csv_major_separator).last.split(csv_separator)
        # build the course hash from the split components
        course_hash = {
            :term => term,
            :name => course_data[0].to_s.upcase,
            :number => course_data[1],
            :section => course_data[2].to_s.upcase,
            :title => course_data[3]
        }
        course_hash[:key] = "#{course_hash[:term]}#{csv_separator}#{course_hash[:name]}#{csv_separator}#{course_hash[:number]}#{csv_separator}#{course_hash[:section]}".downcase << "#{csv_separator}#{course_hash[:title]}"
        course_hash[:sis_source_id] = "#{course_hash[:term]}#{sis_separator}#{course_hash[:name]}#{sis_separator}#{course_hash[:number]}#{sis_separator}#{course_hash[:section]}".downcase
        course_hash[:display] = "#{course_hash[:name]}#{course_hash[:number]} #{course_hash[:section]} - #{course_hash[:title]}"
        # search must match all query parameters (e.g. math, 150, d100)
        data_arr << course_hash if queries.all? { |word| line.include?(word)}
      end
    end

    respond_to do |format|
      format.json { render :json => data_arr }
    end
  end

end
