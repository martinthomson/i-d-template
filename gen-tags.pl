#!/usr/bin/env perl
#
# Generate tags file for explicit and implicit anchors in the Markdown drafts.
# This facilitates jumping to the marked place from the reference.
#
# Usage: ./gen-tags.pl *.md > tags
#
# (In vim, add the dash to the keyword definition via :set iskeyword+=-
# to be able to jump to anchors with dashes in them.)

sub to_re {
    my $search_str = quotemeta shift;
    $search_str =~ s/\\\{/{/g;  # Revert left curly brace escape just
                                # performed by quotemeta().
    return $search_str;
}

while (<>) {
    if (/^(#+\s+(.+?))\s*(?:$|\{)/) {   # Implicit anchor for header
        $re = to_re $1;
        $link = $2;
        $link =~ y/A-Z/a-z/;
        $link =~ s/[^A-Za-z0-9]/-/g;
        push @tags, "$link\t$ARGV\t/^$re/\n";
    }
    if (/(\{#\s*(.+?)\s*})/) {          # Explicit anchor
        $re = to_re $1;
        $link = $2;
        push @tags, "$2\t$ARGV\t/$re/\n";
    }
    if (/(\{:\s*#\s*(\S+))/) {          # Explicit anchor (for figure)
        $re = to_re $1;
        $link = $2;
        push @tags, "$2\t$ARGV\t/$re/\n";
    }
}

print sort @tags;
