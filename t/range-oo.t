#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Data::Dumper;
use Test::More tests => 10;

my $debug = 0;

BEGIN { use_ok( 'range_oo 0.3.0' ); }

use feature 'say';    # temporarily...
use Data::Printer;    # temporarily...

my $range = range_oo->new();

my @ranges = (
    [ -20, -10 ],
    [ -5,  5 ],
    [ 10,  20 ],
    [ 40,  50 ],
    [ 80,  90 ],
    [ 85,  100 ],
    [ 120, 150 ],
    [ 200, 250 ]
);
for ( @ranges) {
    my ($start, $end) = @$_;
    $range->add_range_oo( $start, $end );
}
is_deeply(
    $range,
    {
        add   => { -20 => -10, -5 => 5, 10 => 20, 40 => 50, 80 => 90, 85 => 100, 120 => 150, 200 => 250 },
        rm    => {},
        messy => 1
    },
    'add 8 initial ranges'
);

subtest 'range check' => sub {
    plan tests => 8;

    my @in_range_neg   = $range->is_in_range_oo(-15);
    my @in_range_left  = $range->is_in_range_oo(40);
    my @in_range_mid   = $range->is_in_range_oo(45);
    my @in_range_right = $range->is_in_range_oo(50);
    my @out_before     = $range->is_in_range_oo(-30);
    my @out_mid        = $range->is_in_range_oo(105);
    my @out_after      = $range->is_in_range_oo(300);

    is_deeply( \@in_range_neg,   [ 1, -20, -10 ], 'value in range (left border)' );
    is_deeply( \@in_range_left,  [ 1, 40,  50 ],  'value in range (left border)' );
    is_deeply( \@in_range_mid,   [ 1, 40,  50 ],  'value in range (middle)' );
    is_deeply( \@in_range_right, [ 1, 40,  50 ],  'value in range (right border)' );
    is_deeply( \@out_before, [0], 'value out of range (before all)' );
    is_deeply( \@out_mid,    [0], 'value out of range (interior)' );
    is_deeply( \@out_after,  [0], 'value out of range (after all)' );

    is_deeply(
        $range,
        {
            add   => { -20 => -10, -5 => 5, 10 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 },
            rm    => {},
            messy => 0
        },
        'ranges collapsed during is_in_range check'
    );
};

@ranges = ( [ 0, 44 ], [ 131, 139 ], [ 241, 300 ] );
for (@ranges) {
    my ( $start, $end ) = @$_;
    $range->rm_range_oo( $start, $end );
}
is_deeply(
    $range,
    {
        add   => { -20 => -10, -5 => 5, 10 => 20, 40  => 50,  80  => 100, 120 => 150, 200 => 250 },
        rm    => { 0 => 44, 131 => 139, 241 => 300 },
        messy => 1
    },
    'remove 3 ranges'
);

subtest 'range length' => sub {
    plan tests => 2;

    my $length = $range->range_length_oo;
    is( $length, 106, 'range length' );
    is_deeply(
        $range,
        {
            add   => { -20 => -10, -5 => -1, 45 => 50, 80 => 100, 120 => 130, 140 => 150, 200 => 240 },
            rm    => {},
            messy => 0
        },
        'ranges collapsed during range_length'
    );
};

subtest 'output ranges' => sub {
    plan tests => 2;

    $range->add_range_oo( 300, 400 );
    my $scalar_out = $range->output_ranges_oo;
    is( $scalar_out, '-20..-10,-5..-1,45..50,80..100,120..130,140..150,200..240,300..400', 'output range string');
    $range->add_range_oo( 500, 600 );
    my %hash_out = $range->output_ranges_oo;
    is_deeply(
        \%hash_out,
        { -20 => -10, -5 => -1, 45 => 50, 80 => 100, 120 => 130, 140 => 150, 200 => 240, 300 => 400, 500 => 600 },
        'output range hash'
    );
};

subtest 'output integers in range' => sub {
    plan tests => 2;

    $range->rm_range_oo( 45,  600 );
    my $scalar_out = $range->output_integers_oo;
    is( $scalar_out, '-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-5,-4,-3,-2,-1', 'output integers string');

    $range->rm_range_oo( -20, -10 );
    $range->add_range_oo( 5, 10 );
    my @array_out = $range->output_integers_oo;
    is_deeply(
        \@array_out,
        [ -5, -4, -3, -2, -1, 5, 6, 7, 8, 9, 10 ],
        'output integers array'
    );
};

