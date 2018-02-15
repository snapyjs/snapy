# Snapy

Webpack based, snapshot only test runner.
Currently nodejs only, but with clientside and E2E testing in planning.

## Features
- Snapshots only - forces you to do proper tests of input -> output
- Interactively shows you the output and asks about it
- Uses webpack bundles to track changes
- Watches test files and dependencies
- Static analysis of tests to make writing them as easy as possible


### Install
```sh
npm install --save-dev snapy
```

### Usage
```js
// ./test/test.js
// snapy tries to load all files in test directory by default
{test} = require("snapy")
test((snap) => {
  snap({obj: true})
})
```
```sh
# in terminal
snapy --help

# usage: snapy <options> (config file)

# options:
# -w, --watch         restart snapy on changes in config

# config file is optional and defaults to "snapy.config.[js|json|coffee|ts]"
# in "test/" and "/"
```

## snapy.config
Read by [read-conf](https://github.com/paulpflug/read-conf), from `./` or `./test/` by default.
```js
// ./test/snapy.config.js
module.exports = {

  // Disable some of the default plugins
  // $item (String) Package name or filepath (absolute or relative to cwd) of plugin
  disablePlugins: null, // Array

  // Snapy plugins to load
  // type: Array
  // $item (String) Package name or filepath (absolute or relative to cwd) of plugin
  plugins: ["snapy-cache","snapy-obj","snapy-entry","snapy-promise","snapy-transform-obj","snapy-filter-obj"],

  // Will also run tests from unchanged chunks
  runAll: false, // Boolean

  // Environment where the tests are run
  target: "node", // String

  // Timeout applied on all preparation, test and cleanup calls
  timeout: 2000, // Number

  // Level of logging
  verbose: 1, // Number

  // webpack configuration which will be used by merging
  webpack: {}, // Object

  // Path of webpack.config file to use for testing
  webpackFile: null, // String

  // …

}
```

## Plugins

You should read the (short) docs of the bold ones.

Activated by default:
- **[snapy-obj](https://github.com/snapyjs/snapy-obj)**
- **[snapy-promise](https://github.com/snapyjs/snapy-promise)**
- **[snapy-transform-obj](https://github.com/snapyjs/snapy-transform-obj)**
- **[snapy-filter-obj](https://github.com/snapyjs/snapy-filter-obj)**
- [snapy-entry](https://github.com/snapyjs/snapy-entry)
- [snapy-cache](https://github.com/snapyjs/snapy-cache)

Activated by target: "node"
- **[snapy-node](https://github.com/snapyjs/snapy-node)**
- [snapy-file](https://github.com/snapyjs/snapy-file)
- [snapy-stream](https://github.com/snapyjs/snapy-stream)
- [snapy-node-report](https://github.com/snapyjs/snapy-node-report)

## Writing tests
The API is small but powerful:
```js
// ./test/someFile.js
{test, prepare, after, getTestId} = require("snapy")

// code outside will be called before all tests

// prepare(fn)
// fn will be called before each test and takes two arguments:
// state (optional) a state given by a test
// cleanUp(fn) registers a fn which will be called after each test
// you can return a value, which will be passed to the test
prepare((state, cleanUp) => {
  // do something
  cleanUp( => {
    // cleanup what you did
  })
  
  // getTestId()
  // provides you with an unique identifier for current running test
  // this is important as some tests may run in parallel on different threads
  portToUse = 8080+getTestId()
  return processedState
})

// test(state, fn)
// state is optional, and will be passed to prepare call
// fn takes two or three arguments
// depending if there is a returned value from prepare
// snap(obj) will take a snapshot and test it against previous values
// processedState: return value of prepare
// cleanUp(fn) registers a fn which will be called after this test
test(state, (snap, processedState, cleanUp) => {
  snap({obj: true})
  cleanUp( => {
    // cleanup what you did
  })
})


// after(fn)
// registers a fn which will be called after all tests
after( => {
  // more cleanUp
})
```

## Caveats
As the tests are statically analysed, you are not allowed to do one of the following:
- don't rename `test` or `snap`
```js
{test:tst} = require("snapy") // won't work
test((sn) => {sn({obj:true})}) // won't work
```
- don't use `snap` in conditional statements or loops
```js
test((snap) => {
  [1,2].forEach((i) => {snap({obj:i})}) // won't work
})
```
- don't define the test outside of the `test` call
```js
t = (snap) => {snap({obj:true})}
test(t) // won't work
```

## License
Copyright (c) 2018 Paul Pflugradt
Licensed under the MIT license.
