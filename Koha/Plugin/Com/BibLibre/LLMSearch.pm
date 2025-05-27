package Koha::Plugin::Com::BibLibre::LLMSearch;

## It's good practice to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);
use Template;
use Mojo::JSON qw(decode_json);
use Data::Dumper;


## Here we set our plugin version
our $VERSION = "1";
our $MINIMUM_VERSION = "23.11";

## Here is our metadata, some keys are required, some are optional
our $metadata = {
    name            => 'LLM Search',
    author          => 'A. Suzuki',
    date_authored   => '2025-05-26',
    date_updated    => "2025-05-26",
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

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};
    unless ($cgi->param('save')) {
	my $template = $self->get_template({ file => 'configure.tt' });
	$template->param(
	    base_url      => $self->retrieve_data('base_url'),
	    api_key       => $self->retrieve_data('api_key'),
	    model         => $self->retrieve_data('model'),
	    system_prompt => $self->retrieve_data('system_prompt'),
	);

	$self->output_html( $template->output() );
    }
    else {
        $self->store_data(
            {
                base_url           => $cgi->param('base_url') // 'https://api.mistral.ai/v1/',
                api_key            => $cgi->param('api_key'),
		model              => $cgi->param('model') // 'mistral-small-latest',
		system_prompt      => $cgi->param('system_prompt'),
                last_configured_by => C4::Context->userenv->{'number'},
            }
        );
        $self->go_home();
    }
}

sub opac_js {
    my ( $self ) = @_;
    return '<script>' . $self->mbf_read('purify.min.js') . '</script>'
	 . '<script>' . $self->mbf_read('chat.js') . '</script>';
}

sub opac_head {
    my ( $self ) = @_;
    my $css = $self->mbf_read('chat.css');
    return '<style>' . $css . '</style>';
}

sub api_routes {
    my ( $self, $args ) = @_;
    my $spec_str;
    $spec_str = $self->mbf_read('openapi.json');
    my $spec = decode_json($spec_str);
    return $spec;
}

sub static_routes {
    my ( $self, $args ) = @_;

    my $spec_str = $self->mbf_read('staticapi.json');
    my $spec     = decode_json($spec_str);

    return $spec;
}

sub api_namespace {
    my ( $self ) = @_;
    return 'llmsearch';
}
1;
