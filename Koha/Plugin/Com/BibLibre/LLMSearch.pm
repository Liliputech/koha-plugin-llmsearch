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
    my $table = $self->get_qualified_table_name('stats');
    warn "Install LLMSEARCH";
    return C4::Context->dbh->do("
           CREATE TABLE IF NOT EXISTS $table (
               id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
               timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
               categorycode VARCHAR(10),
               branchcode VARCHAR(10),
               enrolled_year YEAR,
               birth_year YEAR,
               sort1 VARCHAR(80),
               sort2 VARCHAR(80),
               opac_lang VARCHAR(10),
               tokens_sent INT UNSIGNED,
               tokens_received INT UNSIGNED
               ) ENGINE=InnoDB;
               ");
}

sub upgrade {
    my ( $self, $args ) = @_;

    my $dt = dt_from_string();
    $self->store_data( { last_upgraded => $dt->ymd('-') . ' ' . $dt->hms(':') } );

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
            only_logged   => $self->retrieve_data('only_logged'),
            enable_stats  => $self->retrieve_data('enable_stats'),
        );

        $self->output_html( $template->output() );
    }
    else {
        $self->store_data(
            {
                base_url           => $cgi->param('base_url') // 'https://api.mistral.ai/v1/chat/completions',
                api_key            => $cgi->param('api_key'),
                model              => $cgi->param('model') // 'mistral-small-latest',
                system_prompt      => $cgi->param('system_prompt') // $self->mbf_read('system_prompt.txt'),
                only_logged        => $cgi->param('only_logged') eq 'on' ? 1 : 0,
                enable_stats       => $cgi->param('enable_stats') eq 'on' ? 1 : 0,
                last_configured_by => C4::Context->userenv->{'number'},
            }
        );
        $self->go_home();
    }
}

sub is_allowed {
    my ( $self ) = @_;
    my $only_logged = $self->retrieve_data('only_logged');

    return 1
        unless $only_logged eq '1';

    return 1
        if defined C4::Context->userenv->{'number'};

    return 0;
}

sub opac_js {
    my ( $self ) = @_;
    return '<script src="https://cdn.jsdelivr.net/npm/dompurify/dist/purify.min.js"></script>'
        . '<script>' . $self->mbf_read('chat.js') . '</script>'
        if $self->is_allowed();
}

sub opac_head {
    my ( $self ) = @_;
    return '<style>' . $self->mbf_read('chat.css') . '</style>'
        if $self->is_allowed();
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
