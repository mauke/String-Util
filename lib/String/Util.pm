package String::Util;
use strict;
use Carp;
use overload;


# version
our $VERSION = '1.30';


#------------------------------------------------------------------------------
# opening POD
#

=head1 NAME

String::Util -- String processing utilities

=head1 SYNOPSIS

  use String::Util ':all';

  # "crunch" whitespace and remove leading/trailing whitespace
  $val = crunch($val);

  # does this value have "content", does it contain something besides whitespace?
  if (hascontent $val) {...}

  # format for display in a web page
  $val = htmlesc($val);

  # format for display in a web page table cell
  $val = cellfill($val);

  # remove leading/trailing whitespace
  $val = trim($val);

  # ensure defined value
  $val = define($val);

  # repeat string x number of times
  $val = repeat($val, $iterations);

  # remove leading/trailing quotes
  $val = unquote($val);

  # remove all whitespace
  $val = no_space($val);

  # remove trailing \r and \n, regardless of what
  # the OS considers an end-of-line
  $val = fullchomp($val);

  # or call in void context:
  fullchomp $val;

  # encrypt string using random seed
  $val = randcrypt($val);

  # are these two values equal, where two undefs count as "equal"?
  if (eqq $a, $b) {...}

  # are these two values different, where two undefs count as "equal"?
  if (neqq $a, $b) {...}

  # get a random string of some specified length
  $val = randword(10);

=head1 DESCRIPTION

String::Util provides a collection of small, handy utilities for processing
strings.

=head1 INSTALLATION

String::Util can be installed with the usual routine:

  perl Makefile.PL
  make
  make test
  make install

=head1 FUNCTIONS

=cut

#
# opening POD
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# export
#
use base 'Exporter';
use vars qw[@EXPORT_OK %EXPORT_TAGS];

# the following functions accept a value and return a modified version of
# that value
push @EXPORT_OK, qw[
	collapse     crunch     htmlesc    trim      ltrim
	rtrim        define     repeat     unquote   no_space
	nospace      fullchomp  randcrypt  jsquote   cellfill
	crunchlines
];

# the following functions return true or false based on their input
push @EXPORT_OK, qw[
	hascontent  nocontent eqq equndef neqq neundef
	startswith  endswith  contains];

# the following function returns a random string of some type
push @EXPORT_OK, qw[ randword randpost ];

# the following function returns the unicode values of a string
push @EXPORT_OK, qw[ ords deords ];

%EXPORT_TAGS = ('all' => [@EXPORT_OK]);
#
# export
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# collapse
#

=head2 collapse($string), crunch($string)

C<collapse()> collapses all whitespace in the string down to single spaces.
Also removes all leading and trailing whitespace.  Undefined input results in
undefined output.

C<crunch()> is the old name for C<collapse()>. I decided that "crunch" never
sounded right. Spaces don't go "crunch", they go "poof" like a collapsing
ballon. However, C<crunch()> will continue to work as an alias for
C<collapse()>.

  $var = collapse("  Hello     world!    "); # "Hello world!"

=cut

sub collapse {
	my ($val) = @_;

	if (defined $val) {
		$val =~ s|^\s+||s;
		$val =~ s|\s+$||s;
		$val =~ s|\s+| |sg;
	}

	return $val;
}

sub crunch {
	return collapse(@_);
}
#
# collapse
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# hascontent
#

=head2 hascontent($scalar), nocontent($scalar)

hascontent() returns true if the given argument is defined and contains
something besides whitespace.

An undefined value returns false.  An empty string returns false.  A value
containing nothing but whitespace (spaces, tabs, carriage returns, newlines,
backspace) returns false.  A string containing any other characters (including
zero) returns true.

C<nocontent()> returns the negation of C<hascontent()>.

  $var = hascontent("");  # False
  $var = hascontent(" "); # False
  $var = hascontent("a"); # True

  $var = nocontent("");   # True
  $var = nocontent("a");  # False

=cut

sub hascontent {
	my ($val) = @_;

	defined($val) or return 0;
	$val =~ m|\S|s or return 0;

	return 1;
}

sub nocontent {
	return ! hascontent(@_);
}

#
# hascontent
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# trim
#