$range = range_oo->new();
$range->add_range_oo( -20, -10 );
$range->rm_range_oo( -20, -19 );
$range->rm_range_oo( -16, -15 );
$range->rm_range_oo( -12, -11 );
$range->collapse_ranges_oo;
is_deeply(
    $range,
    {
        add   => { -18 => -17, -14 => -13, -10 => -10 },
        rm    => {},
        messy => 0
    },
    'collapse after removing multiple ranges from a single range'
);

my $test_name;
my $start;
my $end;
my $range_ref;

subtest 'add various ranges' => sub {
    plan tests => 22;

    $start     = 5;
    $end       = 8;
    $test_name = "add + collapse range ($start - $end) that ends before 1st";
    $range_ref = { add => { 5 => 8, 10 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 5;
    $end       = 15;
    $test_name = "add + collapse range ($start - $end) that begins before 1st and ends in 1st";
    $range_ref = { add => { 5 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 5;
    $end       = 25;
    $test_name = "add + collapse range ($start - $end) that begins before 1st and ends between 1st and 2nd";
    $range_ref = { add => { 5 => 25, 40 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 5;
    $end       = 45;
    $test_name = "add + collapse range ($start - $end) that begins before 1st and ends in 2nd";
    $range_ref = { add => { 5 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 5;
    $end       = 60;
    $test_name = "add + collapse range ($start - $end) that begins before 1st and ends between 2nd and 3rd";
    $range_ref = { add => { 5 => 60, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 5;
    $end       = 90;
    $test_name = "add + collapse range ($start - $end) that begins before 1st and ends in 3rd";
    $range_ref = { add => { 5 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 15;
    $end       = 20;
    $test_name = "add + collapse range ($start - $end) that begins in 1st and ends in 1st";
    $range_ref = { add => { 10 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 15;
    $end       = 25;
    $test_name = "add + collapse range ($start - $end) that begins in 1st and ends between 1st and 2nd";
    $range_ref = { add => { 10 => 25, 40 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 15;
    $end       = 45;
    $test_name = "add + collapse range ($start - $end) that begins in 1st and ends in 2nd";
    $range_ref = { add => { 10 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 15;
    $end       = 60;
    $test_name = "add + collapse range ($start - $end) that begins in 1st and ends between 2nd and 3rd";
    $range_ref = { add => { 10 => 60, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 15;
    $end       = 90;
    $test_name = "add + collapse range ($start - $end) that begins in 1st and ends in 3rd";
    $range_ref = { add => { 10 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 25;
    $end       = 30;
    $test_name = "add + collapse range ($start - $end) that begins between 1st and 2nd and ends before 2nd";
    $range_ref = { add => { 10 => 20, 25 => 30, 40 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 25;
    $end       = 45;
    $test_name = "add + collapse range ($start - $end) that begins between 1st and 2nd and ends in 2nd";
    $range_ref = { add => { 10 => 20, 25 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 25;
    $end       = 60;
    $test_name = "add + collapse range ($start - $end) that begins between 1st and 2nd and ends between 2nd and 3rd";
    $range_ref = { add => { 10 => 20, 25 => 60, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 25;
    $end       = 90;
    $test_name = "add + collapse range ($start - $end) that begins between 1st and 2nd and ends in 3rd";
    $range_ref = { add => { 10 => 20, 25 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 5;
    $end       = 9;
    $test_name = "add + collapse range ($start - $end) adjacent to next range (first range)";
    $range_ref = { add => { 5 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 25;
    $end       = 39;
    $test_name = "add + collapse range ($start - $end) adjacent to next range (middle range)";
    $range_ref = { add => { 10 => 20, 25 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 190;
    $end       = 199;
    $test_name = "add + collapse range ($start - $end) adjacent to next range (last range)";
    $range_ref = { add => { 10 => 20, 40 => 50, 80 => 100, 120 => 150, 190 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 21;
    $end       = 25;
    $test_name = "add + collapse range ($start - $end) adjacent to previous range (first range)";
    $range_ref = { add => { 10 => 25, 40 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 51;
    $end       = 60;
    $test_name = "add + collapse range ($start - $end) adjacent to previous range (middle range)";
    $range_ref = { add => { 10 => 20, 40 => 60, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 251;
    $end       = 300;
    $test_name = "add + collapse range ($start - $end) adjacent to previous range (last range)";
    $range_ref = { add => { 10 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 300 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 51;
    $end       = 79;
    $test_name = "add + collapse range ($start - $end) adjacent to both previous and next ranges";
    $range_ref = { add => { 10 => 20, 40 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_add_collapse_test( $start, $end, $range_ref, $test_name );

};

subtest 'remove various ranges' => sub {
    plan tests => 12;

    $start     = 0;
    $end       = 9;
    $test_name = "remove + collapse range ($start - $end) before 1st";
    $range_ref = { add => { 10 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_rm_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 0;
    $end       = 10;
    $test_name = "remove + collapse range ($start - $end) that begins before 1st and ends on start of 1st";
    $range_ref = { add => { 11 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_rm_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 0;
    $end       = 15;
    $test_name = "remove + collapse range ($start - $end) that begins before 1st and ends in middle of 1st";
    $range_ref = { add => { 16 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_rm_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 0;
    $end       = 19;
    $test_name = "remove + collapse range ($start - $end) that begins before 1st and ends just before end of 1st";
    $range_ref = { add => { 20 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_rm_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 0;
    $end       = 20;
    $test_name = "remove + collapse range ($start - $end) that begins before 1st and ends at end of 1st";
    $range_ref = { add => { 40 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_rm_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 0;
    $end       = 45;
    $test_name = "remove + collapse range ($start - $end) that begins before 1st and ends in 2nd";
    $range_ref = { add => { 46 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_rm_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 50;
    $end       = 80;
    $test_name = "remove + collapse range ($start - $end) that begins at end of previous and ends at beginning of next";
    $range_ref = { add => { 10 => 20, 40 => 49, 81 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_rm_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 51;
    $end       = 79;
    $test_name = "remove + collapse range ($start - $end) that begins just before end of previous and ends just before beginning of next";
    $range_ref = { add => { 10 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_rm_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 130;
    $end       = 140;
    $test_name = "remove + collapse range ($start - $end) that begins and ends inside a range";
    $range_ref = { add => { 10 => 20, 40 => 50, 80 => 100, 120 => 129, 141 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_rm_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 75;
    $end       = 175;
    $test_name = "remove + collapse range ($start - $end) begins and ends outside of multiple ranges";
    $range_ref = { add => { 10 => 20, 40 => 50, 200 => 250 }, rm => {}, messy => 0 };
    base_rm_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 240;
    $end       = 260;
    $test_name = "remove + collapse range ($start - $end) that begins in last range and ends after";
    $range_ref = { add => { 10 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 239 }, rm => {}, messy => 0 };
    base_rm_collapse_test( $start, $end, $range_ref, $test_name );

    $start     = 251;
    $end       = 300;
    $test_name = "remove + collapse range ($start - $end) that begins just after last range";
    $range_ref = { add => { 10 => 20, 40 => 50, 80 => 100, 120 => 150, 200 => 250 }, rm => {}, messy => 0 };
    base_rm_collapse_test( $start, $end, $range_ref, $test_name );

};

sub base_add_collapse_test {
    my ( $start, $end, $range_ref, $test_name ) = @_;

    my $base_range_ref = build_base();
    $base_range_ref->add_range_oo( $start, $end );
    collapse_and_test( $base_range_ref, $range_ref, $test_name );
}

sub base_rm_collapse_test {
    my ( $start, $end, $range_ref, $test_name ) = @_;

    my $base_range_ref = build_base();
    $base_range_ref->rm_range_oo( $start, $end );
    collapse_and_test( $base_range_ref, $range_ref, $test_name );
}

sub build_base {
    my $range = range_oo->new();

    my @ranges = (
        [ 10,  20 ],
        [ 40,  50 ],
        [ 80,  90 ],
        [ 85,  100 ],
        [ 120, 150 ],
        [ 200, 250 ]
    );

    for ( @ranges) {
        my ($start, $end) = @$_;
        $range->add_range_oo( $start, $end );
    }

    $range->collapse_ranges_oo;

    return $range;
}

sub collapse_and_test {
    my ( $base_range_ref, $range_ref, $test_name ) = @_;

    $base_range_ref->collapse_ranges_oo;

    is_deeply( $base_range_ref, $range_ref, $test_name );
    print Dumper $base_range_ref if $debug;
}
