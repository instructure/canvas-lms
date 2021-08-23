# End to End testing

End to End testing framework for canvas-lms Jenkinsfiles
For more information about the e2e testing framework take a look [JenkinsPipelineUnit](https://github.com/jenkinsci/JenkinsPipelineUnit)

## Getting Started

First, you need to install JDK 8:

```bash
$ brew tap AdoptOpenJDK/openjdk
$ brew cask install adoptopenjdk8
```

## Install gradle

Install gradle:

```bash
brew install gradle
```

## Install gradle wrapper

To install gradle wrapper:

```bash
$ GRADLE_WRAPPER_DIR="/path/to/install/gradlewrapper/"
$ mkdir -p $GRADLE_WRAPPER_DIR
$ cd $GRADLE_WRAPPER_DIR
$ gradle wrapper
$ echo "export PATH=$GRADLE_WRAPPER_DIR:\$PATH" >> ~/.bashrc
$ source ~/.bashrc
```

For further information: [gradlewrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html)

## Running Tests
```bash
$ cd /path/to/canvas-lms/build/new-jenkins/library
$ gradlew integrationTest
```

To run a specific file
```bash
$ cd /path/to/canvas-lms/build/new-jenkins/library
$ gradlew integrationTest --tests <classname> # where classname is RebaseHelperTest for example
```

To force a re-run a specific file
```bash
$ cd /path/to/canvas-lms/build/new-jenkins/library
$ gradlew integrationTest --tests <classname> --info --rerun-tasks # where classname is RebaseHelperTest for example
```

## Help & Support

If you run into any issues, please don't hesitate to reach out to #devx!
