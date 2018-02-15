path = require "path"
webpack = require "webpack"
fs = require "fs-extra"

snapyConfigPlugin = require("./webpack-plugin-config")

getRegExp = (name) => new RegExp "\\.#{name}$"

getStyleLoader = (name) =>
  loaders = ["style-loader","css-loader"]
  loaders.push "#{name}-loader" unless name == "css"
  return test: getRegExp(name), use: loaders

getLoader = (name) => test: getRegExp(name), use: "#{name}-loader"

module.exports = (snapy) =>
  devtool: "source-map"
  output:
    filename: "[chunkhash].js"
  module:
    rules: [
      getStyleLoader("css")
      getStyleLoader("sass")
      getStyleLoader("stylus")
      getLoader("html")
      getLoader("coffee")
      {
        test: getRegExp("(js|coffee|ts)")
        loader: require.resolve("./webpack-loader")
        enforce: "post"
        exclude: /node_modules/
      }
    ]
  resolve:
    extensions: [".js", ".json", ".coffee", ".ts"]
  resolveLoader:
    extensions: [".js", ".coffee", ".ts"]
    modules:[
      "web_loaders"
      "web_modules"
      "node_loaders"
      "node_modules"
      path.resolve(process.cwd(), "./node_modules")
      path.resolve(fs.realpathSync(process.cwd()),"..")
    ]
  plugins: [
    new snapyConfigPlugin snapy
    new webpack.DefinePlugin "process.env.NODE_ENV": '"test"'
  ]