=head2 trim($string)

Returns the string with all leading and trailing whitespace removed.
Trim on undef returns "".

  $var = trim(" my string  "); # "my string"

=cut

sub trim {
	my ($val, %opts) = @_;

	if (!defined($val)) {
		return "";
	}

	if (defined $val) {
		# trim left
		if ( defined($opts{'left'}) ? $opts{'left'} : 1 )
			{ $val =~ s|^\s+||s }

		# trim right
		if ( defined($opts{'right'}) ? $opts{'left'} : 1 )
			{ $val =~ s|\s+$||s }
	};

	return $val;
}
#
# trim
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# ltrim, rtrim
#

=head2 ltrim(), rtrim()

ltrim trims B<leading> whitespace.

rtrim trims B<trailing> whitespace.

=cut

sub ltrim {
	return trim($_[0], right=>0);
}

sub rtrim {
	return trim($_[0], left=>0);
}

#
# ltrim, rtrim
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# no_space
#

=head2 no_space($string)

Removes B<all> whitespace characters from the given string. This includes spaces
between words

  $var = no_space("  Hello World!   "); # "HelloWorld!"

=cut

sub no_space {
	my ($val) = @_;

	if (defined $val)
		{ $val =~ s|\s+||gs }

	return $val;
}

# alias nospace to no_space
sub nospace { return no_space(@_) }

#
# no_space
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# htmlesc
#

=head2 htmlesc(string)

Formats a string for literal output in HTML.  An undefined value is returned as
an empty string.

htmlesc() is very similar to CGI.pm's escapeHTML.  However, there are a few
differences. htmlesc() changes an undefined value to an empty string, whereas
escapeHTML() returns undefs as undefs.

=cut

sub htmlesc {
	my ($val) = @_;

	if (defined $val) {
		$val =~ s|\&|&amp;|g;
		$val =~ s|\"|&quot;|g;
		$val =~ s|\<|&lt;|g;
		$val =~ s|\>|&gt;|g;
	}
	else {
		$val = '';
	}

	return $val;
}
#
# htmlesc
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# cellfill
#

=head2 cellfill($string)

Formats a string for literal output in an HTML table cell.  Works just like
htmlesc() except that strings with no content (i.e. are undef or are just
whitespace) are returned as C<&nbsp;>.

=cut

sub cellfill{
	my ($val) = @_;

	if (hascontent($val)) {
		$val = htmlesc($val);
	}

	else {
		$val = '&nbsp;';
	}

	return $val;
}
#
# cellfill
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# jsquote
#

=head2 jsquote($string)

Escapes and quotes a string for use in JavaScript.  Escapes single quotes and
surrounds the string in single quotes.  Returns the modified string.

=cut

sub jsquote {
	my ($str) = @_;

	# Escape single quotes.
	$str =~ s|'|\\'|gs;

	# Break up anything that looks like a closing HTML tag.  This modification
	# is necessary in an HTML web page.  It is unnecessary but harmless if the
	# output is used in a JavaScript document.
	$str =~ s|</|<' + '/|gs;

	# break up newlines
	$str =~ s|\n|\\n|gs;

	# surround in quotes
	$str = qq|'$str'|;

	# return
	return $str;
}
#
# jsquote
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# unquote
#

=head2 unquote($string)

If the given string starts and ends with quotes, removes them. Recognizes
single quotes and double quotes.  The value must begin and end with same type
of quotes or nothing is done to the value. Undef input results in undef output.
Some examples and what they return:

  unquote(q|'Hendrix'|);   # Hendrix
  unquote(q|"Hendrix"|);   # Hendrix
  unquote(q|Hendrix|);     # Hendrix
  unquote(q|"Hendrix'|);   # "Hendrix'
  unquote(q|O'Sullivan|);  # O'Sullivan

B<option:> braces

If the braces option is true, surrounding braces such as [] and {} are also
removed. Some examples:

  unquote(q|[Janis]|, braces=>1);  # Janis
  unquote(q|{Janis}|, braces=>1);  # Janis
  unquote(q|(Janis)|, braces=>1);  # Janis

=cut

sub unquote {
	my ($val, %opts) = @_;

	if (defined $val) {
		my $found = $val =~ s|^\`(.*)\`$|$1|s or
			$val =~ s|^\"(.*)\"$|$1|s or
			$val =~ s|^\'(.*)\'$|$1|s;

		if ($opts{'braces'} && ! $found) {
			$val =~ s|^\[(.*)\]$|$1|s or
			$val =~ s|^\((.*)\)$|$1|s or
			$val =~ s|^\{(.*)\}$|$1|s;
		}
	}

	return $val;
}
#
# unquote
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# define
#

=head2 define($scalar)

Takes a single value as input. If the value is defined, it is returned
unchanged.  If it is not defined, an empty string is returned.

This subroutine is useful for printing when an undef should simply be
represented as an empty string.  Perl already treats undefs as empty strings in
string context, but this subroutine makes the
L<warnings module|http://perldoc.perl.org/warnings.html>
go away.  And you B<ARE> using warnings, right?

=cut

sub define {
	my ($val) = @_;

	# if overloaded object, get return value and
	# concatenate with string (which defines it).
	if (ref($val) && overload::Overloaded($val)) {
		local $^W = 0;
		$val = $val . '';
	}

	defined($val) or $val = '';
	return $val;
}
#
# define
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# repeat
#

=head2 repeat($string, $count)

Returns the given string repeated the given number of times. The following
command outputs "Fred" three times:

 print repeat('Fred', 3), "\n";

Note that repeat() was created a long time based on a misunderstanding of how
the perl operator 'x' works.  The following command using 'x' would perform
exactly the same as the above command.

 print 'Fred' x 3, "\n";

Use whichever you prefer.

=cut

sub repeat {
	my ($val, $count) = @_;
	return ($val x int($count));
}
#
# repeat
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# randword
#

=head2 randword($length, %options)

Returns a random string of characters. String will not contain any vowels (to
avoid distracting dirty words). First argument is the length of the return
string. So this code:

  foreach my $idx (1..3) {
      print randword(4), "\n";
  }

would output something like this:

  kBGV
  NCWB
  3tHJ

If the string 'dictionary' is sent instead of an integer, then a word is
randomly selected from a dictionary file.  By default, the dictionary file
is assumed to be at /usr/share/dict/words and the shuf command is used to
pull out a word.  The hash %String::Util::PATHS sets the paths to the
dictionary file and the shuf executable.  Modify that hash to change the paths.
So this code:

  foreach my $idx (1..3) {
      print randword('dictionary'), "\n";
  }

would output something like this:

  mustache
  fronds
  browning

B<option:> alpha

If the alpha option is true, only alphabetic characters are returned, no
numerals. For example, this code:

  foreach my $idx (1..3) {
      print randword(4, alpha=>1), "\n";
  }

would output something like this:

  qrML
  wmWf
  QGvF

B<option:> numerals

If the numerals option is true, only numerals are returned, no alphabetic
characters. So this code:

  foreach my $idx (1..3) {
      print randword(4, numerals=>1), "\n";
  }

would output something like this:

  3981
  4734
  2657

B<option:> strip_vowels

This option is true by default.  If true, vowels are not included in the
returned random string. So this code:

  foreach my $idx (1..3) {
      print randword(4, strip_vowels=>1), "\n";
  }

would output something like this:

  Sk3v
  pV5z
  XhSX

=cut

# path information for WC
our %PATHS = (
	wc => '/usr/bin/wc',
	shuf => '/usr/bin/shuf',
	words => '/usr/share/dict/words',
	head => '/usr/bin/head',
	tail => '/usr/bin/tail',
);

sub randword {
	my ($count, %opts) = @_;
	my ($rv, $char, @chars, $paths);
	$rv = '';

	# check syntax
	defined($count) or croak 'syntax: randword($count)';

	# dictionary word
	if ($count =~ m|^dict|si) {
		# loop until acceptable word is found
		DICTIONARY:
		while (1) {
			my ($cmd, $line_count, $line_num, $word);

			# use Encode module
			require Encode;
			require Number::Misc;

			# get line count
			$cmd = qq|$PATHS{'wc'} -l "$PATHS{'words'}"|;
			($line_count) = `$cmd`;
			$line_count =~ s|\s.*||s;

			# get random line
			$line_num = Number::Misc::rand_in_range(0, $line_count);

			# untaint line number
			unless ($line_num =~ m|^([0-9]+)$|s) { die "invalid line number: $line_num" }
			$line_num = $1;

			# get random word
			$cmd = qq[$PATHS{'head'} -$line_num "$PATHS{'words'}" | $PATHS{'tail'} -1];
			($word) = `$cmd`;
			$word =~ s|\s.*||si;
			$word =~ s|'.*||si;
			$word = lc($word);

			# only allow words that are all letters
			if ($opts{'letters_only'}) {
				unless ($word =~ m|^[a-z]+$|s)
					{ next DICTIONARY }
			}

			# check for max length
			if ($opts{'maxlength'}) {
				if ( length($word) > $opts{'maxlength'} )
					{ next DICTIONARY }
			}

			# encode unless specifically opted not to do so
			unless ( defined($opts{'encode'}) && (! $opts{'encode'}) )
				{ $word = Encode::encode_utf8($word) }

			# return
			return $word;
		}
	}

	# alpha only
	if ($opts{'alpha'})
		{ @chars = ('a' .. 'z', 'A' .. 'Z') }

	# else alpha and numeral
	else
		{ @chars = ('a' .. 'z', 'A' .. 'Z', '0' .. '9') }

	# defaults
	defined($opts{'strip_vowels'}) or $opts{'strip_vowels'} = 1;

	while (length($rv) < $count) {
		$char = rand();

		# numerals only
		if ($opts{'numerals'}) {
			$char =~ s|^0.||;
			$char =~ s|\D||g;
		}

		# character random word
		else {
			$char = int( $char * ($#chars + 1) );
			$char = $chars[$char];
			next if($opts{'strip_vowels'} && $char =~ m/[aeiouy]/i);
		}

		$rv .= $char;
	}

	return substr($rv, 0, $count);
}
#
# randword
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# eqq
# formerly equndef
#

=head2 eqq($scalar1, $scalar2)

Returns true if the two given values are equal.  Also returns true if both
are undef.  If only one is undef, or if they are both defined but different,
returns false. Here are some examples and what they return.

  $var = eqq('x', 'x'), "\n";      # True
  $var = eqq('x', undef), "\n";    # False
  $var = eqq(undef, undef), "\n";  # True

=cut

# alias equndef to eqq
sub equndef { return eqq(@_) }

sub eqq {
	my ($str1, $str2) = @_;

	# if both defined
	if ( defined($str1) && defined($str2) )
		{ return $str1 eq $str2 }

	# if neither are defined
	if ( (! defined($str1)) && (! defined($str2)) )
		{ return 1 }

	# only one is defined, so return false
	return 0;
}
#
# eqq
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# neqq
# formerly neundef
#

=head2 neqq($scalar1, $scalar2)

The opposite of neqq, returns true if the two values are *not* the same.
Here are some examples and what they return.

  $var = neqq('x', 'x'), "\n";      # False
  $var = neqq('x', undef), "\n";    # True
  $var = neqq(undef, undef), "\n";  # False

=cut

sub neundef {
	return eqq(@_) ? 0 : 1;
}

sub neqq {
	return eqq(@_) ? 0 : 1;
}
#
# neqq
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# pod to note renaming of equndef to eqq and neundef to neqq
#

=head2 equndef(), neundef()

equndef() has been renamed to eqq(). neundef() has been renamed to neqq().
Those old names have been kept as aliases.

=cut

#
# pod to note renaming of equndef to eqq and neundef to neqq
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# fullchomp
#

=head2 fullchomp($string)

Works like chomp, but is a little more thorough about removing \n's and \r's
even if they aren't part of the OS's standard end-of-line.

Undefs are returned as undefs.

=cut

sub fullchomp {
	my ($line) = @_;
	defined($line) and $line =~ s|[\r\n]+$||s;
	defined(wantarray) and return $line;
	$_[0] = $line;
}
#
# fullchomp
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# randcrypt
#

=head2 randcrypt($string)

Crypts the given string, seeding the encryption with a random two character
seed.

=cut

sub randcrypt {
	my ($pw) = @_;
	my ($rv);
	$rv = crypt($pw, randword(2));
	return $rv;
}
#
# randcrypt
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# randpost
#

=head2 randpost(%opts)

Returns a string that sorta looks like one or more paragraphs.

B<option:> word_count

Sets how many words should be in the post.  By default a random number from
1 to 250 is used.

B<option:> par_odds

Sets the odds of starting a new paragraph after any given word.  By default the
value is .05, which means paragraphs will have an average about twenty words.

B<option:> par

Sets the string to put at the end or the start and end of a paragraph.
Defaults to two newlines for the end of a pargraph.

If this option is a single scalar, that string is added to the end of each
paragraph.

To set both the start and end string, use an array reference.  The first
element should be the string to put at the start of a paragraph, the second
should be the string to put at the end of a paragraph.

B<option:> max_length

Sets the maximum length of the returned string, including paragraph delimiters.

=cut

sub randpost {
	my (%opts) = @_;
	my (@rv, $str, $pars, $par_odds, $par_open, $par_close);
	my ($word_count);


	# determine word count
	if (defined($opts{'word_count'}) || defined($opts{'words'}))
		{ $word_count = $opts{'word_count'} || $opts{'words'} }
	else
		{ $word_count = int(rand() * 250) }

	# determine paragraph odds
	if (defined $opts{'par_odds'})
		{ $par_odds = $opts{'par_odds'} }
	else
		{ $par_odds = .05 }


	#- - - - - - - - - - - - - - - - - - - - - - - - -
	# determine paragraph separator
	#
	if (defined $opts{'par'}) {
		$pars = 1;

		if (ref $opts{'par'}) {
			$par_open = $opts{'par'}->[0];
			$par_close = $opts{'par'}->[1];
		}

		else {
			$par_open = '';
			$par_close = $opts{'par'};
		}
	}

	else {
		$par_open = '';
		$par_close = "\n\n";
	}
	#
	# determine paragraph separator
	#- - - - - - - - - - - - - - - - - - - - - - - - -


	#- - - - - - - - - - - - - - - - - - - - - - - - -
	# build array of words
	#
	foreach my $i (0..$word_count) {
		my ($word, $p);

		if ( $i && ($i < $word_count-1) && $pars && (rand() < $par_odds) ) {
			$word = $par_close . $par_open;
		}

		else {
			my $word_length = int(rand() * 15);
			$word = lc randword($word_length, alpha=>1, strip_vowels=>0, %opts);
		}

		push @rv, $word;
	}
	#
	# build array of words
	#- - - - - - - - - - - - - - - - - - - - - - - - -


	# clean up return value
	$str = $par_open . join(' ', @rv) . $par_close;
	$str =~ s|\s+$||;
	$str =~ s|^\s+||;
	$str =~ s| +\n|\n|g;
	$str =~ s|\n +|\n|g;
	$str =~ s| +| |g;

	# if maximum length sent, reduce to that length
	if ($opts{'max_length'}) {
		$str = substr($str, 0, $opts{'max_length'});
		$str =~ s|\s+$||s;
	}

	# return words separated by spaces
	return $str;
}
#
# randpost
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# ords
#

=head2 ords($string)

Returns the given string represented as the ascii value of each character.

  $var = ords('Hendrix'); # {72}{101}{110}{100}{114}{105}{120}

B<options>

=over 4

=item * convert_spaces=>[true|false]

If convert_spaces is true (which is the default) then spaces are converted to
their matching ord values. So, for example, this code:

  $var = ords('a b', convert_spaces=>1); # {97}{32}{98}

This code returns the same thing:

  $var = ords('a b');                    # {97}{32}{98}

If convert_spaces is false, then spaces are just returned as spaces. So this
code:

  ords('a b', convert_spaces=>0);        # {97} {98}


=item * alpha_nums

If the alpha_nums option is false, then characters 0-9, a-z, and A-Z are not
converted. For example, this code:

  $var = ords('a=b', alpha_nums=>0); # a{61}b

=back

=cut

sub ords {
	my ($str, %opts) = @_;
	my (@rv, $show_chars);

	# default options
	%opts = (convert_spaces=>1, alpha_nums=>1, %opts);

	# get $show_chars option
	$show_chars = $opts{'show_chars'};

	# split into individual characters
	@rv = split '', $str;

	# change elements to their unicode numbers
	CHAR_LOOP:
	foreach my $char (@rv) {
		# don't convert space if called so
		if ( (! $opts{'convert_spaces'}) && ($char =~ m|^\s$|s) )
			{ next CHAR_LOOP }

		# don't convert alphanums
		if (! $opts{'alpha_nums'}) {
			if ( $char =~ m|^[a-z0-9]$|si) {
				next CHAR_LOOP;
			}
		}

		my $rv = '{';

		if ($show_chars)
			{ $rv .= $char . ':' }

		$rv .= ord($char) . '}';

		$char = $rv;
	}

	# return words separated by spaces
	return join('', @rv);
}
#
# ords
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# deords
#

=head2 deords($string)

Takes the output from ords() and returns the string that original created that
output.

  $var = deords('{72}{101}{110}{100}{114}{105}{120}'); # 'Hendrix'

=cut

sub deords {
	my ($str) = @_;
	my (@tokens, $rv);
	$rv = '';

	# get tokens
	@tokens = split(m|[\{\}]|s, $str);
	@tokens = grep {length($_)} @tokens;

	# build return string
	foreach my $token (@tokens) {
		$rv .= chr($token);
	}

	# return
	return $rv;
}
#
# deords
#------------------------------------------------------------------------------

=head2 contains($string, $substring)

Checks if the string contains substring

  $var = contains("Hello world", "Hello");   # true
  $var = contains("Hello world", "llo wor"); # true
  $var = contains("Hello world", "QQQ");     # false

=cut

sub contains {
	my $str    = shift() || "";
	my $substr = shift();

	if (!$substr) {
		$substr = $str;
		$str    = $_;
	}

	my $ret = index($str, $substr, 0) != -1;

	return $ret;
}

=head2 startswith($string, $substring)

Checks if the string starts with the characters in substring

  $var = startwidth("Hello world", "Hello"); # true
  $var = startwidth("Hello world", "H");     # true
  $var = startwidth("Hello world", "Q");     # false

=cut

sub startswith {
	my $str    = shift() || "";
	my $substr = shift();

	if (!$substr) {
		$substr = $str;
		$str    = $_;
	}

	my $ret = index($str, $substr, 0) == 0;

	return $ret;
}

=head2 endswith($string, $substring)

Checks if the string ends with the characters in substring

  $var = endswidth("Hello world", "world");   # true
  $var = endswidth("Hello world", "d");       # true
  $var = endswidth("Hello world", "QQQ");     # false

=cut

sub endswith {
	my $str    = shift() || "";
	my $substr = shift();

	if (!$substr) {
		$substr = $str;
		$str    = $_;
	}

	my $len   = length($substr);
	my $start = length($str) - $len;

	my $ret = index($str, $substr, $start) != -1;

	return $ret;
}

#------------------------------------------------------------------------------
# crunchlines
#

=head2 crunchlines($string)

Compacts contiguous newlines into single newlines.  Whitespace between newlines
is ignored, so that two newlines separated by whitespace is compacted down to a
single newline.

  $var = crunchlines("x\n\n\nx"); # "x\nx";

=cut

sub crunchlines {
	my ($str) = @_;

	while($str =~ s|\n[ \t]*\n|\n|gs)
		{}

	$str =~ s|^\n||s;
	$str =~ s|\n$||s;

	return $str;
}
#
# crunchlines
#------------------------------------------------------------------------------


# return true
1;


__END__

=head1 TERMS AND CONDITIONS

Copyright (c) 2012-2016 by Miko O'Sullivan.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the same terms
as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHORS

Miko O'Sullivan
F<miko@idocs.com>

Scott Baker
F<scott@perturb.org>

=cut



#------------------------------------------------------------------------------
# module info
# This info is used by a home-grown CPAN builder. Please leave it as it is.
#
{
	// include in CPAN distribution
	include : 1,

	// test scripts
	test_scripts : {
		'Util/tests/test.pl' : 1,
	},
}
#
# module info
#------------------------------------------------------------------------------
