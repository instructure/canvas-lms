require 'net/http'
require 'rubygems'
require 'active_record'
require 'date'
require 'json'

@user = 'user@fireworks.boom'
@pass = 'password'
@host = 'fireworks.boom'
@port = '3456'
@post_ws = "/data/workspaces"

def build_data

  dir = Dir.pwd
  data = "trends.log"

  File.open("#{dir}/parallel_log/#{data}", 'r') do |f|
    f.each_line do |line|
      if line != nil
        values = line.split("*").to_a
        spec_file = values[0]
        spec_name = values[1]
        date = values[2]
        status = values[3]
        time = values[4]
        stack_trace = values[5]
        spec_context = values[6]
        hudson_build_number = values[7]
        hudson_build_name = values[8]
        gerrit_project = values[9]
        git_commit_change_id = values[10]
        commit_patchset_number = values[11]
        build_owner = values[12]

        @all_specs ||= { :build_details => { :hudson_build_number => hudson_build_number, :hudson_build_name => hudson_build_name,
                         :gerrit_project => gerrit_project, :git_commit_change_id => git_commit_change_id,
                         :commit_patchset_number => commit_patchset_number, :build_owner => build_owner }
                       }

        @all_specs[spec_name] = { :spec_file => spec_file,
                                  :date => date,
                                  :status => status,
                                  :time => time,
                                  :stack_trace => stack_trace,
                                  :spec_context => spec_context,
                                  :hudson_build => hudson_build_number,
                                }
      end
    end
  end
  @payload = @all_specs.to_json
end

def post
  req = Net::HTTP::Post.new(@post_ws, initheader = {'Content-Type' =>'application/json'})
  req.basic_auth @user, @pass
  req.body = @payload
  response = Net::HTTP.new(@host, @port).start {|http| http.request(req) }
  puts "Response #{response.code} #{response.message}:
          #{response.body}"
end

build_data
thepost = post
puts thepost
