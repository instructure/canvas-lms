
require 'spec_helper'

describe RuboCop::Canvas::Comments do
  it "picks out which comments are applicable" do
    output = TWO_FILE_OFFENSE_OUTPUT
    diff = {
      'app/controllers/quizzes/quizzes_controller.rb' => [(1..3), (200..250)],
      'app/controllers/application_controller.rb' => [(80..110)]
    }
    parsed_diff = ::RuboCop::Canvas::DiffParser.new(diff, false)
    comments = described_class.new(parsed_diff)
    results = comments.on_output(output)
    expected = [{
        path: "app/controllers/application_controller.rb",
        position: 100,
        message: "Class definition is too long. [748/100]",
        severity: "info"
    }]
    expect(results).to eq(expected)
  end

  it "integrates a real dataset and makes legitimate comments" do
    # rubocop:disable all
    raw_diff = %Q{
      commit cd4249a9bbc70ce0d7f767b137ca15671d34a277
Author: Ethan Vizitei <evizitei@instructure.com>
Date:   Mon Apr 6 19:50:34 2015 -0600

    Line too long

    Change-Id: I0aa8af857501ae3fbc21366f742ea014cbcd2564

diff --git a/app/helpers/calendars_helper.rb b/app/helpers/calendars_helper.rb
index 00f8cde..087ac4a 100644
--- a/app/helpers/calendars_helper.rb
+++ b/app/helpers/calendars_helper.rb
@@ -18,7 +18,7 @@

 module CalendarsHelper
   def pastel_color_index(idx)
-    colors = ['#c0deca', '#f8ca35', '#d8dec0', '#b6b6b6', '#b3d1d1', '#cde5ab', '#c8b3d1', '#d1beb3', '#bfafaf', '#ddac81', '#d5d5d5', '#d49abe', '#c1ee82', '#98cbd1', '#b7b29c']
+    colors = ['#c0deca', '#f8ca35', '#d8dec0', '#b6b6b6', '#b3d1d1', '#cde5ab', '#c8b3d1', '#d1beb3', '#bfafaf', '#ddac81', '#d5d5d5', '#d49abe', '#c1ee82', '#98cbd1', '#b7b29c', 'Make a long line longer']
     colors[idx % colors.length]
   end
    }
    # rubocop:enable all

    parsed_rubocop_output = LARGE_OFFENSE_LIST
    diff = ::RuboCop::Canvas::DiffParser.new(raw_diff)
    comments = described_class.new(diff)
    results = comments.on_output(parsed_rubocop_output)
    expect(results.length).to eq(3)
  end


  # rubocop:disable all
  LARGE_OFFENSE_LIST = {
    "files"=>[
      {
        "path"=>"app/helpers/calendars_helper.rb",
        "offenses"=>
        [
          {
            "severity"=>"convention",
            "message"=>"Missing top-level module documentation comment.",
            "cop_name"=>"Style/Documentation",
            "corrected"=>nil,
            "location"=>{"line"=>19, "column"=>1, "length"=>6}
          },{
            "severity"=>"convention",
            "message"=>"Line is too long. [178/80]",
            "cop_name"=>"Metrics/LineLength",
            "corrected"=>nil,
            "location"=>{"line"=>21, "column"=>81, "length"=>98}
          },{
            "severity"=>"convention",
            "message"=>"Trailing whitespace detected.",
            "cop_name"=>"Style/TrailingWhitespace",
            "corrected"=>false,
            "location"=>{"line"=>24, "column"=>1, "length"=>2}
          },{
            "severity"=>"convention",
            "message"=>"Trailing whitespace detected.",
            "cop_name"=>"Style/TrailingWhitespace",
            "corrected"=>false,
            "location"=>{"line"=>28, "column"=>1, "length"=>2}
          },{
            "severity"=>"convention",
            "message"=>"Trailing whitespace detected.",
            "cop_name"=>"Style/TrailingWhitespace",
            "corrected"=>false,
            "location"=>{"line"=>32, "column"=>1, "length"=>2}
          }
        ]
      }
    ]
  }

  TWO_FILE_OFFENSE_OUTPUT = {
    "metadata" => { "rubocop_version" => "0.30.0" },
    "files" => [
      {
        "path" => "app/controllers/quizzes/quizzes_controller.rb","offenses" =>
          [{"severity" => "convention","message" => "Class definition is too long. [748/100]",
          "cop_name" => "Metrics/ClassLength","corrected" =>nil,"location"=>{"line"=>19,"column"=>1,"length"=>5}}]
      },
      {
        "path"=>"app/controllers/application_controller.rb","offenses"=>
          [{"severity"=>"convention","message"=>"Class definition is too long. [748/100]",
          "cop_name"=>"Metrics/ClassLength","corrected" => nil,"location"=>{"line"=>100,"column"=>1,"length"=>5}}]
      }
    ]
  }
  # rubocop:enable all
end
