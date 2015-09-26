package Number::RGB;

use strict;
use warnings;

# VERSION

use vars qw[$CONSTRUCTOR_SPEC];
use Carp;
use Scalar::Util qw[looks_like_number];
use Params::Validate qw[:all];
use base qw[Class::Accessor::Fast];
use Attribute::Handlers 0.99;

sub import {
	my $class  = shift;
	my $caller = (caller)[0];
	eval qq[
		package $caller;
		use Attribute::Handlers;
		sub RGB :ATTR(SCALAR) { goto &$class\::RGB }
		package $class;
	];
}

use overload fallback => 1,
	'""'  => \&as_string,
	'+'   => sub { shift->_op_math('+',  @_) },
	'-'   => sub { shift->_op_math('-',  @_) },
	'*'   => sub { shift->_op_math('*',  @_) },
	'/'   => sub { shift->_op_math('/',  @_) },
	'%'   => sub { shift->_op_math('%',  @_) },
	'**'  => sub { shift->_op_math('**', @_) },
	'<<'  => sub { shift->_op_math('<<', @_) },
	'>>'  => sub { shift->_op_math('>>', @_) },
	'&'   => sub { shift->_op_math('&',  @_) },
	'^'   => sub { shift->_op_math('^',  @_) },
	'|'   => sub { shift->_op_math('|',  @_) };

sub new {
	my $class = shift;
	my %params = validate( @_,  $CONSTRUCTOR_SPEC );
	croak "$class->new() requires parameters" unless keys %params;

	my %rgb;
	if ( defined $params{rgb} ) {
		@rgb{qw[r g b]} = @{$params{rgb}};
	} elsif ( defined $params{rgb_number} ) {
		return $class->new(rgb => [($params{rgb_number})x3]);
	} elsif ( defined $params{hex} ) {
		my $hex = $params{hex};
		$hex =~ s/^#//;
		$hex =~ s/(.)/$1$1/g if length($hex) == 3;
		@rgb{qw[r g b]} = map hex, $hex =~ /(.{2})/g;
	}

	$class->SUPER::new(\%rgb);
}

__PACKAGE__->mk_accessors( qw[r g b] );

sub rgb       { [ map $_[0]->$_, qw[r g b] ] }
sub hex       { '#' . join '', map { substr sprintf('0%x',$_[0]->$_), -2 } qw[r g b] }
sub hex_uc    { uc shift->hex }
sub as_string {
	join ',', map $_[0]->$_, qw[r g b]
}

sub _op_math {
	my ($self,$op, $other, $reversed) = @_;
	ref($self)->new(rgb => [
		map {
			my $x = $self->$_;
			my $y = ref($other) && overload::Overloaded($other) ? $other->$_ : $other;
			int eval ($reversed ? "$y $op $x" : "$x $op $y");
		} qw[r g b]
	] );
}

sub new_from_guess {
	my ($class, $value) = @_;

    my $is_single_rgb = looks_like_number($value) && $value>=0 && $value<=255;
	foreach my $param ( keys %{$CONSTRUCTOR_SPEC} ) {
        next if $param eq 'hex' and $is_single_rgb;
		my $self = eval { $class->new($param => $value) };
		return $self if defined $self;
	}
	croak "$class->new_from_guess() couldn't guess type for ($value)";
}

sub RGB :ATTR(SCALAR) {
	my ($var, $data) = @_[2,4];
	$$var = __PACKAGE__->new_from_guess(@$data);
}

