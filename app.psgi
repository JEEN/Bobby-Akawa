use Plack::Builder;
use Bobby;

my $app = Bobby->new->to_psgi;
builder {
  enable 'ReverseProxy';
  $app;
};

