#!/usr/bin/env node
var args, i, len, options, arg
options = {}
args = process.argv.slice(2)
for (i = 0, len = args.length; i < len; i++) {
  arg = args[i]
  if (arg[0] == "-") {
    switch (arg) {
      case '-w':
      case '--watch':
        options.watch = true
        break
      case '-h':
      case '--help':
        console.log('usage: snapy <options> (config file)')
        console.log('')
        console.log('options:')
        console.log('-w, --watch         restart snapy on changes in config')
        console.log('')
        console.log('config file is optional and defaults to "snapy.config.[js|json|coffee|ts]"')
        console.log('in "test/" and "/"')
        process.exit()
        break
    }
  } else {
    options.name = arg
  }
}
var start
/*try {
  //require("coffeescript/register")
  //start = require("./src/snapy.coffee")
} catch (e) {
 
}*/
start = require("./lib/snapy.js")
start(options)