define(['jsx/gradezilla/DataLoader', 'underscore'], (DataLoader, _) => {
  QUnit.module("Gradebook Data Loader", (hooks) => {
    let savedTrackEvent;
    let fakeXhr;
    let XHRS, XHR_HANDLERS, handlerIndex;

    const ASSIGNMENT_GROUPS = [{id: 1}, {id: 4}];
    const STUDENTS_PAGE_1 = [{id: 2}, {id: 5}];
    const STUDENTS_PAGE_2 = [{id: 3}, {id: 7}];
    const SUBMISSIONS_CHUNK_1 = [{id: 99}];
    const SUBMISSIONS_CHUNK_2 = [{id: 100}, {id: 101}];
    const CUSTOM_COLUMNS = [{id: 50}];

    hooks.beforeEach(() => {
       XHRS = [];
       handlerIndex = 0;
       fakeXhr = sinon.useFakeXMLHttpRequest();
       fakeXhr.onCreate = (xhr) => {
         XHRS.push(xhr);
         // this settimeout allows jquery to finish setting up the xhr
         // before we try to handle it
         setTimeout(() => {
           if (XHR_HANDLERS && typeof XHR_HANDLERS[handlerIndex] === "function") {
             XHR_HANDLERS[handlerIndex]();
           }
         });
       };

       // google analytics stuff :/
       savedTrackEvent = $.trackEvent;
       $.trackEvent = () => {};
    });

    hooks.afterEach(() => {
      fakeXhr.restore();
      XHR_HANDLERS = null;
      $.trackEvent = savedTrackEvent;
    });

    const callLoadGradebookData = (opts) => {
      opts = opts || {};
      const defaults = {
        assignmentGroupsURL: "/ags",
        assignmentGroupsParams: {ag_params: "ok"},
        customColumnsURL: "/customcols",
        studentsURL: "/students",
        studentsPageCb: () => {},
        studentsParams: {student_params: "whatever"},
        submissionsURL: "/submissions",
        submissionsParams: {submission_params: "blahblahblah"},
        submissionsChunkCb: () => {},
        submissionsChunkSize: 2,
        customColumnDataURL: "/customcols/:id/data",
        customColumnDataParams: {custom_column_data_params: "..."},
        customColumnDataPageCb: () => {},
      }

      return DataLoader.loadGradebookData({...defaults, ...opts});
    }

    const respondToXhr = (url, status, headers, response) => {
      const pendingXhrs = XHRS.filter(x => !x.status);
      const xhr = _.find(pendingXhrs, xhr => xhr.url === url);
      if (xhr) {
        xhr.respond(status, headers, JSON.stringify(response));
        handlerIndex++;
      }
    };

    QUnit.module("Assignment Groups");

    test("resolves promise with data when all groups are loaded", (assert) => {
      XHR_HANDLERS = [
        () => {
          respondToXhr("/ags?ag_params=ok",
                       200, {Link: ""}, ASSIGNMENT_GROUPS);
        },
      ];

      const dataLoader = callLoadGradebookData();
      const resolved = assert.async();

      dataLoader.gotAssignmentGroups.then((ags) => {
        ok(_.isEqual(ags, ASSIGNMENT_GROUPS));
        resolved();
      });
    });

    QUnit.module("Students and Submissions");

    test("resolves promise with data when all students are loaded", (assert) => {
      XHR_HANDLERS = [
        () => {
          respondToXhr("/students?student_params=whatever",
                       200, {Link: ""}, STUDENTS_PAGE_1);
        }
      ]

      const dataLoader = callLoadGradebookData();
      const resolved = assert.async();

      dataLoader.gotStudents.then((students) => {
        ok(_.isEqual(students, STUDENTS_PAGE_1));
        resolved();
      });
    });

    test("fires callback with each page of students", (assert) => {
      XHR_HANDLERS = [
        () => {
          respondToXhr("/students?student_params=whatever",
                       200,
                       {Link: '</students?page=2>; rel="last"'},
                       STUDENTS_PAGE_1)
        },
        () => {
          respondToXhr("/students?page=2&student_params=whatever",
                       200, {Link: ""}, STUDENTS_PAGE_2);
        }
      ];

      let pageCallbacksDone = assert.async();
      let promiseResolved = assert.async();

      let pageCbCalled = 0;
      const pages = [STUDENTS_PAGE_1, STUDENTS_PAGE_2];
      const pageCb = (students) => {
        pageCbCalled++;
        ok(_.isEqual(students, pages.shift()));
        if (pageCbCalled ===  2) {
          pageCallbacksDone();
        }
      };

      const dataLoader = callLoadGradebookData({studentsPageCb: pageCb});
      dataLoader.gotStudents.then((students) => {
        ok(pageCbCalled === 2, "callbacks fire before promise resolves");
        ok(_.isEqual(students, STUDENTS_PAGE_1.concat(STUDENTS_PAGE_2)), "promise returns all pages");
        promiseResolved();
      });
    });

    test("requests submissions as students are loading", (assert) => {
      const studentIdParam = (studentIds) => {
        return studentIds.reduce(
          (str, id) => str + "student_ids%5B%5D=" + id + "&",
          ""
        );
      };

      XHR_HANDLERS = [
        () => {
          respondToXhr("/students?student_params=whatever",
                       200,
                       {Link: '</students?page=2>; rel="last"'},
                       STUDENTS_PAGE_1)
        },
        () => {
          const studentIds = studentIdParam([2, 5]);
          respondToXhr(`/submissions?${studentIds}submission_params=blahblahblah`,
                       200, {}, SUBMISSIONS_CHUNK_1)
        },
        () => {
          respondToXhr("/students?page=2&student_params=whatever",
                       200, {Link: ""}, STUDENTS_PAGE_2);
        },
        () => {
          const studentIds = studentIdParam([3, 7]);
          respondToXhr(`/submissions?${studentIds}submission_params=blahblahblah`,
                       200, {}, SUBMISSIONS_CHUNK_2)
        },
      ];

      const studentsDone = assert.async();
      const submissionsDone = assert.async();

      let studentsCbCalled = 0;
      let submissionsCbCalled = 0;

      const submissionPages = [SUBMISSIONS_CHUNK_1, SUBMISSIONS_CHUNK_2];

      const studentsCb = () => studentsCbCalled++;
      const submissionsCb = (submissions) => {
        submissionsCbCalled++;
        ok(_.isEqual(submissionPages.shift(), submissions));
        ok(studentsCbCalled === submissionsCbCalled,
           "submissions are queued for for each page of students");
      };

      const dataLoader = callLoadGradebookData({
        studentsPageCb: studentsCb,
        submissionsChunkCb: submissionsCb,
      });
      dataLoader.gotStudents.then(studentsDone);
      dataLoader.gotSubmissions.then(() => {
        ok(dataLoader.gotStudents.isResolved(),
           "students finish loading first");
        ok(submissionsCbCalled === 2);
        submissionsDone();
      });
    });

    QUnit.module("Custom Column Data");

    test("resolves promise with custom columns", (assert) => {
      XHR_HANDLERS = [
        () =>{
          respondToXhr("/customcols", 200, {}, CUSTOM_COLUMNS);
        },
      ];

      const resolved = assert.async();
      const dataLoader = callLoadGradebookData();
      dataLoader.gotCustomColumns.then((cols) => {
        ok(_.isEqual(cols, CUSTOM_COLUMNS));
        resolved();
      });
    });

    test("doesn't fetch custom column data until all other data is done", (assert) => {
      XHR_HANDLERS = [
        () => {
          respondToXhr("/customcols", 200, {}, CUSTOM_COLUMNS);
        },
      ];

      const done = assert.async();
      const dataLoader = callLoadGradebookData();
      dataLoader.gotCustomColumns.then(() => {
        ok(XHRS.filter(xhr => xhr.url.match(/data/)).length === 0,
           "custom columns for other data to finish");

        dataLoader.gotSubmissions.resolve();
        setTimeout(() => {
          ok(XHRS.filter(xhr => xhr.url.match(/data/)).length === 1);
          done();
        });
      });
    });
  });
});
