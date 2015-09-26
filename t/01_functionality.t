#!perl

use Test::More;
use Test::Exception;
use strict;
use warnings FATAL => 'all';
use Hash::Util qw/hash_traversal_mask/;
BEGIN { use_ok 'Number::RGB' }

{ # Regression check against https://github.com/zoffixznet/Number-RGB/issues/1
    #... the test doesn't always detect the issue, but "detects sometimes"
    #... is better than nothing. If the issue returns, someone will eventually
    #... get a failing test
    lives_ok {
        for ( 1..3 ) {
            for ( 0..255 ) {
                my $c = Number::RGB->new_from_guess($_);
                die ":RGB($_) was incorrectly interpreted as $c"
                    unless "$c" eq "$_,$_,$_";
            }
        }
    } 'guess from single 0..255 seems to work';
}

my $black :RGB(0);
my $white :RGB(255);
is( "$white", "255,255,255", "white" );
is( "$black", "0,0,0", "black" );

my $gray = $black + ( ( $white - $black ) / 2 );

is( "$gray",    "127,127,127", "gray" );
ok( eq_array( $gray->rgb, [ 127, 127, 127 ] ), "rgb()" );
is( $gray->hex, '#7f7f7f', "hex()");

done_testing;