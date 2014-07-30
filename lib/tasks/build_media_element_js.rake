
desc "Builds mediaelementjs from it's git repo into a form canvas_lms can use with AMD and inject instructure-specific customizations"
task :build_media_element_js do
  require 'fileutils'

  def remove_console(text)
    text.gsub(/console.(log|debug)\((.*)\);?/, '')
  end

  repo_path = '../mediaelement'
  public_path = 'public'
  repo_location = "https://github.com/johndyer/mediaelement.git"

  unless File.exists? repo_path
    puts "cloning repo"
    `git clone #{repo_location} #{repo_path}`
  end

  git_revision = `git --git-dir=#{repo_path}/.git rev-parse HEAD`
  rev_msg = "/*
    Built by: #{File.basename(__FILE__)}
    from #{repo_location}
    revision: #{git_revision}
    YOU SHOULDN'T EDIT ME DIRECTLY
  */
  "

  puts  'building MediaElement.js'
  me_files = [
    'me-header.js',
    'me-namespace.js',
    'me-utility.js',
    'me-plugindetector.js',
    'me-featuredetection.js',
    'me-mediaelements.js',
    'me-shim.js',
    'me-i18n.js'
  ]
  me_chunks = me_files.map { |file| File.read "#{repo_path}/src/js/#{file}" }

  puts 'building MediaElementPlayer.js'
  mep_files = [
    'mep-header.js',
    'mep-library.js',
    'mep-player.js',
    'mep-feature-playpause.js',
    'mep-feature-stop.js',
    'mep-feature-progress.js',
    'mep-feature-time.js',
    'mep-feature-volume.js',
    'mep-feature-fullscreen.js',
    'public/javascripts/mediaelement/mep-feature-tracks-instructure.js',
    # 'mep-feature-contextmenu.js',
    # 'mep-feature-sourcechooser.js',
    'mep-feature-googleanalytics.js'
  ]
  mep_chunks = mep_files.map { |path|
    resolved_path = (path.include? '/') ? path : "#{repo_path}/src/js/#{path}"
    File.read resolved_path
  }

  puts "Combining scripts"

  chunks = [rev_msg, "define(['jquery'], function (jQuery){"] + me_chunks + mep_chunks + ["return mejs;\n});\n"]
  File.open("#{public_path}/javascripts/vendor/mediaelement-and-player.js", 'w') {|f|
    f.write(remove_console(chunks.join("\n")))
  }

  puts "Copying CSS"
  css = File.read "#{repo_path}/src/css/mediaelementplayer.css"
  # fix urls to background images
  css = css.gsub('url(', 'url(/images/mediaelement/')
  File.open("app/stylesheets/vendor/_mediaelementplayer.scss", 'w') {|f| f.write(rev_msg + css) }

  puts 'Copying Skin Files'
  img_path = "#{public_path}/images/mediaelement"
  FileUtils.mkdir_p img_path
  [ 'src/css/controls.png',
    'src/css/controls.svg',
    'src/css/bigplay.png',
    'src/css/bigplay.svg',
    'src/css/loading.gif',
    'build/flashmediaelement.swf',
    'build/silverlightmediaelement.xap'
  ].each { |file| FileUtils.cp "#{repo_path}/#{file}", img_path }

  puts 'DONE!'
end
