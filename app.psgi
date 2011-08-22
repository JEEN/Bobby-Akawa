use 5.014;
use strict;
use warnings;
use Tatsumaki;
use Tatsumaki::Error;
use Tatsumaki::Application;
use Time::HiRes;

package DashboardPollHandler {
  use base qw(Tatsumaki::Handler);
  __PACKAGE__->asynchronous(1);
  use Tatsumaki::MessageQueue;
  $Tatsumaki::MessageQueue::BacklogLength = 100;

  sub get {
    my($self, $channel) = @_;

    $channel ||= 1;

    my $mq = Tatsumaki::MessageQueue->instance($channel);
    my $client_id = $self->request->param('client_id')
        or Tatsumaki::Error::HTTP->throw(500, "'client_id' needed");
    $mq->poll_once($client_id, sub { $self->on_new_event(@_) });
  }

  sub on_new_event {
    my($self, @events) = @_;
    $self->write(\@events);
    $self->finish;
  }
}

package DashboardPostHandler {
  use base qw(Tatsumaki::Handler);
  use Encode;

  sub post {
    my($self, $channel) = @_;

    $channel ||= 1;

    my $v = $self->request->parameters;
    my $mq = Tatsumaki::MessageQueue->instance($channel);

    $mq->publish({
        type => "message", id => $v->{id}, name => Encode::decode_utf8($v->{name}),
        lat => $v->{lat}, lng => $v->{lng}, icon => $v->{icon}, people => $v->{people}, 
        created_at => $v->{created_at}, address => $self->request->address,
        time => scalar Time::HiRes::gettimeofday, 
    });
    $self->write({ success => 1 });
  }

}

package DashboardHandler {
  use base qw(Tatsumaki::Handler);

  sub get {
    my($self, $channel) = @_;
    $self->render('dashboard.html');
  }
}

package main {
  use File::Basename;

  my $app = Tatsumaki::Application->new([
    "/dashboard/poll" => 'DashboardPollHandler',
    "/dashboard/post" => 'DashboardPostHandler',
    "/dashboard/" => 'DashboardHandler',
  ]);

  $app->template_path(dirname(__FILE__) . "/templates");
  $app->static_path(dirname(__FILE__) . "/static");

  return $app->psgi_app;
}
