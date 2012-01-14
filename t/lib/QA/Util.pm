# -*- Mode: perl; indent-tabs-mode: nil -*-

package QA::Util;

use utf8;
use strict;
use Data::Dumper;
use HTTP::Cookies;
use Test::More;
use Test::WWW::Selenium;
use WWW::Selenium::Util qw(server_is_running);

use base qw(Exporter);
@QA::Util::EXPORT = qw(
    trim
    url_quote
    random_string

    log_in
    logout
    file_bug_in_product
    create_bug
    edit_bug
    edit_bug_and_return
    go_to_bug
    go_to_home
    go_to_admin
    edit_product
    add_product
    open_advanced_search_page
    set_parameters

    get_selenium
    get_rpc_clients

    WAIT_TIME
    CHROME_MODE
);

# How long we wait for pages to load.
use constant WAIT_TIME => 60000;
use constant CONF_FILE =>  "../config/selenium_test.conf";
use constant CHROME_MODE => 1;
use constant NDASH => chr(0x2013);

#####################
# Utility Functions #
#####################

sub random_string {
    my $size = shift || 30; # default to 30 chars if nothing specified
    return join("", map{ ('0'..'9','a'..'z','A'..'Z')[rand 62] } (1..$size));
}

# Remove consecutive as well as leading and trailing whitespaces.
sub trim {
    my ($str) = @_;
    if ($str) {
      $str =~ s/[\r\n\t\s]+/ /g;
      $str =~ s/^\s+//g;
      $str =~ s/\s+$//g;
    }
    return $str;
}

# This originally came from CGI.pm, by Lincoln D. Stein
sub url_quote {
    my ($toencode) = (@_);
    $toencode =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/eg;
    return $toencode;
}

###################
# Setup Functions #
###################

sub get_config {
    # read the test configuration file
    my $conf_file = CONF_FILE;
    my $config = do($conf_file)
        or die "can't read configuration '$conf_file': $!$@";
}

sub get_selenium {
    my $chrome_mode = shift;
    my $config = get_config();

    if (!server_is_running) {
        die "Selenium Server isn't running!";
    }

    my $sel = Test::WWW::Selenium->new(
        host        => $config->{host},
        port        => $config->{port},
        browser     => $chrome_mode ? $config->{experimental_browser_launcher} : $config->{browser},
        browser_url => $config->{browser_url}
    );

    return ($sel, $config);
}

sub get_xmlrpc_client {
    my $config = get_config();
    my $xmlrpc_url = $config->{browser_url} . "/"
                    . $config->{bugzilla_installation} . "/xmlrpc.cgi";

    require QA::RPC::XMLRPC;
    # A temporary cookie jar that isn't saved after the script closes.
    my $cookie_jar = new HTTP::Cookies();
    my $rpc        = new QA::RPC::XMLRPC(proxy => $xmlrpc_url);
    $rpc->transport->cookie_jar($cookie_jar);
    return ($rpc, $config);
}

sub get_jsonrpc_client {
    my ($get_mode) = @_;
    require QA::RPC::JSONRPC;
    # A temporary cookie jar that isn't saved after the script closes.
    my $cookie_jar = new HTTP::Cookies();
    my $rpc = new QA::RPC::JSONRPC();
    $rpc->transport->cookie_jar($cookie_jar);
    # If we don't set a long timeout, then the Bug.add_comment test
    # where we add a too-large comment fails.
    $rpc->transport->timeout(180);
    $rpc->version($get_mode ? '1.1' : '1.0');
    $rpc->bz_get_mode($get_mode);
    return $rpc;
}

sub get_rpc_clients {
    my ($xmlrpc, $config) = get_xmlrpc_client();
    my $jsonrpc = get_jsonrpc_client();
    my $jsonrpc_get = get_jsonrpc_client('GET');
    return ($config, $xmlrpc, $jsonrpc, $jsonrpc_get);
}

################################
# Helpers for Selenium Scripts #
################################


sub go_to_home {
    my ($sel, $config) = @_;
    $sel->open_ok("/$config->{bugzilla_installation}/", undef, "Przejdź do strony głównej");
    # $sel->is_text_present("Strona główna");
    $sel->title_is("Bugzilla – Strona główna");
}

