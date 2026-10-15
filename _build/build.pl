# usage: perl build.pl <build dir> <output dir>
# Pages keep the same URLs as the old WordPress site (e.g. /trade-union/).
use strict; use warnings;
use File::Path qw(make_path);
my ($B,$O)=@ARGV;
sub slurp { local $/; open my $f,'<',$_[0] or die "$_[0]: $!"; my $s=<$f>; $s }
sub spit  { my ($p,$s)=@_; (my $d=$p) =~ s{/[^/]+$}{}; make_path($d); open my $o,'>',$p or die "$p: $!"; print $o $s; close $o; print "wrote $p\n"; }

my @nav = (
  [q(),                             q(Home)],
  [q(publications/),                q(Publications)],
  [q(special-issues-and-sessions/), q(Special Issues and Sessions)],
  [q(research-participation/),      q(Research Participation)],
  [q(projects/),                    q(Projects)],
  [q(trade-union/),                 q(Trade Union)],
);

# [output dir ('' = root), content file, title, description, current nav, main class]
my $paper = 'older-autistic-adults-experiences-attitudes-and-support-needs/';
my @pages = (
 # Titles follow the original site ("Page - marionhersh.org"); descriptions are sentences from each page.
 ['',                             'index.html',        'Marion Hersh - marionhersh.org', 'Senior Lecturer in Biomedical Engineering. I believe in working to make the world a better place for people, animals and the planet itself.', '', 'home'],
 ['publications/',                'publications.html', 'Publications - marionhersh.org', 'Books, Journal Papers, Book Chapters, On-line Encyclopedia Chapters.', 'publications/', 'page'],
 ['special-issues-and-sessions/', 'special.html',      'Special Issues and Sessions - marionhersh.org', 'Special Issues and Sessions.', 'special-issues-and-sessions/', 'page'],
 ['research-participation/',      'participate.html',  'Research Participation - marionhersh.org', 'Calm Spaces Website and Forum for Older autistic people. Designing Recommender Systems for Blind, Partially Sighted and Autistic People. AI Research and Disabled, Neurodivergent and Deaf Researchers and Other Professionals: Experiences and Attitudes.', 'research-participation/', 'page'],
 ['projects/',                    'projects.html',     'Projects - marionhersh.org', 'This project involves a co-design/co-production approach with older autistic people at the centre of it to investigating their experiences and support needs for participation, community development, empowerment and autonomy.', 'projects/', 'page'],
 ['trade-union/',                 'union.html',        'Trade Union - marionhersh.org', 'UCU Scotland Green Network. Solidarity to branches taking action or balloting. UCU NEC Elections. Interview with Marion Hersh and Christina Paine on being a disabled UCU activist.', 'trade-union/', 'page'],
 ['recent-posts/',                'recent.html',       'Recent Posts - marionhersh.org', 'Link to new article: Older Autistic Adults’ Experiences, Attitudes and Support Needs.', '', 'page'],
 [$paper,                         'older-autistic-adults.html', 'Older Autistic Adults’ Experiences, Attitudes and Support Needs - marionhersh.org', 'The paper presents new empirical data on the living and employment situations, aspirations and barriers to improving these situations of 78 autistic people aged 50-79.', 'publications/', 'page'],
 ['404/',                         'notfound.html',     'Page not found - marionhersh.org', 'Page not found.', '', 'page'],
);

# Old addresses that now live elsewhere
my %redirects = ('podcast/' => 'publications/', 'archive/' => 'recent-posts/');

# Assemble the stylesheet and version it, so browsers never use a stale copy
use Digest::MD5 qw(md5_hex);
my $css = join '', map { slurp("$B/$_") } qw(css-base.css css-home.css css-inner.css css-a11y.css);
spit("$O/assets/style.css", $css);
my $cssver = substr(md5_hex($css), 0, 8);

use JSON::PP;
my $stats = decode_json(slurp("$B/src/stats.json"));

my $layout = slurp("$B/layout.html");
$layout =~ s/\{\{CSSVER\}\}/$cssver/g;
for my $p (@pages) {
  my ($dir,$file,$title,$desc,$cur,$mc)=@$p;
  my $root = $dir eq '' ? './' : '../' x (() = $dir =~ m{/}g);
  my $c = slurp("$B/content/$file");
  1 while $c =~ s/\{\{INCLUDE ([\w.\/-]+)\}\}/slurp("$B\/$1")/ge;   # fragments may include fragments
  $c =~ s/\{\{STAT_(\w+)\}\}/$stats->{$1} \/\/ die "unknown statistic $1"/ge;   # publication totals from research.pl
  my $nav = join "\n", map { sprintf '        <li><a href="{{ROOT}}%s"%s>%s</a></li>', $_->[0], ($_->[0] eq $cur && $dir ne '404/' ? ' aria-current="page"' : ''), $_->[1] } @nav;
  my $h = $layout;
  $h =~ s/\{\{MAINCLASS\}\}/$mc/; $h =~ s/\{\{TITLE\}\}/$title/g; $h =~ s/\{\{DESC\}\}/$desc/g;
  $h =~ s/\{\{NAV\}\}/$nav/; $h =~ s/\{\{CONTENT\}\}/$c/;
  if ($dir eq '404/') {   # GitHub Pages serves /404.html from the site root for any path, so use absolute-from-root links
    $h =~ s/\{\{ROOT\}\}/\/marionhersh\//g; spit("$O/404.html", $h); next;
  }
  $h =~ s/\{\{ROOT\}\}/$root/g;
  spit("$O/${dir}index.html", $h);
}
for my $from (sort keys %redirects) {
  my $to = '../' . $redirects{$from};
  spit("$O/${from}index.html", qq{<!doctype html>\n<html lang="en-GB">\n<head>\n<meta charset="utf-8">\n<title>Moved</title>\n<meta name="robots" content="noindex">\n<meta http-equiv="refresh" content="0; url=$to">\n<link rel="canonical" href="$to">\n</head>\n<body>\n<p>This page has moved to <a href="$to">$to</a>.</p>\n</body>\n</html>\n});
}
