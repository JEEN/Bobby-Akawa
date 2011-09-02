use 5.014;
use strict;
use warnings;
use Tatsumaki;
use Tatsumaki::HTTPClient;
use Tatsumaki::Error;
use Tatsumaki::Application;
use Time::HiRes;
use JSON::XS;

our $OAUTH_TOKEN = '3IY3E4YGHFJUMIF4UQECELXIFYRKIZRWRPQFWLTJVFIB4RMY';
our $LIMIT = 10;

our $CLIENT_ID = '0Z5WKEHGKJYNM0Z1VRXNG3ZC1T02DLTH1JLK4SXCU5V4RFWS';
our $CLIENT_SECRET = 'I1HN2BJ2EHYZT2HZD2GUYQVTQN55GURLJS1RHLYL1OBII1HC';
our $CALLBACK_URL = "http://bobby.silex.kr/authenticate_receive";

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

package DashboardVenueHandler {
  use base qw(Tatsumaki::Handler);
  use Furl;
  use JSON::XS;

  sub get {
    my ($self, $venue_id) = @_;

    my $v = $self->request->parameters;
    my $furl = Furl->new->get((sprintf 'https://api.foursquare.com/v2/venues/%s?oauth_token=%s', $venue_id, $OAUTH_TOKEN));
    my $content = decode_json($furl->content);

    my $venue = $content->{response}->{venue};
    my $r = {
      url           => $venue->{url},
      foursquareUrl => $venue->{shortUrl},
      checkinCount  => $venue->{stats}->{checkinsCount},
      usersCount    => $venue->{stats}->{usersCount},
      contact  => $venue->{contact}->{formattedPhone},
      beenHere => $venue->{beenHere}->{count},
      photos   => [ map { @{ $_->{items} } } grep { scalar @{ $_->{items} } > 0 } @{ $venue->{photos}->{groups} } ],
    };

    $self->write($r);
  }
}

package DashboardUpdateHandler {
  use base qw(Tatsumaki::Handler);
  __PACKAGE__->asynchronous(1);  

  sub get {
    my ($self, $oauth_token) = @_;

    my $client = Tatsumaki::HTTPClient->new;
    my $url = sprintf 'https://api.foursquare.com/v2/users/self/checkins?oauth_token=%s&limit=%d', $OAUTH_TOKEN, $LIMIT;
    $client->get($url, $self->async_cb(sub { $self->on_response(@_) } ));
  }

  sub on_response {
    my ($self, $res) = @_;

    if ($res->is_error) {
      Tatsumaki::Error::HTTP->throw(500);
    }
    my $data = JSON::XS::decode_json($res->content);

    my $mq = Tatsumaki::MessageQueue->instance(1);

    my $count;
    for my $item (@{ $data->{response}->{checkins}->{items} }) {
      my @people = map { $_  } $item->{shout} =~ /(\@[^ ]+)/g;

      my $v = {
        id   => $item->{venue}->{id},
        name => $item->{venue}->{name},
        lat        => $item->{venue}->{location}->{lat},
        lng        => $item->{venue}->{location}->{lng},
        icon       => $item->{venue}->{categories} ? $item->{venue}->{categories}->[0]->{icon} : '',
        people     => join(" ", @people),
        created_at => $item->{createdAt},
      };

      $mq->publish({
        type => "message", id => $v->{id}, name => Encode::decode_utf8($v->{name}),
        lat => $v->{lat}, lng => $v->{lng}, icon => $v->{icon}, people => $v->{people},
        created_at => $v->{created_at}, address => $self->request->address,
        time => scalar Time::HiRes::gettimeofday,
      });
      $count++;
    }
    $self->write({ success => 1, count => $count });
    $self->finish;
  }
}

package DashboardHandler {
  use base qw(Tatsumaki::Handler);

  sub get {
    my($self, $channel) = @_;
    $self->render('dashboard.html');
  }
}

package AuthenticateHandler {
  use base qw(Tatsumaki::Handler);

  sub get {
    my $self = shift;

    $self->res->redirect(sprintf "https://foursquare.com/oauth2/authenticate?client_id=%s&response_type=code&redirect_uri=%s", $CLIENT_ID, $CALLBACK_URL);
  }
}

package AuthReceiveHandler {
  use base qw(Tatsumaki::Handler);

  sub get {
    my $self = shift;
   
    my $v = $self->req->parameters;
    warn $v->{code};

    my $client = Tatsumaki::HTTPClient->new;
    $client->get(sprintf "https://foursquare.com/oauth2/access_token?client_id=%s&client_secret=%s&grant_type=authorization_code&redirect_uri=%s&code=%s", $CLIENT_ID, $CLIENT_SECRET, $CALLBACK_URL, $v->{code}, $self->async_cb(sub { $self->on_response(@_) })); 
  }

  sub on_response {
    my ($self, $res) = @_;

    if ($res->is_error) {
      Tatsumaki::Error::HTTP->throw(500);
    }
    my $data = JSON::XS::decode_json($res->content);
    warn $data->{access_token};
    $self->write($data->{access_token});
  }
}

package main {
  use File::Basename;

  my $app = Tatsumaki::Application->new([
    "/dashboard/poll" => 'DashboardPollHandler',
    "/dashboard/post" => 'DashboardPostHandler',
    '/dashboard/venue/(\w+)' => 'DashboardVenueHandler',
    "/dashboard/update" => 'DashboardUpdateHandler',
    "/dashboard/" => 'DashboardHandler',
    "/authenticate" => 'AuthenticateHandler',
    "/authenticate_receive" => 'AuthReceiveHandler',
  ]);

  $app->template_path(dirname(__FILE__) . "/templates");
  $app->static_path(dirname(__FILE__) . "/static");

  return $app->psgi_app;
}
