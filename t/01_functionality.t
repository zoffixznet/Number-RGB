use Test::More qw[no_plan];
use strict; $^W = 1;
BEGIN { use_ok 'Number::RGB' }

my $white :RGB(255);
my $black :RGB(0);

is( "$white", "255,255,255", "white" );
is( "$black", "0,0,0", "black" );

my $gray = $black + ( ( $white - $black ) / 2 );

is( "$gray",    "127,127,127", "gray" );
ok( eq_array( $gray->rgb, [ 127, 127, 127 ] ), "rgb()" );
is( $gray->hex, '#7f7f7f', "hex()");