# Go to the home/login page and log in.
sub log_in {
    my ($sel, $config, $user) = @_;

    go_to_home($sel, $config);
    $sel->type_ok("Bugzilla_login_top", $config->{"${user}_user_login"}, "Wprowadź login użytkownika $user");
    $sel->type_ok("Bugzilla_password_top", $config->{"${user}_user_passwd"}, "Wprowadź hasło użytkownika $user");
    $sel->click_ok("log_in_top", undef, "Zaloguj się");
    $sel->wait_for_page_to_load(WAIT_TIME);
    #$sel->is_text_present("Strona główna", "Użytkownik jest zalogowany");
    $sel->title_is("Bugzilla – Strona główna", "Użytkownik jest zalogowany");
}

# Log out. Will fail if you are not logged in.
sub logout {
    my $sel = shift;

    $sel->click_ok("link=Wyloguj", undef, "Wyloguj"); #to odwoluje sie do tresci w linku a ta jest po polsku wiec ten polski tekst trzeba to wstawic
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    $sel->title_is("Wylogowano");
}

# Display the bug form to enter a bug in the given product.
sub file_bug_in_product {
    my ($sel, $product, $classification) = @_;

    $classification ||= "Unclassified";
    $sel->click_ok("link=Nowy", undef, "Utwórz nowy błąd");
    $sel->wait_for_page_to_load(WAIT_TIME);
    my $title = $sel->get_title();
    if ($title eq "Wybór kategorii") {
        ok(1, "More than one enterable classification available. Display them in a list");
        $sel->click_ok("link=$classification", undef, "Choose $classification");
        $sel->wait_for_page_to_load(WAIT_TIME);
        $title = $sel->get_title();
    }
    if ($title eq "Zgłaszanie błędu") {
        ok(1, "Wyświetl listę wprowadzalnych produktów");
        $sel->click_ok("link=$product", undef, "Wybrano $product");
        $sel->wait_for_page_to_load(WAIT_TIME);
    }
    else {
        ok(1, "Tylko jeden produkt jest dostępny w $classification. Pomijam stronę 'Wybierz produkt'.")
    }
    $sel->title_is("Zgłaszanie błędu: $product", "Wyświetlono formularz wprowadzania danych błędu");
}

sub create_bug {
    my ($sel, $bug_summary) = @_;
    my $ndash = NDASH;

    $sel->click_ok('commit');
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    my $bug_id = $sel->get_value('//input[@name="id" and @type="hidden"]');
    $sel->title_is("Błąd $bug_id $ndash $bug_summary", "Błąd numer $bug_id z opisem '$bug_summary'");
    return $bug_id;
}

sub edit_bug {
    my ($sel, $bug_id, $bug_summary, $options) = @_;
    my $ndash = NDASH;
    my $btn_id = $options ? $options->{id} : 'commit';

    $sel->click_ok($btn_id);
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    $sel->title_is("Błąd $bug_id $ndash $bug_summary", "Zapisano zmiany dla błędu $bug_id");
    # If the web browser doesn't support history.ReplaceState or has it turned off,
    # "Bug XXX processed" is displayed instead (as in Bugzilla 4.0 and older).
    # $sel->title_is("Bug $bug_id processed", "Changes submitted to bug $bug_id");
}

sub edit_bug_and_return {
    my ($sel, $bug_id, $bug_summary, $options) = @_;
    my $ndash = NDASH;

    edit_bug($sel, $bug_id, $bug_summary, $options);
    $sel->click_ok("link=błędu $bug_id"); #zwrpc uwage na forme wyrazu "bledu" - tak widnieje w polskim UI
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    $sel->title_is("Błąd $bug_id $ndash $bug_summary", "Wracam do błędu $bug_id");
}

# Go to show_bug.cgi.
sub go_to_bug {
    my ($sel, $bug_id) = @_;

    $sel->type_ok("quicksearch_top", $bug_id);
    $sel->click_ok("find_top", undef, "Przejdź do błędu $bug_id");
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    my $bug_title = $sel->get_title();
    utf8::encode($bug_title) if utf8::is_utf8($bug_title);
    $sel->title_like(qr/^Błąd $bug_id /, $bug_title);
}

# Go to admin.cgi.
sub go_to_admin {
    my $sel = shift;

    $sel->click_ok("link=Administracja", undef, "Przejdź do strony administracyjnej");
    $sel->wait_for_page_to_load(WAIT_TIME);
    $sel->is_text_present_ok("Administrowanie instalacją");
    # $sel->title_like(qr/^Administrowanie instalacją/, "Wyświetl admin.cgi");
}

