/<style[^>]*>/,/<\/style>/{
  /<style[^>]*>/{
    h
    s/<style[^>]*>.*//
    p
    i\
<style type="text/css">/*<![CDATA[*/
    # Unfortunately, r appends after the current line.  If the end of the style
    # pattern is on this line, then this will mean that the end of the line
    # will appear before the style.  That's terrible.  See below.
    r lib/style.css
    a\
  /*]]>*/</style>
    a\
  <meta name="viewport" content="initial-scale=1.0">
    g
  }
  # Save the last line for later.
  /<\/style>/h
  d
}
# This recovers a saved line and prints it.
x
/<\/style>/{
  s/.*<\/style>//
  p
}
x
