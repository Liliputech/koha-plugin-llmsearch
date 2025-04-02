package Koha::Plugin::Com::BibLibre::LLMSearch;

## It's good practice to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);
use OpenAI::API;

## We will also need to include any Koha libraries we want to access
use C4::Context;

use Koha::DateUtils qw( dt_from_string );

use Data::Dumper;
use Mojo::JSON qw(decode_json);
use URI::Escape qw(uri_unescape);
use HTTP::Request;
use Scalar::Util qw(refaddr);

## Here we set our plugin version
our $VERSION = "1";
our $MINIMUM_VERSION = "22.11";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name            => 'LLM Search',
    author          => 'A. Suzuki',
    date_authored   => '2024-10-26',
    date_updated    => "2024-10-26",
    minimum_version => $MINIMUM_VERSION,
    maximum_version => undef,
    version         => $VERSION,
    description     => 'Brings a new way to query koha in natural language using LLM assistant',
    namespace       => 'llmsearch',
};

## This is the minimum code required for a plugin's 'new' method
## More can be added, but none should be removed
sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

sub install {
    my ( $self, $args ) = @_;
    return 1;
}

sub send_request_openai {
   my ($self, $search_query) = @_;
   my $api_key = $self->retrieve_data('api_key');
   # Custom base URL
   my $base_url = $self->retrieve_data('base_url');

   # Create a new OpenAI::API object with custom base_url
   my $openai = OpenAI::API->new(
       	config => { api_key   => $api_key,
	            api_base  => $custom_base_url,
        });

   my $res = $openai->chat(
       messages => [
	   {"role" => "system", "content" => ""},
	   {"role" => "user",   "content" => $search_query },
       ]);

   return $res;
}

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};
    unless ($cgi->param('save')) {
	my $template = $self->get_template({ file => 'configure.tt' });
	$template->param(
	    base_url => $self->retrieve_data('base_url'),
	    api_key => $self->retrieve_data('api_key'),
	    model => $self->retrieve_data('model'),
	);

	$self->output_html( $template->output() );
    }
    else {
        $self->store_data(
            {
                base_url           => $cgi->param('base_url') // 'https://api.openai.com/v1/',
                api_key            => $cgi->param('api_key'),
		model              => $cgi->param('model'),
                last_configured_by => C4::Context->userenv->{'number'},
            }
        );
        $self->go_home();
    }
}

sub api_routes {
    my ( $self, $args ) = @_;
    my $spec_str;
    $spec_str = $self->mbf_read('openapi.json');
    my $spec = decode_json($spec_str);
    return $spec;
}

sub api_namespace {
    my ( $self ) = @_;
    return 'llmsearch';
}
1;
