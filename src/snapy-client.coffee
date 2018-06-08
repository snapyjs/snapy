Promise = require "yaku"
snapy = 
  config: require "./_snapy-config.js"
  Promise: Promise
  util: require "./util-client"

hookUp = require "hook-up"
hookUp snapy,
  actions: ["snap","getCache","setCache", "ask", "report"]
  Promise: snapy.Promise

config = snapy.config
isFunction = snapy.util.isFunction
concat = snapy.util.concat

snapy.tests = tests = []
snapy.test = (args...) ->
  if args.length == 5
    args.unshift null
  tests.push args
snapy.getTestLine = (index) -> tests[index][3]
snapy.getTestSource = (index) -> tests[index][4]
snapy.getTestFile = (index) -> tests[index][5]
prepare = null
snapy.prepare = (fn) -> prepare = fn
snapy.after = (fn) -> snapy.cleanUp = fn
snapy.testID = 0
snapy.getTestID = -> snapy.testID
whenCanceled = new Promise (res, reject) ->
  snapy.cancel = reject

snapy.makeTimeout = makeTimeout = (position) ->
  
  reject = null
  stopped = 0
  timeout = (dur) -> 
    timeout.duration = dur if dur?
    if stopped == 0
      stop()
      start()
  timeout.duration = config.timeout
  promise = new Promise (res, rej) -> reject = rej
  lastTimeout = null
  stop = -> clearTimeout lastTimeout if lastTimeout
    
  timeout.start = start = (dur) ->
    timeout.duration = dur if dur?
    lastTimeout = setTimeout (->
      str = "Timeout ("+timeout.duration+") reached"
      str += " in "+position if position 
      reject(new Error str)
      ), timeout.duration
    lastTimeout.unref()
    return promise
  timeout.resume = ->
    if stopped > 0
      start() if --stopped == 0
  timeout.stop = -> stop() if stopped++ == 0
  return timeout
  

for plugin in snapy.config.plugins
  plugin = plugin.client if plugin.client
  plugin(snapy)

snapy.callTest = (index, piece) ->  new Promise (resolve)->
  [state, callTest, snaps, testLine, testSource, file] = tests[index]
  addedSnaps = []
  after = [["",resolve]]
  cleanUp = (place, cb) -> after.push [place, cb]
  done = ->
    first = after.reverse().reduce ((acc,curr) -> 
      acc
      .then ->
        if curr[0]
          Promise.race [
            (timeout = makeTimeout("cleanUp of "+curr[0])).start()
            curr[1].call({timeout:timeout})
          ]
          .catch (e) -> console.error e
        else
          curr[1]()
      ), Promise.resolve()

  testTimeout = null
  allDonePromise = null
  snap = (state, key, description, snapLine, snapSource) ->
    o = 
      state: state
      key: key
      description:description
      name: piece.name
      chunkEntry: piece.entry
      file: file
      testLine: testLine
      testSource: testSource
      snapLine: snapLine
      snapSource: snapSource
      origin: file + ":" + snapLine
    testTimeout.stop()
    promise = Promise.race([
      (o.timeout = makeTimeout("snap #{file}:#{snapLine}")).start(testTimeout.duration)
      whenCanceled
      snapy.getCache(o)  
        .then snapy.snap
        .then snapy.setCache
        .then snapy.report
    ]).catch (e) ->
      if e instanceof Error
        o.stderr = (e.stack or e).toString().split("\n")
      snapy.report(o)
    addedSnaps.push promise
    if addedSnaps.length - snaps == 0
      Promise.all(addedSnaps)
      .then done
    return promise
  Promise.resolve()
  .then -> 
    if prepare?
      Promise.race [
        (timeout = makeTimeout("preparation")).start()
        prepare.call {timeout: timeout}, state, cleanUp.bind(null, "preparation")
      ]
  .then (result) -> 
    args = [snap]
    args.push result if result?
    args.push cleanUp.bind(null, "test")
    return Promise.race([
      (testTimeout = makeTimeout("test #{file}:#{testLine}")).start()
      whenCanceled
      new Promise (resolve, reject) ->
        try
          resolve(callTest.apply(null, args))
        catch e
          reject(e)
    ])
  .then -> new Promise (resolve, reject) ->
    (setTimeout (->
      if snaps - addedSnaps.length > 0
        reject new Error "not all snaps reached after timeout of #{config.timeout}"
      else
        resolve()
    ), config.timeout).unref()
  .catch (e) ->
    console.error e.stack or e
    done()
if window?
  window.snapy = snapy
else if global
  global.snapy = snapy
if module?
  module.exports = snapy
  