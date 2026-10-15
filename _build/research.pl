# Builds the complete publication list and the summary figures from:
#   research/enlighten-9066.json     - University of Glasgow Enlighten repository, author 9066
#   research/crossref-additions.json - further publications found on Crossref (checked one by one)
# usage: perl _build/research.pl   (run from the project root)
use strict; use warnings; use utf8; use JSON::PP;
binmode STDOUT, ':utf8';
sub slurp { local $/; open my $f, '<:raw', $_[0] or die "$_[0]: $!"; <$f> }
sub spit  { open my $f, '>:utf8', $_[0] or die "$_[0]: $!"; print $f $_[1]; close $f; print "wrote $_[0]\n" }
sub esc   { my $s = shift // ''; $s =~ s/&(?!(?:amp|lt|gt|quot|#\d+);)/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g; $s }
# DOIs taken from the repository page can contain HTML entities and characters that are not allowed in a URL
sub href  { my $s = shift; $s =~ s/&lt;/</g; $s =~ s/&gt;/>/g; $s =~ s/&amp;/&/g; $s =~ s/([<>"\s])/sprintf("%%%02X", ord $1)/ge; $s =~ s/&/&amp;/g; $s }
sub names { my @n = @{ $_[0] }; return $n[0] if @n == 1; join(', ', @n[0 .. $#n - 1]) . ' and ' . $n[-1] }

my $en  = decode_json(slurp('_build/research/enlighten-9066.json'));
my $add = decode_json(slurp('_build/research/crossref-additions.json'));
$_->{source} = 'enlighten' for @$en;
$_->{source} = 'crossref'  for @$add;
my @all = sort { $b->{year} <=> $a->{year} } (@$en, @$add);   # sort is stable: repository order kept within a year

my %count; $count{$_->{type}}++ for @all;
my $total = @all; my $first = (sort { $a <=> $b } map { $_->{year} } @all)[0];

sub entry {
  my $p = shift;
  my $url = $p->{source} eq 'enlighten' ? "https://eprints.gla.ac.uk/$p->{eid}/" : "https://doi.org/" . href($p->{doi}) . "";
  my $s = esc(names($p->{authors})) . " ($p->{year}) <a href=\"$url\">" . esc($p->{title}) . "</a> " . esc($p->{rest});
  $s .= qq{ <a href="https://doi.org/} . href($p->{doi}) . qq{">doi:} . esc($p->{doi}) . '</a>' if $p->{doi} && $p->{source} eq 'enlighten';
  return "  <li>$s</li>\n";
}

my $o = qq{<section class="box complete" aria-labelledby="complete-list">\n<h2 id="complete-list">Complete list of publications</h2>\n};
$o .= qq{<p class="note">This list includes all my publications recorded in the University of Glasgow’s <a href="https://eprints.gla.ac.uk/view/author/9066.html">Enlighten repository</a>, together with more recent publications recorded by Crossref under my <a href="https://orcid.org/0000-0002-4610-8266">ORCID iD</a>. It has $total entries from $first to the present.</p>\n};
my %years; push @{ $years{$_->{year}} }, $_ for @all;
for my $y (sort { $b <=> $a } keys %years) {
  $o .= qq{<h3 id="year-$y">$y</h3>\n<ul class="refs">\n} . join('', map { entry($_) } @{ $years{$y} }) . "</ul>\n";
}
$o .= "</section>\n";
spit('_build/src/complete-pubs.frag.html', $o);

my @spec = grep { $_->{special} } @$add;
spit('_build/src/special-more.frag.html', qq{<ul class="refs">\n} . join('', map { entry($_) } sort { $b->{year} <=> $a->{year} } @spec) . "</ul>\n");

my %stat = (total => $total, articles => $count{article} // 0, books => $count{book} // 0, other => $count{in} // 0, first => $first);
spit('_build/src/stats.json', encode_json(\%stat));
print join(', ', map { "$_=$stat{$_}" } sort keys %stat), "\n";
