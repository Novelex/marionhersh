# usage: perl build.pl <build dir> <output dir>
# Pages keep the same URLs as the old WordPress site (e.g. /trade-union/).
use strict; use warnings;
use File::Path qw(make_path);
my ($B,$O)=@ARGV;
sub slurp { local $/; open my $f,'<',$_[0] or die "$_[0]: $!"; my $s=<$f>; $s }
sub spit  { my ($p,$s)=@_; (my $d=$p) =~ s{/[^/]+$}{}; make_path($d); open my $o,'>',$p or die "$p: $!"; print $o $s; close $o; print "wrote $p\n"; }

my @nav = (
  ['',                             'Home'],
  ['publications/',                'Publications'],
  ['special-issues-and-sessions/', 'Special issues & sessions'],
  ['research-participation/',      'Research participation'],
  ['projects/',                    'Projects'],
  ['trade-union/',                 'Trade union'],
);

# [output dir ('' = root), content file, title, description, current nav, main class]
my $paper = 'older-autistic-adults-experiences-attitudes-and-support-needs/';
my @pages = (
 ['',                             'index.html',        'Marion Hersh', 'Marion Hersh, Senior Lecturer in Biomedical Engineering at the University of Glasgow: assistive technology, older autistic people, mobility for blind people and engineering ethics.', '', 'home'],
 ['publications/',                'publications.html', 'Publications | Marion Hersh', 'Books, journal papers and book chapters by Marion Hersh on assistive technology, accessibility, autism and engineering ethics.', 'publications/', 'page'],
 ['special-issues-and-sessions/', 'special.html',      'Special Issues and Sessions | Marion Hersh', 'Journal special issues and conference sessions edited or organised by Marion Hersh.', 'special-issues-and-sessions/', 'page'],
 ['research-participation/',      'participate.html',  'Research Participation | Marion Hersh', 'Current studies looking for participants: Calm Spaces, recommender systems, and disabled researchers in AI.', 'research-participation/', 'page'],
 ['projects/',                    'projects.html',     'Projects | Marion Hersh', 'Older Autistic Kit (OAK): a co-production project with older autistic people, including the Calm Spaces website and forum.', 'projects/', 'page'],
 ['trade-union/',                 'union.html',        'Trade Union | Marion Hersh', 'Marion Hersh’s UCU work: Scotland Green Network, NEC elections and an interview on being a disabled union activist.', 'trade-union/', 'page'],
 ['recent-posts/',                'recent.html',       'Recent Posts | Marion Hersh', 'News and recent posts from Marion Hersh.', '', 'page'],
 [$paper,                         'older-autistic-adults.html', 'Older Autistic Adults’ Experiences, Attitudes and Support Needs | Marion Hersh', 'Empirical study of the living and employment situations, aspirations and barriers of 78 autistic people aged 50–79.', 'publications/', 'page'],
 ['404/',                         'notfound.html',     'Page not found | Marion Hersh', 'Page not found.', '', 'page'],
);

# Old addresses that now live elsewhere
my %redirects = ('podcast/' => 'publications/', 'archive/' => 'recent-posts/');

# Assemble the stylesheet and version it, so browsers never use a stale copy
use Digest::MD5 qw(md5_hex);
my $css = join '', map { slurp("$B/$_") } qw(css-base.css css-home.css css-inner.css);
spit("$O/assets/style.css", $css);
my $cssver = substr(md5_hex($css), 0, 8);

my $layout = slurp("$B/layout.html");
$layout =~ s/\{\{CSSVER\}\}/$cssver/g;
for my $p (@pages) {
  my ($dir,$file,$title,$desc,$cur,$mc)=@$p;
  my $root = $dir eq '' ? './' : '../' x (() = $dir =~ m{/}g);
  my $c = slurp("$B/content/$file");
  $c =~ s/\{\{INCLUDE ([\w.-]+)\}\}/slurp("$B\/$1")/ge;
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
