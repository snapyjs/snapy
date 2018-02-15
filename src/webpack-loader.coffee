acorn = require "acorn"
equery = require "grasp-equery"

sourceMap = require "source-map"

{hash} = require "./util"

testSelector = equery.parse("test(_$)")
snapSelector = equery.parse("snap(__)")

chunkStats = {}
hashes = {}
module.exports = (source, map) ->
  getStrFromExpr = (expr) => source.slice expr.start, expr.end
  getFrom = (arr, expr) =>
    result = []
    if arr.length > 0
      for entry, i in arr by -1
        if entry.start > expr.end
          arr.pop()
        else if entry.start > expr.start
          result.push arr.pop()
        else
          break
    return result
  getHashFromExpr = (expr) => hash(getStrFromExpr(expr))
  addArguments = (expr, args) =>
    args = args.map (str) => str.replace?(/"/g,"\\\"") or str
    insertString = ",\""+args.join("\",\"")+"\""
    source = source.slice(0,expr.end-1) + insertString + source.slice(expr.end-1)

  @cacheable?()
  cb = @async?() or @callback
  comments = []
  ast = acorn.parse source, onComment: comments, locations: true, ecmaVersion: 8
  tests = equery.queryParsed(testSelector, ast)
  if tests.length > 0
    snaps = equery.queryParsed snapSelector, ast
    chunkStats[@resourcePath] = tests: tests.length, snaps: snaps.length
    tmpHashes = hashes[@resourcePath] = []
    if map
      sourceByLines = map.sourcesContent[0].split("\n")
      consumer = await new sourceMap.SourceMapConsumer(map)
      getLoc = ({loc}) =>
        start = consumer.originalPositionFor loc.start
        end = consumer.originalPositionFor loc.end
        if end.line == start.line and loc.end.line != loc.start.line
          end = consumer.originalPositionFor line: loc.end.line-1, column: loc.end.column
        return start: start, end: end
    else
      sourceByLines = source.split("\n")
      getLoc = (expr) => expr.loc
    getStartLine = (loc) => loc.start.line
    getSource = (loc) => sourceByLines.slice(loc.start.line-1, loc.end.line).join("\\n")
    tests.reverse().forEach (test) =>
      testHash = getHashFromExpr test
      testSnaps = getFrom snaps, test
      testLoc = getLoc(test)
      addArguments(test, [testSnaps.length, getStartLine(testLoc), getSource(testLoc), @resourcePath])
      testComments = getFrom(comments, test).reverse()
      snapLocs = testSnaps.map(getLoc)
      for snap, i in testSnaps
        prevSnapEnd = testSnaps[i+1]?.end or 0
        snapComments = []
        for comment in testComments by -1
          if comment.start > prevSnapEnd
            testComments.pop()
            snapComments.push comment.value.trim()
          else
            break
        snapComment = snapComments.reverse().join("\\n")
        snapLoc = snapLocs[i]
        addArguments(snap, [testHash+i, snapComment, getStartLine(snapLoc), getSource(snapLoc) ])
        tmpHashes.push testHash+i
  consumer?.destroy()
  cb(null,source,map)

module.exports.chunkStats = chunkStats
module.exports.hashes = hashes
