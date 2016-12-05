const template = require("./index.html");

const styles = require("./styles.css");

const Elm = require("./Calculator.elm");

var root = document.getElementsByTagName("main")[0];

if(root) {
    Elm.Calculator.embed(root, styles);
} else {
    console.error("Cannot embed Elm application!");
};
