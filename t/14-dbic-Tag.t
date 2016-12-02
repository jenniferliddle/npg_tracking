use strict;
use warnings;

use English qw(-no_match_vars);

use Test::More tests => 13;
use Test::Deep;
use Test::Exception;
use Test::MockModule;

use t::dbic_util;

use Readonly;

Readonly::Scalar my $ABSURD_ID => 100_000_000;


use_ok('npg_tracking::Schema::Result::Tag');


my $schema = t::dbic_util->new->test_schema();
my $test;

lives_ok { $test = $schema->resultset('Tag')->new( {} ) }
         'Create test object';


throws_ok { $test->check_row_validity() }
          qr/Argument required/ms,
          'Exception thrown for no argument supplied';


is( $test->check_row_validity('no_such_tag'), undef, 'Invalid tag' );
is( $test->check_row_validity($ABSURD_ID),    undef, 'Invalid tag id' );

my $row = $test->check_row_validity('all_control');

is(
    ( ref $row ),
    'npg_tracking::Schema::Result::Tag',
    'Valid tag...'
);

is( $row->id_tag(), 7, '...and correct row' );

$row = $test->check_row_validity(1);

is( ( ref $row ), 'npg_tracking::Schema::Result::Tag', 'Valid tag id...' );
is( $row->tag(), 'good', '...and correct row' );


my $row2 = $test->_insist_on_valid_row(1);

cmp_deeply( $row, $row2, 'Internal method returns same row' );


{
    my $broken_db_test =
        Test::MockModule->new('DBIx::Class::ResultSet');

    $broken_db_test->mock( count => sub { return 2; } );

    $test = $schema->resultset('Tag')->new( {} );

    throws_ok { $test->check_row_validity(1) }
              qr/Panic![ ]Multiple[ ]tag[ ]rows[ ]found/msx,
             'Exception thrown for multiple db matches';

    $broken_db_test->mock( count => sub { return 0; } );
    is( $test->check_row_validity(1), undef, 'Return undef for no matches' );

    throws_ok { $test->_insist_on_valid_row(1) }
              qr/Invalid[ ]identifier:[ ]1/msx,
              'Internal validator croaks as it\'s supposed to';
}


1;
