package Number::RGB;
# $Id: RGB.pm,v 1.2 2004/03/06 16:17:02 cwest Exp $
use strict;

use vars qw[$VERSION $CONSTRUCTOR_SPEC];
$VERSION = (qw$Revision: 1.2 $)[1];

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

=cut

use Carp;
use Params::Validate qw[:all];
use base qw[Class::Accessor::Fast];
use Attribute::Handlers;

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

=head1 DESCRIPTION

This module creates RGB tuple objects and overloads their operators to
make RGB math easier. An attribute is also exported to the caller to
make construction shorter.

=head2 Methods

=over 4

=item C<new()>

  my $red   = Number::RGB->new(rgb => [255,0,0])
  my $blue  = Number::RGB->new(hex => '#0000FF');
  my $black = Number::RGB->new(rgb_number => 0);

This constructor accepts named parameters. One of three parameters are
required.

C<rgb> is a list reference containing three intergers within the range
of C<0..255>. In order, each interger represents I<red>, I<green>, and
I<blue>.

C<hex> is a hexidecimal representation of an RGB tuple commonly used in
Cascading Style Sheets. The format begins with an optional hash (C<#>)
and follows with three groups of hexidecimal numbers represending
I<red>, I<green>, and I<blue> in that order.

C<rgb_number> is a single integer which represents all primary colors.
This is shorthand to create I<white>, I<black>, and all shades of
I<gray>.

This method throws and exception on error, which should be caught with
C<eval>.

=cut

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

=pod

=item C<r()>

Accessor and mutator for the I<red> value.

=item C<g()>

Accessor and mutator for the I<green> value.

=item C<b()>

Accessor and mutator for the I<blue> value.

=cut

__PACKAGE__->mk_accessors( qw[r g b] );

=pod

=item C<rgb()>

Returns a list reference containing three elements. In order they
represent I<red>, I<green>, and I<blue>.

=item C<hex()>

Returns a hexidecimal represention of the tuple conforming to the format
used in Cascading Style Sheets.

=item C<hex_uc()>

Returns the same thing as C<hex()>, but any hexidecimal numbers that
include C<'A'..'F'> will be uppercased.

=item C<as_string()>

Returns a string representation of the tuple.  For example, I<white>
would be the string C<255,255,255>.

=cut

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

=pod

=item C<new_from_guess()>

  my $color = Number::RGB->new_from_guess(input());

This constructor tries to guess the format being used and returns a
tuple object. If it can't guess, an exception will be thrown.

=back

=cut

sub new_from_guess {
	my ($class, $value) = @_;
	foreach my $param ( keys %{$CONSTRUCTOR_SPEC} ) {
		my $self = eval { $class->new($param => $value) };
		return $self if defined $self;
	}
	croak "$class->new_from_guess() couldn't guess type for ($value)";
}

=head2 Attributes

=over 4

=item C<:RGB()>

  my $red   :RGB(255,0,0);
  my $blue  :RGB(#0000FF);
  my $white :RGB(0);

This attribute is exported to the caller and provides a shorthand wrapper
around C<new_from_guess()>.

=back

=cut

sub RGB :ATTR(SCALAR) {
	my ($var, $data) = @_[2,4];
	$$var = __PACKAGE__->new_from_guess($data);
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

=head1 AUTHOR

Casey West, <F<casey@geeknest.com>>.

=head1 COPYRIGHT

  Copyright (c) 2004 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut
