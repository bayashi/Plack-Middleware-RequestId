use strict;
use Plack::Builder;
use HTTP::Request::Common;
use LWP::UserAgent;

use Test::More 0.88;
use Plack::Test;

my $res = sub { [ 200, ['Content-Type' => 'text/plain'], ['OK'] ] };

{
    my $app = builder {
        enable 'RequestId';
        $res;
    };
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/');
            is $res->code, 200;
            is $res->content_type, 'text/plain';
            is $res->content, 'OK';
            my $id = $res->header('X-Request-Id');
            is length($id), 32;
            like $id, qr/^[0-9A-F]+$/i;
            is $id, $Plack::Middleware::RequestId::request_id;
            note $id if $ENV{AUTHOR_TEST};
    };
    test_psgi $app, $cli;
}

{
    my $app = builder {
        enable 'RequestId', http_header => 'X-Foo';
        $res;
    };
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/');
            is $res->code, 200;
            is $res->content_type, 'text/plain';
            is $res->content, 'OK';
            my $id = $res->header('X-Foo');
            is length($id), 32;
            like $id, qr/^[0-9A-F]+$/i;
            note $id if $ENV{AUTHOR_TEST};
    };
    test_psgi $app, $cli;
}

{
    my $app = builder {
        enable 'RequestId', id_generator => sub { 123 };
        $res;
    };
    my $cli = sub {
            my $cb = shift;
            my $res = $cb->(GET '/');
            is $res->code, 200;
            is $res->content_type, 'text/plain';
            is $res->content, 'OK';
            is $res->header('X-Request-Id'), 123;
    };
    test_psgi $app, $cli;
}

done_testing;
