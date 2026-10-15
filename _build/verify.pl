# Word-by-word check that each new page contains exactly the original site's text.
# Interface elements (breadcrumbs, contents menus, page titles) are left out of the comparison,
# and the election flyer (an image on the original site) is checked separately.
#
# usage: perl _build/verify.pl   (run from the project root)
use strict; use warnings;
my $tmp = $ENV{TMPDIR} || $ENV{TEMP} || '/tmp';

sub slurp { local $/; open my $f, '<', $_[0] or die "$_[0]: $!"; my $s = <$f>; $s }
sub text {
  my $h = shift;
  $h =~ s/<br\s*\/?>/ /g;
  $h =~ s/<[^>]+>/ /g;
  my %e = ('&amp;' => '&', '&#038;' => '&', '&#8211;' => '–', '&#8212;' => '—', '&#8216;' => '‘', '&#8217;' => '’', '&#8220;' => '“', '&#8221;' => '”', '&nbsp;' => ' ', '&lt;' => '<', '&gt;' => '>', '&quot;' => '"');
  $h =~ s/(&#?\w+;)/exists $e{$1} ? $e{$1} : $1/ge;
  $h =~ s/\xC2\xA0/ /g;
  $h =~ s/\s+/ /g; $h =~ s/^ | $//g;
  return $h;
}
sub main_of {
  my $h = slurp(shift);
  ($h) = $h =~ /<main[^>]*>(.*)<\/main>/s;
  $h =~ s{<p class="crumbs">.*?</p>}{}gs;
  $h =~ s{<nav class="toc side".*?</nav>}{}gs;
  $h =~ s{<h1[^>]*>.*?</h1>}{}gs;
  $h =~ s{<p class="byline">.*?</p>}{}gs;
  $h =~ s{<div class="flyer">.*?\n</div>\n}{}gs;
  # captions must come first inside a table; on the original site they followed it
  $h =~ s{(<caption>.*?</caption>)(.*?</table>\s*</div>\s*(?:<p>\*[^<]*</p>\s*)?)}{$2$1}gs;
  return $h;
}
my @pairs = (
  ['home.clean.html',     'index.html', sub { my $h = shift; $h =~ s{<div class="card-grid">.*}{}s; $h =~ s{<p class="role">}{<p>}; $h }],
  ['projects.clean.html', 'projects/index.html'],
  ['research.clean.html', 'research-participation/index.html'],
  ['union.clean.html',    'trade-union/index.html'],
  ['recent.clean.html',   'recent-posts/index.html'],
  ['podcast.clean.html',  'publications/index.html'],
  ['autistic.clean.html', 'older-autistic-adults-experiences-attitudes-and-support-needs/index.html'],
);
my $problems = 0;
for my $p (@pairs) {
  my ($orig, $new, $fix) = @$p;
  my $a = text(slurp("_build/original/$orig"));
  my $bh = main_of($new); $bh = $fix->($bh) if $fix;
  my $b = text($bh);
  # The home page links "Recent Posts" and "Archive" now sit in the boxes further down the page.
  $a =~ s/ Recent Posts Archive$// if $orig eq q(home.clean.html);
  open my $fa, '>', "$tmp/v-a.txt"; print $fa "$a\n"; close $fa;
  open my $fb, '>', "$tmp/v-b.txt"; print $fb "$b\n"; close $fb;
  my $d = `git diff --no-index --word-diff=plain --word-diff-regex="[^[:space:]]+" "$tmp/v-a.txt" "$tmp/v-b.txt"`;
  my @ch = $d =~ /(\[-.*?-\]|\{\+.*?\+\})/g;
  my $wa = () = $a =~ /\S+/g;
  printf "%-60s %6d words  %s\n", $new, $wa, @ch ? scalar(@ch) . " differences" : "identical";
  if (@ch) { $problems++; print "    $_\n" for @ch[0 .. ($#ch < 15 ? $#ch : 15)] }
}
print $problems ? "\n$problems page(s) differ from the original\n" : "\nAll pages match the original text word for word\n";
