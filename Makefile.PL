use inc::Module::Install;

name 'Bobby';
all_from 'lib/Bobby.pm';

requires 'Tatsumaki';
requires 'namespace::autoclean';
requires 'Config::ZOMG';
requires 'Furl';
requires 'Plack::Middleware::OAuth';
requires 'Plack::Middleware::ReverseProxy';
WriteAll;
