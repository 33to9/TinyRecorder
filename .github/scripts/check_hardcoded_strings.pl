#!/usr/bin/perl
# Fails if a Swift string literal contains CJK text. User-facing text must be written
# in English in code and translated in <lang>.lproj/Localizable.strings, so every
# language shows only its own text. Comments are ignored.
use strict; use warnings; use utf8;
use File::Find;
binmode STDOUT, ':utf8';
my $bad = 0;
find(sub {
    return unless /\.swift$/;
    my $f = $File::Find::name;
    open my $fh, '<:encoding(UTF-8)', $_ or die "$f: $!";
    while (my $line = <$fh>) {
        next if $line =~ m{^\s*//};
        $line =~ s{\s//[^"]*$}{};                       # trailing comment without quotes
        while ($line =~ /"((?:[^"\\]|\\.)*)"/g) {
            my $lit = $1;
            if ($lit =~ /[\p{Han}\p{Hiragana}\p{Katakana}\p{Hangul}]/) {
                print "$f:$.: hardcoded non-English string \"$lit\"\n"; $bad = 1;
            }
        }
    }
}, $ARGV[0] // 'TinyRecorder');
print "No hardcoded CJK strings in Swift code.\n" unless $bad;
exit $bad;
