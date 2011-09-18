use strict;
use warnings;
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Session;
use Plack::Test;

use Test::More tests => 4;
use Dancer qw/:syntax :tests/;

set apphandler => 'PSGI';
set session    => 'PSGI';

get '/' => sub {
    my $placksession = Plack::Session->new(Dancer::SharedData->request->{env});
    
    is(session->id, $placksession->id, 'session->id() returns same as Plack::Session->new($env)->id()');

    session(foo => 'bar');
    is($placksession->get('foo'), 'bar', 'session write');
    
    $placksession->set(xxx => 'yyy');
    is(session('xxx'), 'yyy', 'session read');
    
    is_deeply(
        session(),
        Dancer::SharedData->request->{env}->{'psgix.session'},
        'session() returns same as $env->{"psgix.session"}'
    );
    
    "ok";
};

my $app = Dancer->start;

test_psgi(
    app => builder {
        enable 'Session';
        $app;
    },
    client => sub {
        my $cb = shift;
        my $res = $cb->(GET '/');
        fail $res->status_line unless $res->is_success
    },
);
