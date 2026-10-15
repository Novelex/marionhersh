# Converts the original WordPress page content into clean, accessible HTML fragments.
# Only structure changes (headings, lists, table headers, joined line breaks);
# the words are kept exactly as they appear on the original site.
#
# usage: perl _build/convert.pl <dir with *.clean.html> <output dir>
use strict; use warnings; use utf8;
binmode STDOUT, ':utf8';
my ($IN, $OUT) = @ARGV;

sub slurp { local $/; open my $f, '<:utf8', $_[0] or die "$_[0]: $!"; my $s = <$f>; $s }
sub spit  { open my $f, '>:utf8', $_[0] or die "$_[0]: $!"; my $s = $_[1]; my %seen; $s =~ s{ id="([^"]+)"}{ $seen{$1}++ ? qq{ id="$1-$seen{$1}"} : qq{ id="$1"} }ge; print $f $s; close $f; print "wrote $_[0]\n" }
sub slug  { my $s = lc shift; $s =~ s/<[^>]+>//g; $s =~ s/&[a-z]+;|&#\d+;//g; $s =~ s/[^a-z0-9]+/-/g; $s =~ s/^-|-$//g; $s }

sub prep {
  my $h = shift;
  my %ent = ('&#8211;' => '–', '&#8212;' => '—', '&#8216;' => '‘', '&#8217;' => '’', '&#8220;' => '“', '&#8221;' => '”', '&#038;' => '&amp;', '&nbsp;' => ' ');
  $h =~ s/(&#82\d\d;|&#038;|&nbsp;)/$ent{$1}/g;
  $h =~ s/\x{A0}/ /g;
  $h =~ s/<strong><\/strong>//g;
  $h =~ s/<strong>\s*<br>\s*<\/strong>/<br>/g;
  $h =~ s/[ \t]+/ /g;
  $h =~ s/ +(<\/(?:p|li|td|a|strong)>)/$1/g;
  $h =~ s/(<(?:p|li|td)>) +/$1/g;
  $h =~ s/<p>\s*<\/p>\n?//g;
  return $h;
}
# A single line break inside running text is a copy-paste artefact: join with a space.
sub joinbr { my $s = shift; $s =~ s/\s*<br>\s*(?!<br>)/ /g; $s }

# Tables: first row(s) become header cells; spanning headers get colspan.
sub table {
  my ($t, $caption) = @_;
  my @rows = $t =~ /<tr>(.*?)<\/tr>/gs;
  my @cells = map { [ $_ =~ /<td>(.*?)<\/td>/gs ] } @rows;
  my $nh = 1;
  $nh = 2 if @cells > 2 && @{$cells[0]} < @{$cells[1]} && $cells[1][1] =~ /^No\.$/;
  my $o = qq{<div class="table-scroll">\n<table>\n};
  $o .= "<caption>$caption</caption>\n" if defined $caption;
  $o .= "<thead>\n";
  for my $r (0 .. $nh - 1) {
    my @c = @{$cells[$r]}; my $span = ($nh == 2 && $r == 0) ? 2 : 1;
    $o .= '<tr>' . join('', map {
      my $x = $c[$_]; $x =~ s/^\s+|\s+$//g;
      $x eq '' ? '<td></td>' : ($_ == 0 ? qq{<th scope="col">$x</th>} : ($span == 2 ? qq{<th scope="colgroup" colspan="2">$x</th>} : qq{<th scope="col">$x</th>}))
    } 0 .. $#c) . "</tr>\n";
  }
  $o .= "</thead>\n<tbody>\n";
  for my $r ($nh .. $#cells) {
    my @c = @{$cells[$r]};
    $o .= '<tr>' . join('', map { my $x = $c[$_]; $x =~ s/^\s+|\s+$//g; $_ == 0 && $nh > 0 && @c > 2 ? qq{<th scope="row">$x</th>} : "<td>$x</td>" } 0 .. $#c) . "</tr>\n";
  }
  $o .= "</tbody>\n</table>\n</div>\n";
  return $o;
}

# ---------- Projects ----------
{
  my $h = prep(slurp("$IN/projects.clean.html"));
  my @out; my $first = 1;
  for my $l (split /\n/, $h) {
    next if $l =~ /^\s*$/;
    if ($l =~ /^<p><strong>(?:<a href="#[^"]*">)?(.*?)(?:<\/a>)?<\/strong><\/p>$/) {
      my $t = $1; my $lv = $first ? 2 : 3; $first = 0;
      push @out, qq{<h$lv id="} . slug($t) . qq{">$t</h$lv>};
    } elsif ($l =~ /^<p><a href="#[^"]*">(.*?)<\/a><\/p>$/) {
      push @out, qq{<h4 id="} . slug($1) . qq{">$1</h4>};
    } elsif ($l =~ /<br><br>/ && $l =~ /^<p>(.*)<\/p>$/) {
      my @parts = split /<br><br>/, $1;
      if ($parts[0] =~ /\(\d{4}\)/) { push @out, qq{<ul class="refs">}, (map { "  <li>" . joinbr($_) . "</li>" } @parts), '</ul>' }
      else { push @out, map { "<p>" . joinbr($_) . "</p>" } @parts }
    } elsif ($l =~ /^<table>/) {
      push @out, table($l);
    } else { push @out, joinbr($l) }
  }
  my $s = join("\n", @out) . "\n";
  # one box for the project introduction, then one box per section
  $s =~ s{(<h3 id="([^"]+)")}{</section>\n<section class="box" aria-labelledby="$2">\n$1}g;
  $s =~ s{^(<h2 id="([^"]+)")}{<section class="box" aria-labelledby="$2">\n$1};
  $s .= "</section>\n";
  spit("$OUT/projects.frag.html", $s);
}

# ---------- Research participation ----------
{
  my $h = prep(slurp("$IN/research.clean.html"));
  my @out;
  for my $l (split /\n/, $h) {
    next if $l =~ /^\s*$/;
    if ($l =~ /^<p><strong>(.*?)<\/strong><\/p>$/) {
      push @out, '</section>' if grep { /<section/ } @out;
      push @out, qq{<section class="box" aria-labelledby="} . slug($1) . qq{">}, qq{<h2 id="} . slug($1) . qq{">$1</h2>};
    } else {
      $l = joinbr($l);
      $l =~ s{(?<!["/])(https://calmspaces\.org)}{<a href="$1">$1</a>};
      $l =~ s{(?<![:"\w.])([\w.]+\@[\w.]+\.\w+)(?![^<]*</a>)}{<a href="mailto:$1">$1</a>}g;
      push @out, $l;
    }
  }
  push @out, '</section>';
  my $s = join("\n", @out) . "\n";
  # the subtitle line under the AI survey heading is a sub-heading on the original page
  $s =~ s{<p>(Questionnaire on Disabled, Neurodivergent and Deaf Researchers and Other Professionals in AI Research)</p>}{<h3>$1</h3>};
  spit("$OUT/research.frag.html", $s);
}

# ---------- Trade union (sections before the interview) and interview ----------
sub interview {
  my $h = shift;
  $h =~ s/.*?(<p><strong>What does it feel like)/$1/s or die "interview start";
  $h =~ s/<\/?strong>/\x01/g;
  my @blocks;
  for my $p (split /<\/?p>|<br>/, $h) {
    $p =~ s/^\s+|\s+$//g; next if $p eq '' || $p =~ /^\x01*$/;
    if ($p =~ /^\x01\s*([^\x01]*\?)\s*\x01?$/s && $p !~ /(?:Christina|Marion):/) { push @blocks, ['q', $1]; next }
    $p =~ s/\x01//g;
    for my $seg (split /\s+(?=(?:Christina|Marion): )/, $p) {
      if ($seg =~ /^(Christina|Marion): (.*)/s) { push @blocks, ['s', $1, $2] }
      elsif (@blocks && $blocks[-1][0] eq 's') { $blocks[-1][2] .= ' ' . $seg }
      else { push @blocks, ['x', $seg] }
    }
  }
  my $o = '';
  for my $b (@blocks) {
    if ($b->[0] eq 'q') { $o .= qq{<h3 id="} . slug($b->[1]) . qq{">$b->[1]</h3>\n} }
    elsif ($b->[0] eq 's') { (my $t = $b->[2]) =~ s/\s+/ /g; $t =~ s/\s+$//; $o .= qq{<p><span class="speaker">$b->[1]:</span> $t</p>\n} }
    else { $o .= "<p>$b->[1]</p>\n" }
  }
  return $o;
}
{
  my $h = prep(slurp("$IN/union.clean.html"));
  my ($before) = $h =~ /^(.*?)<p><strong>Interview with/s or die "union split";
  my @out; my $open = 0;
  for my $l (split /\n/, $before) {
    next if $l =~ /^\s*$/;
    if ($l =~ /^<p><strong>(.*?)<\/strong><\/p>$/) {
      push @out, '</section>' if $open; $open = 1;
      push @out, qq{<section class="box" aria-labelledby="} . slug($1) . qq{">}, qq{<h2 id="} . slug($1) . qq{">$1</h2>};
    } elsif ($l =~ /^<img/) {
      push @out, '{{INCLUDE src/flyer.frag.html}}';
    } else { push @out, joinbr($l) }
  }
  push @out, '</section>' if $open;
  spit("$OUT/union-top.frag.html", join("\n", @out) . "\n");
  spit("$OUT/interview.frag.html", interview($h));
  my ($title) = $h =~ /<p><strong>(Interview with[^<]*)<\/strong><\/p>/;
  spit("$OUT/interview-title.txt", $title);
}

# ---------- Recent posts ----------
{
  my $h = prep(slurp("$IN/recent.clean.html"));
  my ($link) = $h =~ /^\s*(<p>Link to new article:.*?<\/p>)/s or die "recent link";
  $link =~ s{https://marionhersh\.org/}{{{ROOT}}};
  spit("$OUT/recent-link.frag.html", "$link\n");
}

# ---------- Publications ----------
{
  my $h = prep(slurp("$IN/podcast.clean.html"));
  $h =~ s/<\/a><a href="https:\/\/eprints\.gla\.ac\.uk\/132276\/">/ /g;   # one title was split across two identical links
  $h =~ s{https://marionhersh\.org/}{{{ROOT}}}g;
  my %top = map { $_ => 1 } ('Books', 'Journal Papers', 'Book Chapters', 'On-line Encyclopedia Chapters');
  my @out; my $inlist = 0; my $box = 0;
  for my $l (split /\n/, $h) {
    next unless $l =~ /^<p>\s*(.*?)\s*<\/p>$/; my $t = $1; next if $t eq '';
    (my $plain = $t) =~ s/<\/?strong>//g;
    my $is_head = ($t =~ /^<strong>.*<\/strong>$/) || ($plain !~ /\(\d{4}\)|\d{4}\)|UNESCO/ && length($plain) < 60);
    if ($is_head) {
      push @out, '</ul>' if $inlist; $inlist = 0;
      if ($top{$plain}) {
        push @out, '</section>' if $box; $box = 1;
        push @out, qq{<section class="box" aria-labelledby="} . slug($plain) . qq{">}, qq{<h2 id="} . slug($plain) . qq{">$plain</h2>};
      } else { push @out, qq{<h3 id="} . slug($plain) . qq{">$plain</h3>} }
    } else {
      push @out, qq{<ul class="refs">} unless $inlist; $inlist = 1;
      push @out, '  <li>' . joinbr($t) . '</li>';
    }
  }
  push @out, '</ul>' if $inlist; push @out, '</section>' if $box;
  my $s = join("\n", @out) . "\n";
  # The encyclopedia site has closed: send the original links to archived copies where they exist.
  # The visible text is unchanged; part 3's link pointed at part 2 by mistake.
  $s =~ s{href="http://cirrie\.buffalo\.edu/encyclopedia/en/article/309/"}{href="https://web.archive.org/web/20170616165526/http://cirrie.buffalo.edu/encyclopedia/en/article/309/"};
  $s =~ s{href="http://cirrie\.buffalo\.edu/encyclopedia/en/article/311/">(http://cirrie\.buffalo\.edu/encyclopedia/en/article/312/)}{href="https://web.archive.org/web/20220617085123/http://cirrie.buffalo.edu/encyclopedia/en/article/312/">$1};
  spit("$OUT/publications.frag.html", $s);
  # The original Special Issues and Sessions page was empty. These are the entries from the
  # publications list that are a special issue editorial and special thematic session introductions.
  my @special = grep { /Serious games, education and inclusion|introduction to the special thematic session/ } split /\n/, $s;
  die "special: expected 3, got " . @special unless @special == 3;
  spit("$OUT/special.frag.html", qq{<ul class="refs">\n} . join("\n", @special) . "\n</ul>\n");
}

# ---------- Research article ----------
{
  my $h = prep(slurp("$IN/autistic.clean.html"));
  $h =~ s/<ul>\n<li><strong>(Desired Occupational Situations)<\/strong><\/li>\n<\/ul>/<p><strong>$1<\/strong><\/p>/ or die "432";
  my @toc;
  $h =~ s{<p><strong>\s*(\d+(?:\.\d+)*\.?)\s+(.*?)\s*</strong></p>}{
    my ($n, $t) = ($1, $2); (my $k = $n) =~ s/\.$//; my $d = () = $k =~ /\./g; my $l = $d + 2; $l = 4 if $l > 4;
    (my $id = "s$k") =~ s/\./-/g; push @toc, [$n, $t, $id] if $d == 0;
    "<h$l id=\"$id\">$n $t</h$l>" }ge;
  $h =~ s{<p><strong>(Desired Occupational Situations)</strong></p>}{<h4 id="desired-occupational-situations">$1</h4>};
  for my $t ('Abstract', 'Acknowledgements', 'Funding', 'Data', 'Conflicts of Interest', 'References') {
    (my $id = lc $t) =~ s/ /-/g;
    $h =~ s{<p><strong>$t</strong></p>}{<h2 id="$id">$t</h2>} or die "h $t";
  }
  $h =~ s{(<h2 id="references">References</h2>\n)<(?:ol|ul)>(.*?)</(?:ol|ul)>}{$1<ol class="paper-refs">$2</ol>}s or die "refs";
  $h =~ s{<hr[^>]*>\n<p><a href="#_ftnref1">\[1\]</a>}{<hr>\n<p id="fn1" class="note"><a href="#fnref1">[1]</a>};
  $h =~ s{<a href="#_ftn1">\[1\]</a>}{<sup><a id="fnref1" href="#fn1">[1]</a></sup>};
  # tables: the caption is the paragraph that follows each table
  $h =~ s{(<table>.*?</table>)\n((?:<p>\*.*?</p>\n)?)<p>(Table \d[^<]*)</p>\n}{ table($1, $3) . $2 }gse;
  spit("$OUT/paper.frag.html", $h);
  spit("$OUT/paper.toc.html", join('', map { qq{      <li><a href="#$_->[2]">$_->[0] $_->[1]</a></li>\n} } @toc));
}
