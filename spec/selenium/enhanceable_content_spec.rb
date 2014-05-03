require File.expand_path(File.dirname(__FILE__) + '/common')

describe "enhanceable_content" do
  include_examples "in-process server selenium tests"

  it "should automatically enhance content using jQuery UI" do
    stub_kaltura
    course_with_teacher_logged_in

    page = @course.wiki.front_page
    page.body = %{
      <div id="dialog_for_link1" class="enhanceable_content dialog">dialog for link 1</div>
      <a href="#dialog_for_link1" id="link1">link 1</a>

      <div class="enhanceable_content draggable" style="width: 100px;">draggable</div>

      <div class="enhanceable_content resizable" style="width: 100px;">resizable</div>

      <ul class="enhanceable_content sortable" style="display: none;">
        <li>item 1</li>
        <li>item 2</li>
      </ul>

      <div class="enhanceable_content accordion">
        <h3><a href="#">Section 1</a></h3>
        <div>
          <p>
            Section 1 Content
          </p>
        </div>
        <h3><a href="#">Section 2</a></h3>
        <div>
          <p>
            Section 2 Content
          </p>
        </div>
        <h3><a href="#">Section 3</a></h3>
        <div>
          <p>
            Section 3 Content
          </p>
          <ul>
            <li>List item one</li>
            <li>List item two</li>
            <li>List item three</li>
          </ul>
        </div>
      </div>

      <div class="enhanceable_content tabs">
        <ul>
            <li><a href="#fragment-1"><span>One</span></a></li>
            <li><a href="#fragment-2"><span>Two</span></a></li>
            <li><a href="#fragment-3"><span>Three</span></a></li>
        </ul>
        <div id="fragment-1">
            <p>First tab is active by default:</p>
            <pre><code>$('#example').tabs();</code></pre>
        </div>
        <div id="fragment-2">
            Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.
        </div>
        <div id="fragment-3">
            Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.
        </div>
      </div>

      <a id="media_comment_0_deadbeef" class="instructure_file_link instructure_video_link" title="Video.mp4" href="/courses/1/files/1/download?wrap=1">Video</a>
    }
    page.save!

    get "/courses/#{@course.id}/wiki/#{page.url}"

    dialog = f(".enhanceable_content.dialog")

    # need to wait for the content to get enhanced (it happens in instructure.js in a setTimeout of 1000 ms)
    keep_trying_until {
      f("#link1").click
      dialog.should be_displayed
      dialog.should have_class('ui-dialog')
    }
    f(".ui-dialog .ui-dialog-titlebar-close").click
    dialog.should_not be_displayed

    f(".enhanceable_content.draggable").should have_class('ui-draggable')
    f(".enhanceable_content.resizable").should have_class('ui-resizable')

    ul = f(".enhanceable_content.sortable")
    ul.should be_displayed
    ul.should have_class('ui-sortable')

    accordion = f(".enhanceable_content.accordion")
    accordion.should have_class('ui-accordion')
    headers = accordion.find_elements(:css, ".ui-accordion-header")
    headers.length.should == 3
    divs = accordion.find_elements(:css, ".ui-accordion-content")
    divs.length.should == 3
    headers[0].should have_class('ui-state-active')
    divs[0].should be_displayed
    divs[1].should_not be_displayed
    headers[1].click
    wait_for_ajaximations
    headers[0].should have_class('ui-state-default')
    headers[1].should have_class('ui-state-active')
    divs[0].should_not be_displayed
    divs[1].should be_displayed


    tabs = f(".enhanceable_content.tabs")
    tabs.should have_class('ui-tabs')
    headers = tabs.find_elements(:css, ".ui-tabs-nav li")
    headers.length.should == 3
    divs = tabs.find_elements(:css, ".ui-tabs-panel")
    divs.length.should == 3
    headers[0].should have_class('ui-state-active')
    headers[1].should have_class('ui-state-default')
    divs[0].should be_displayed
    divs[1].should_not be_displayed

    f('#media_comment_0_deadbeef span.media_comment_thumbnail').should_not be_nil
  end
end

