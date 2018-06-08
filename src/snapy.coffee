path = require "path"

fs = require "fs-extra"
Promise = require "yaku"
chalk = require "chalk"

hookUp = require "hook-up"
readConf = require "read-conf"

{isString,isFunction, arrayize, log, print, inspect, setVerbosity, status, hash, concat} = util = require "./util"

configName = "snapy.config"
webpackName = "webpack.config"
lookupDirs = ["./test","./"]

class Snapy
  constructor: ->
    hookUp @,
      actions: 
        "": ["getEntry", "run", "cancel", "report", "ask"]
        cache: ["get", "set", "discard","keep", "save"]
      catch: (e) => 
        @readConfig?.cancel(@)
        status "", "stop"
        console.error e
        status chalk.red("Snapy Error occured"), "fail"
  version: 1
  util: util
  fs: fs
  Promise: Promise
  chalk: chalk
  path: path
  log: log
  print: print
  inspect: inspect
  status: status

module.exports = (options) =>
  status "reading config"
  options ?= {}
  options.name ?= configName
  readConf 
    name: options.name
    watch: options.watch
    folders: lookupDirs
    assign: options.config
    plugins:
      paths: [process.cwd(), path.resolve(__dirname,"..")]
      prepare: ({plugins, target}) =>
        targets = require "./targets"
        for plugin in targets[target or "node"]
          plugins.push plugin
    schema: require.resolve("./configSchema")
    concatArrays:true
    required: false
    catch: (e) => console.log e
    base: new Snapy
    cancel: (snapy) =>
      unless snapy.isCanceled
        snapy.isCanceled = true
        status "stopping"
        snapy._watcher?.close()
        await snapy.cancel()
        snapy.resetAllActions()
        await snapy.isFinished if snapy.isFinished
        snapy.isCanceled = false
      status "stopped"
    cb: (snapy) =>
      {config, cache} = snapy
      setVerbosity config.verbose
      
      position = snapy.position
      cache.get.hookIn position.init, (o) => o.cache = set: false, value: null
      cache.get.hookIn position.after, (o) => o.value = o.cache.value if o.cache.set
      cache.set.hookIn position.init, (o) => o.cache = set: true, value: o.value
      snapy.getEntry.hookIn position.before, (o) => 
        o.files = o.files.filter (filename) => not filename.startsWith configName
      
      snapy.clientPlugins = clientPlugins = []
      workers = []
      for {pluginPath, plugin} in config.plugins
        if plugin.client
          if isString(plugin.client)
            clientPlugins.push path.resolve(pluginPath,"..",plugin.client)
          else
            clientPlugins.push pluginPath 
        if plugin.server?
          workers.push plugin.server(snapy)
        else if isFunction(plugin)
          workers.push plugin(snapy)
      await Promise.all(workers)

      
      status "merging webpack.config"
      webpackDefaults = require("./"+webpackName)(snapy)

      if config.webpackFile
        webpackConfig = require path.resolve(config.webpackFile)
      else
        webpackConfig = {}
      mergeWebpack = require "webpack-merge"
      configWebpack = snapy.webpackConfig = mergeWebpack webpackDefaults, webpackConfig, config.webpack
      unless configWebpack.entry?
        {entry: configWebpack.entry} = await snapy.getEntry {}
      status "running webpack"
      webpack = require("webpack")
      MemoryFS = require "memory-fs"
      mfs = new MemoryFS()
      compiler = webpack configWebpack
      compiler.outputFileSystem = mfs
      {chunkStats, hashes} = require("./webpack-loader")

      moduleToDeps = (module, deps = []) =>
        if (fileDeps = module.buildInfo.fileDependencies)?
          concat deps, Array.from(fileDeps)
        for dep in module.dependencies
          moduleToDeps(dep.module, deps) if dep.module
        return deps
      first = true
      lastHash = null
      handler = (err, stats) =>
        
        if err?
          inspect err.stack or err
          inspect err.details if err.details
          status "ERROR: webpack", "fail"
        else if lastHash != (lastHash = stats.hash)
          if stats.hasErrors()
            for error in stats.toJson().errors
              inspect error
            status "webpack compilation failed", "warn"
          else unless snapy.isCanceled
            unless first
              snapy.isCanceled = true
              status "stopping tests"
              await snapy.cancel()
              snapy.cancel.reset()
              status "waiting for cleanup"
              await snapy.isFinished if snapy.isFinished
              snapy.isCanceled = false
              status "restarting tests"
            first = false
            status "webpack finished"
            if stats.hasWarnings()
              for warning in stats.toJson().warnings 
                inspect warning
            inspect stats.toString(chunks: false, colors: true), 2

            {value:cachedChunks} = await cache.get key:"chunks"
            cachedChunks ?= {}
            changedChunks = []

            outPath = stats.compilation.outputOptions.path

            types = ["tests","snaps"]
            newStats = => {tests:0, snaps:0}
            addStats = (s1,s2) =>
              for type in types
                s1[type] += s2[type]
            totalStats = newStats()
            dueStats = newStats() 
            due = {}
            for chunk in stats.compilation.chunks
              deps = moduleToDeps(chunk.entryModule)
              for dep in deps
                if (testHashes = hashes[dep])
                  for testHash in testHashes
                    cache.keep key: testHash

              chunkStat = deps.reduce ((acc,cur) => 
                curStat = chunkStats[cur] or newStats()
                addStats(acc,curStat)
                return acc
                ), newStats()
              if chunkStat.tests > 0
                addStats(totalStats, chunkStat)
                if config.runAll or cachedChunks[chunk.name] != chunk.hash
                  addStats(dueStats, chunkStat)
                  if (sourceMapFile = chunk.files[1])
                    sourceMap = JSON.parse(mfs.readFileSync(path.join(outPath,sourceMapFile), "utf8"))
                    sourceMap.sources = sourceMap.sources.map (filename) => filename.replace("webpack:///","")
                  changedChunks.push
                    name: chunk.name
                    stats: chunkStat
                    tests: chunkStat.tests
                    entry: chunk.entryModule.resource
                    content: mfs.readFileSync path.join(outPath,chunk.files[0]), "utf8"
                    mapName: sourceMapFile
                    map: sourceMap
                  cachedChunks[chunk.name] = chunk.hash
                  due[chunk.name] = chunkStat.snaps
                  

            if dueStats.tests and dueStats.snaps
              print "#{dueStats.tests} out of #{totalStats.tests} tests are due for testing (#{dueStats.snaps} snaps)"

              snapy.report.hookIn (chunk) => 
                if chunk.success == true
                  due[chunk.name]--

              snapy.run.hookIn position.after, =>
                for chunk, incomplete of due
                  delete cachedChunks[chunk] if incomplete
                cache.set key: "chunks", value: cachedChunks
              unless snapy.isCanceled
                await snapy.isFinished = snapy.run
                  changedChunks: changedChunks
                  stats: stats
                  fs: mfs
                  stats: 
                    total: totalStats
                    due: dueStats
                    byFile: chunkStats
              unless snapy.isCanceled
                await cache.save() 
              #console.log process._getActiveHandles()
            else
              status chalk.green("No changes detected since last successfull run"), "succeed"
            process.exit() unless options.watch
          
            
      if options.watch or configWebpack.watch
        snapy._watcher = compiler.watch configWebpack.watchOptions, handler
        process.on "SIGINT", => process.exit(0)
      else
        compiler.run handler

if process.argv[0] == "coffee"
  try
    require "coffeescript/register"
  catch
    try
      require "coffee-script/register"
  module.exports()
  