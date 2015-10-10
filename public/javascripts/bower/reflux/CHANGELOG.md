# Changelog

Check for latest changes on the [milestones page](https://github.com/spoike/refluxjs/milestones).

## v0.2.7

* Fixed IE8 errors and warnings [#286](https://github.com/spoike/refluxjs/pull/286), [#270](https://github.com/spoike/refluxjs/pull/270)
* Ensure triggerPromise original promise [#229](https://github.com/spoike/refluxjs/pull/229)
* Fixed aborted callbacks [#227](https://github.com/spoike/refluxjs/pull/227)

## v0.2.6

* Fixed catch call in Promises [#267](https://github.com/spoike/refluxjs/pull/267)
* Promise and EventEmitter is now properly exported [#258](https://github.com/spoike/refluxjs/pull/258), [#253](https://github.com/spoike/refluxjs/pull/253)
* Getters in stores were accidentally invoked [#231](https://github.com/spoike/refluxjs/pull/231), [#230](https://github.com/spoike/refluxjs/pull/230)
* Asynchronous actions will now return promises [#223](https://github.com/spoike/refluxjs/pull/223), [#216](https://github.com/spoike/refluxjs/issues/216), [#259](https://github.com/spoike/refluxjs/issues/259)
* `dist` folder is now available again in npm package [#266](https://github.com/spoike/refluxjs/pull/266)
* Fixes to README file [#260](https://github.com/spoike/refluxjs/pull/260), [#247](https://github.com/spoike/refluxjs/pull/247), [#244](https://github.com/spoike/refluxjs/pull/244), [#240](https://github.com/spoike/refluxjs/pull/240), [#236](https://github.com/spoike/refluxjs/pull/236), [#235](https://github.com/spoike/refluxjs/pull/235), [#234](https://github.com/spoike/refluxjs/pull/234)

## v0.2.5

* Added `connectFilter` [#222](https://github.com/spoike/refluxjs/pull/222)
* A lot of clarifications and typo fixes in documentation. [#147](https://github.com/spoike/refluxjs/pull/147), [#207](https://github.com/spoike/refluxjs/pull/207), [#208](https://github.com/spoike/refluxjs/pull/208), [#209](https://github.com/spoike/refluxjs/pull/209), [#211](https://github.com/spoike/refluxjs/pull/211), and [#214](https://github.com/spoike/refluxjs/pull/214)

## v0.2.4

* Promisable actions [#185](https://github.com/spoike/refluxjs/issues/185)
* Fixed IE8 bug [#202](https://github.com/spoike/refluxjs/issues/202), [#187](https://github.com/spoike/refluxjs/issues/187)
* Plus other various fixes: [#201](https://github.com/spoike/refluxjs/issues/201), [#200](https://github.com/spoike/refluxjs/issues/202), [#183](https://github.com/spoike/refluxjs/issues/183), and [#182](https://github.com/spoike/refluxjs/issues/182)

## v0.2.3

* Store mixins [#124](https://github.com/spoike/refluxjs/pull/124)

## v0.2.2

* Fixed circular dependency issue that caused browserify builds not to work as expected [#129](https://github.com/spoike/refluxjs/issues/129) [#138](https://github.com/spoike/refluxjs/issues/138)
* Bind store methods before init() method executes. [#168](https://github.com/spoike/refluxjs/issues/168)
* Clarify the meaning of "FRP". [#161](https://github.com/spoike/refluxjs/issues/161)
* Child (async) actions and promise handling [#140](https://github.com/spoike/refluxjs/issues/140)

## v0.2.1

* IE8 trailing comma bug fix [#145](https://github.com/spoike/refluxjs/pull/145)
* Multiple use of Reflux.connect bug fix [#142](https://github.com/spoike/refluxjs/issues/142), [#143](https://github.com/spoike/refluxjs/pull/143)
* Added .npmignore file, removing non-essential files from `npm install` [#125](https://github.com/spoike/refluxjs/issues/125)

## v0.2.0

* Breaking change: Set initial state before componentDidMount (in `Reflux.connect`) [#117](https://github.com/spoike/refluxjs/pull/117)
* Allow extension of actions and stores (with `Reflux.ActionMethods` and `Reflux.StoreMethods`) [#121](https://github.com/spoike/refluxjs/pull/121)
* Automatically bind store methods [#100](https://github.com/spoike/refluxjs/pull/100)
* Bugfix: Connect and listenermixin combo [#131](https://github.com/spoike/refluxjs/pull/131)

## v0.1.14, v0.1.15

* You may now stop listening to joined listenables individually [#96](https://github.com/spoike/refluxjs/pull/96).
* Reflux will now throw an error if you attempt to join less than two listenables [#97](https://github.com/spoike/refluxjs/pull/97).

## v0.1.13

* Added more join methods, i.e. `listener.joinLeading`, `listener.joinTrailing`, `listener.joinConcat` and `listener.joinStrict`
 [#92](https://github.com/spoike/refluxjs/pull/92).
* Actions can be set to sync or async trigger [#93](https://github.com/spoike/refluxjs/pull/93).
* And various bug fixes. Check the [milestone page](https://github.com/spoike/refluxjs/issues?q=milestone%3A0.1.13+is%3Aclosed).

## v0.1.12

* Bug fixes. Check the [milestone page](https://github.com/spoike/refluxjs/issues?q=milestone%3A0.1.12+is%3Aclosed).

## v0.1.9, v0.1.10, v0.1.11

* Critical bug fixes. See [#80](https://github.com/spoike/refluxjs/issues/80), [#81](https://github.com/spoike/refluxjs/issues/81), and [#82](https://github.com/spoike/refluxjs/issues/82).

## v0.1.8

* Added `Reflux.connect`, `Reflux.listenTo`, `listenToMany` conveniences. See [#63](https://github.com/spoike/refluxjs/pull/63) and [#75](https://github.com/spoike/refluxjs/pull/75)
* Stores may now use a `listenables` prop [#63](https://github.com/spoike/refluxjs/pull/63) to automatically register actions to callbacks
* `preEmit` may now map or transform the action payload by returning something. See [58](https://github.com/spoike/refluxjs/issues/58) and [#78](https://github.com/spoike/refluxjs/pull/78)
* Reflux now exposes a `keep` for easier introspection on actions and stores [#56](https://github.com/spoike/refluxjs/issues/56)
* Added mixin interfaces `ListenerMethods` and `PublisherMethods` making it possible for users to extend Reflux's actions and stores. See [#45](https://github.com/spoike/refluxjs/issues/45)

## v0.1.7

* Added support for initial data handling [#49](https://github.com/spoike/refluxjs/pull/49)
* Added CHANGELOG.md [#50](https://github.com/spoike/refluxjs/issues/50)
* Bug: Unregistered actions could not be reregistered [#47](https://github.com/spoike/refluxjs/pull/47)

## v0.1.6

* Added possibility to join actions and stores with `Reflux.all` [#27](https://github.com/spoike/refluxjs/issues/27), [#28](https://github.com/spoike/refluxjs/pull/28)
* Added circular dependency check [#26](https://github.com/spoike/refluxjs/issues/26)

## v0.1.5

* Bug fix

## v0.1.4

* Action functors are now deferred [#22](https://github.com/spoike/refluxjs/issues/22), [#23](https://github.com/spoike/refluxjs/pull/23)
* Added web tests using testling.ci [#20](https://github.com/spoike/refluxjs/pull/20)

## v0.1.3

* Added hooks `preEmit` and `shouldEmit` for actions [#16](https://github.com/spoike/refluxjs/issues/16)
* Various bug fixes and `.jshintrc` file created for grunt build

## v0.1.2

* Added `ListenerMixin` useful for React components [#7](https://github.com/spoike/refluxjs/issues/7)
* Using `eventemitter3` instead [#4](https://github.com/spoike/refluxjs/issues/4)

## v0.1.1

* Added convenience function to create multiple actions [#6](https://github.com/spoike/refluxjs/issues/6)
* Bug: createStore's unsubscribe function was broken [#5](https://github.com/spoike/refluxjs/issues/5)

## v0.1.0

* Removed lodash dependency [#1](https://github.com/spoike/refluxjs/issues/1)