# Go to editproducts.cgi and display the given product.
sub edit_product {
    my ($sel, $product, $classification) = @_;

    $classification ||= "Unclassified";
    go_to_admin($sel);
    $sel->click_ok("link=Produkty", undef, "Przejdź do strony produktów");
    $sel->wait_for_page_to_load(WAIT_TIME);
    my $title = $sel->get_title();
    if ($title eq "Wybór kategorii") {
        ok(1, "Dostępna jest więcej niż jedna kategoria. Wyświetla listę kategorii.");
        $sel->click_ok("link=$classification", undef, "Wybór kategorii $classification");
        $sel->wait_for_page_to_load(WAIT_TIME);
    }
    else {
        $sel->title_is("Modyfikowanie produktów", "Wyświetl listę produktów w wybranej kategorii");
    }
    $sel->click_ok("link=$product", undef, "Wybór produktu $product");
    $sel->wait_for_page_to_load(WAIT_TIME);
    $sel->title_is("Modyfikowanie produktu „$product”", "Wyświetlenie opcji z produkcie $product");
}

sub add_product {
    my ($sel, $classification) = @_;

    $classification ||= "Unclassified";
    go_to_admin($sel);
    $sel->click_ok("link=Produkty", undef, "Przejdź do strony produktów");
    $sel->wait_for_page_to_load(WAIT_TIME);
    my $title = $sel->get_title();
    if ($title eq "Select Classification") {
        ok(1, "More than one enterable classification available. Display them in a list");
        $sel->click_ok("//a[contains(\@href, 'editproducts.cgi?action=add&classification=$classification')]",
                       undef, "Add product to $classification");
    }
    else {
        $sel->title_is("Modyfikowanie produktów", "Display the list of enterable products");
        $sel->click_ok("link=Dodaj produkt", undef, "Dodaj nowy produkt");
    }
    $sel->wait_for_page_to_load(WAIT_TIME);
    $sel->title_is("Dodawanie produktu", "Wyświetl formularz dodawania nowego produktu");
}

sub open_advanced_search_page {
    my $sel = shift;

    $sel->click_ok("link=Wyszukiwanie");
    $sel->wait_for_page_to_load(WAIT_TIME);
    my $title = $sel->get_title();
    if ($title eq "Wyszukiwanie błędów") {
        ok(1, "Display the simple search form");
        $sel->click_ok("link=Wyszukiwanie zaawansowane");
        $sel->wait_for_page_to_load(WAIT_TIME);
    }
    $sel->title_is("Wyszukiwanie błędów", "Display the Advanced search form");
}

# $params is a hashref of the form:
# {section1 => { param1 => {type => '(text|select)', value => 'foo'},
#                param2 => {type => '(text|select)', value => 'bar'},
#                param3 => undef },
#  section2 => { param4 => ...},
# }
# section1, section2, ... is the name of the section
# param1, param2, ... is the name of the parameter (which must belong to the given section)
# type => 'text' is for text fields
# type => 'select' is for drop-down select fields
# undef is for radio buttons (in which case the parameter must be the ID of the radio button)
# value => 'foo' is the value of the parameter (either text or label)
sub set_parameters {
    my ($sel, $params) = @_;

    go_to_admin($sel);
    $sel->click_ok("link=Parametry", undef, "Strona z parametrami instalacji");
    $sel->wait_for_page_to_load(WAIT_TIME);
    $sel->title_is("Konfiguracja: Ustawienia wymagane");
    my $last_section = "Ustawienia wymagane";

    foreach my $section (keys %$params) {
        if ($section ne $last_section) {
            $sel->click_ok("link=$section");
            $sel->wait_for_page_to_load_ok(WAIT_TIME);
            $sel->title_is("Konfiguracja: $section");
            $last_section = $section;
        }
        my $param_list = $params->{$section};
        foreach my $param (keys %$param_list) {
            my $data = $param_list->{$param};
            if (defined $data) {
                my $type = $data->{type};
                my $value = $data->{value};

                if ($type eq 'text') {
                    $sel->type_ok($param, $value);
                }
                elsif ($type eq 'select') {
                    $sel->select_ok($param, "label=$value");
                }
                else {
                    ok(0, "Unknown parameter type: $type");
                }
            }
            else {
                # If the value is undefined, then the param name is
                # the ID of the radio button.
                $sel->click_ok($param);
            }
        }
        $sel->click_ok('//input[@type="submit" and @value="Zapisz zmiany"]', undef, "Zapisz zmiany");
        $sel->wait_for_page_to_load_ok(WAIT_TIME);
        $sel->title_is("Zaktualizowano parametry");
    }
}

1;

__END__
