# Parses the University of Glasgow Enlighten author page (saved as research/enlighten-9066.html)
# into research/enlighten-9066.json.  usage: perl _build/research/parse-enlighten.pl < _build/research/enlighten-9066.html > _build/research/enlighten-9066.json
use strict; use warnings; use JSON::PP;
use Encode qw(decode); local $/; my $h = decode("UTF-8", scalar <STDIN>);   # the page is UTF-8
my @out; my %coauth; my $year;
# walk year headings and entries in order
while ($h =~ /(<h2>(\d{4})|<p>(.*?)<\/p>)/gs) {
  if (defined $2) { $year = $2; next }
  my $p = $3; next unless $p =~ /eprints\.gla\.ac\.uk\/(\d+)\//;
  $p =~ s/<!--.*?-->//gs;
  my @names = $p =~ /<span class="person_name">([^<]+)<\/span>/g;
  my ($eid, $title) = $p =~ /<a href="https:\/\/eprints\.gla\.ac\.uk\/(\d+)\/">(.*?)<\/a>/s;
  my ($doi) = $p =~ /href="https:\/\/doi\.org\/([^"]+)"/;
  (my $rest = $p) =~ s/.*?<a href="https:\/\/eprints\.gla\.ac\.uk\/\d+\/">.*?<\/a>//s;
  $rest =~ s/<span class="id_number">.*?<\/span>//gs;
  $rest =~ s/<[^>]+>//g; $rest =~ s/\s+/ /g; $rest =~ s/^ | $//g; $rest =~ s/,$//;
  $title =~ s/<[^>]+>//g; $title =~ s/\s+/ /g; $title =~ s/^ | $//g;
  my $type = $p =~ /journal_volume/ ? 'article' : $rest =~ /^In:/ ? 'in' : $rest =~ /ISBN/ ? 'book' : 'other';
  $coauth{$_}++ for grep { !/^Hersh,/ } @names;
  push @out, { year => $year, eid => $eid, authors => \@names, title => $title, rest => $rest, doi => $doi, type => $type };
}
my %t; $t{$_->{type}}++ for @out;
print STDERR scalar(@out), " items; types: ", join(', ', map {"$_=$t{$_}"} sort keys %t), "; co-authors: ", scalar(keys %coauth), "; years ", $out[-1]{year}, "-", $out[0]{year}, "\n";
print JSON::PP->new->utf8->canonical->pretty->encode(\@out);
