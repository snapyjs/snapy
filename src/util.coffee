path = require "path"
Promise = require "yaku"
ora = require "ora"
{createHash} = require "crypto"
{inspect} = require "util"
module.exports.concat = (arr1,arr2) -> Array.prototype.push.apply(arr1, arr2)
module.exports.isString = (str) => typeof str == "string" or str instanceof String
module.exports.isFunction = (fn) => typeof fn == "function"
module.exports.isArray = Array.isArray
module.exports.arrayize = (obj) => 
  if Array.isArray(obj)
    return obj
  else unless obj?
    return []
  else
    return [obj]
spinner = null
module.exports.status = (str, prop) => 
  unless spinner?
    module.exports.spinner = spinner = ora().start()
  if prop
    spinner[prop](str)
  else
    spinner.text = str
  return spinner
_log = []
verbosity = 0
module.exports.log = (i, text, verbose = 1) => 
  unless text?
    text = i
    i = 0
  (_log[i] ?= []).push text if verbosity >= verbose
module.exports.print = (text, verbose = 1)  =>
  spinner?.stop()
  unless text
    for texts in _log
      for text in texts
        console.log "snapy: " + text
      console.log ""
    _log = []
  else
    console.log "snapy: " + text if verbosity >= verbose
  spinner?.start()
module.exports.inspect = (obj, verbose = 1) =>
  if verbosity >= verbose
    spinner?.stop()
    console.log obj
    spinner?.start()
module.exports.setVerbosity = (verbose) => verbosity = verbose 
module.exports.hash = (str) => createHash("md5").update(str).digest("hex")
globObj = {stat: true, nodir: true}
