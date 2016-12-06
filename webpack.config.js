const ExtractTextPlugin = require("extract-text-webpack-plugin");

var htmlExtractor = new ExtractTextPlugin("index.html");

module.exports = {
    entry: "./entry.js",
    output: {
        path: __dirname + "/dist",
        filename: "bundle.js"
    },

    module: {
        loaders: [
            { test: /\.css$/, loader: "style-loader!css-loader?modules" },
            { test: /\.woff$/, loader: "file-loader" },
            { test: /\.elm$/,  loader: "elm-webpack-loader" },
            { test: /\.html$/, loader: htmlExtractor.extract(
                { loader: "html-loader?minimize=true" }
            )}
        ]
    },

    plugins: [
        htmlExtractor
    ]
}
