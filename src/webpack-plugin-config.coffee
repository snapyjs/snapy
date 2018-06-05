path = require "path"

VirtualModulePlugin = require('virtual-module-webpack-plugin')


module.exports = class Config
  constructor: ({config, clientPlugins}) ->
    copy = Object.assign({},config)
    delete copy.plugins
    result = "module.exports = #{JSON.stringify(copy)}"
    plugins = clientPlugins.map (plugin) => "require('"+require.resolve(plugin)+"')"  
    result = result.replace /}$/, ",plugins:[#{plugins.join(',')}]}"
    return new VirtualModulePlugin
      path: path.resolve(__dirname,"./_snapy-config.js")
      contents: result
    