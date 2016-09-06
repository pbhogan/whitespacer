# Whitespacer package

Strips trailing whitespace, adds a trailing newlines when an editor is saved and does tab to spaces conversions.

To disable/enable features for a certain language package, you can use syntax-scoped properties in your `config.cson`. E.g.

```coffee
'.slim.text':
  whitespace:
    removeTrailingWhitespace: false
```

You find the `scope` on top of a grammar package's settings view.

Note: for `.source.jade` removing trailing whitespace is disabled by default.
