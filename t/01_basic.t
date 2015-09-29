use strict;
use warnings;
use Test::More;

use Plack::Middleware::RequestId;

can_ok 'Plack::Middleware::RequestId', qw/new/;

# write more tests

done_testing;