$CONSTRUCTOR_SPEC = {
    rgb => {
        type      => ARRAYREF,
        optional  => 1,
        callbacks => {
        	'three elements'    => sub { 3 == @{$_[0]} },
        	'only digits'       => sub { 0 == grep /\D/, @{$_[0]} },
        	'between 0 and 255' => sub { 3 == grep { $_ >= 0 && $_ <= 255 } @{$_[0]} },
        },
    },
    rgb_number => {
    	type      => SCALAR,
    	optional  => 1,
    	callbacks => {
    		'only digits'       => sub { $_[0] !~ /\D/ },
    		'between 0 and 255' => sub { $_[0] >= 0 && $_[0] <= 255 },
    	},
    },
    hex => {
    	type      => SCALAR,
    	optional  => 1,
    	callbacks => {
    		'hex format' => sub { $_[0] =~ /^#?(?:[\da-f]{3}|[\da-f]{6})$/i },
    	},
    }
};

1;

__END__

=encoding utf8

=head1 NAME

Number::RGB - Manipulate RGB Tuples

=head1 SYNOPSIS

  use Number::RGB;
  my $white :RGB(255);
  my $black :RGB(0);

  my $gray = $black + (($white - $black) / 2);

  my @rgb = @{ $white->rgb };
  my $hex = $black->hex;

  my $blue   = Number::RGB->new(rgb => [0,0,255]);
  my $green  = Number::RGB->new(hex => '#00FF00');

  my $red :RGB(255,0,0);

  my $purple = $blue + $green;
  my $yellow = $red  + $green;

=head1 DESCRIPTION

This module creates RGB tuple objects and overloads their operators to
make RGB math easier. An attribute is also exported to the caller to
make construction shorter.

=head2 Methods

=head3 C<new>

  my $red   = Number::RGB->new(rgb => [255,0,0])
  my $blue  = Number::RGB->new(hex => '#0000FF');
  my $black = Number::RGB->new(rgb_number => 0);

This constructor accepts named parameters. One of three parameters are
required.

C<rgb> is a array reference containing three intergers within the range
of C<0..255>. In order, each interger represents I<red>, I<green>, and
I<blue>.

C<hex> is a hexidecimal representation of an RGB tuple commonly used in
Cascading Style Sheets. The format begins with an optional hash (C<#>)
and follows with three groups of hexidecimal numbers represending
I<red>, I<green>, and I<blue> in that order.

C<rgb_number> is a single integer to use for each of the three primary colors.
This is shorthand to create I<white>, I<black>, and all shades of
I<gray>.

This method throws an exception on error.

=head3 C<new_from_guess>

  my $color = Number::RGB->new_from_guess( ... );

This constructor tries to guess the format being used and returns a
tuple object. If it can't guess, an exception will be thrown.

I<Note:> a single number between C<0..255> will I<never> be interpreted as
a hex shorthand. You'll need to explicitly prepend C<#> character to
disambiguate and force hex mode.

=head3 C<r>

Accessor and mutator for the I<red> value.

=head3 C<g>

Accessor and mutator for the I<green> value.

=head3 C<b>

Accessor and mutator for the I<blue> value.

=head3 C<rgb>

Returns a list reference containing three elements. In order they
represent I<red>, I<green>, and I<blue>.

=head3 C<hex>

Returns a hexidecimal represention of the tuple conforming to the format
used in Cascading Style Sheets.

=head3 C<hex_uc>

Returns the same thing as L</hex>, but any hexidecimal numbers that
include C<'A'..'F'> will be uppercased.

=head3 C<as_string>

Returns a string representation of the tuple.  For example, I<white>
would be the string C<255,255,255>.

=head2 Attributes

=head3 C<:RGB()>

  my $red   :RGB(255,0,0);
  my $blue  :RGB(#0000FF);
  my $white :RGB(0);

This attribute is exported to the caller and provides a shorthand wrapper
around L</new_from_guess>.

=for pod_spiffy hr

=head1 REPOSITORY

=for pod_spiffy start github section

Fork this module on GitHub:
L<https://github.com/zoffixznet/Number-RGB>

=for pod_spiffy end github section

=head1 BUGS

=for pod_spiffy start bugs section

To report bugs or request features, please use
L<https://github.com/zoffixznet/Number-RGB/issues>

If you can't access GitHub, you can email your request
to C<bug-Number-RGB at rt.cpan.org>

=for pod_spiffy end bugs section

=head1 MAINTAINER

This module is currently maintained by:

=for pod_spiffy author ZOFFIX

=head1 AUTHOR

=for pod_spiffy start author section

=for pod_spiffy author CWEST

=for pod_spiffy end author section

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut