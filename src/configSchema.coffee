module.exports =
  verbose:
    type: Number
    default: 1
    desc: "Level of logging"
  
  runAll: 
    type: Boolean
    default: false
    desc: "Will also run tests from unchanged chunks"
  target: 
    type: String
    default: "node"
    desc: "Environment where the tests are run"
  timeout: 
    type: Number
    default: 2000
    desc: "Timeout applied on all preparation, test and cleanup calls"
  plugins:
    type: Array
    default: [
      "snapy-cache"
      "snapy-obj"
      "snapy-entry"
      "snapy-promise"
      "snapy-transform-obj"
      "snapy-filter-obj"
    ]
    desc: "Snapy plugins to load"
  plugins$_item:
    type: String
    desc: "Package name or filepath (absolute or relative to cwd) of plugin"
  disablePlugins:
    type: Array
    desc: "Disable some of the default plugins"
  disablePlugins$_item:
    type: String
    desc: "Package name or filepath (absolute or relative to cwd) of plugin"
  webpackFile:
    type: String
    desc: "Path of webpack.config file to use for testing"
  webpack:
    type: Object
    default: {}
    desc: "webpack configuration which will be used by merging"