use strict;
use warnings;
use lib qw(lib);

use Test::More "no_plan";

use QA::Util;
use utf8;

my ($sel, $config) = get_selenium();

log_in($sel, $config, 'admin');
set_parameters($sel, {'Pola błędu' => {'usestatuswhiteboard-on' => undef}});

# Make sure the status whiteboard is displayed and add stuff to it.

file_bug_in_product($sel, "TestProduct");
$sel->select_ok("component", "TestComponent");
my $bug_summary = "white and black";
$sel->type_ok("short_desc", $bug_summary);
$sel->type_ok("comment", "This bug is to test the status whiteboard");
my $bug1_id = create_bug($sel, $bug_summary);
$sel->is_text_present_ok("Tablica:");
$sel->type_ok("status_whiteboard", "[msg from test_status_whiteboard.t: x77v]");
edit_bug($sel, $bug1_id, $bug_summary);

file_bug_in_product($sel, "TestProduct");
$sel->select_ok("component", "TestComponent");
my $bug_summary2 = "WTC";
$sel->type_ok("short_desc", $bug_summary2);
$sel->type_ok("comment", "bugzillation!");
my $bug2_id = create_bug($sel, $bug_summary2);
$sel->type_ok("status_whiteboard", "[msg from test_status_whiteboard.t: x77v]");
edit_bug($sel, $bug2_id, $bug_summary2);

# Now search these bugs above using data being in the status whiteboard,
# and save the query.

open_advanced_search_page($sel);
$sel->remove_all_selections_ok("product");
$sel->remove_all_selections_ok("bug_status");
$sel->type_ok("status_whiteboard", "x77v");
$sel->click_ok("Szukaj");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Lista błędów");
$sel->is_text_present_ok("2 błędy");
$sel->type_ok("save_newqueryname", "sw-x77v");
$sel->click_ok("remember");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Utworzono wyszukiwanie");
my $text = trim($sel->get_text("message"));
ok($text =~ /Masz nowe wyszukiwanie o nazwie sw-x77v/, 'Saved search correctly saved');

# Make sure the saved query works.

$sel->click_ok("link=sw-x77v");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Lista błędów: sw-x77v");
$sel->is_text_present_ok("2 błędy");

# The status whiteboard should no longer be displayed in both the query
# and bug view pages (query.cgi and show_bug.cgi) when usestatuswhiteboard
# is off.

set_parameters($sel, {'Pola błędu' => {'usestatuswhiteboard-off' => undef}});
$sel->click_ok("link=Wyszukiwanie");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Wyszukiwanie błędów");
ok(!$sel->is_text_present("Tablica statusu:"), "Whiteboard label no longer displayed in the search page");
go_to_bug($sel, $bug1_id);
ok(!$sel->is_text_present("Tablica statusu:"), "Whiteboard label no longer displayed in the bug page");

# Queries based on the status whiteboard should still work when
# the parameter is off.

$sel->click_ok("link=sw-x77v");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Lista błędów: sw-x77v");
$sel->is_text_present_ok("2 błędy");

# Turn on usestatuswhiteboard again as some other scripts may expect the status
# whiteboard to be available by default.

set_parameters($sel, {'Pola błędu' => {'usestatuswhiteboard-on' => undef}});

# Clear the status whiteboard and delete the saved search.

$sel->click_ok("link=sw-x77v");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Lista błędów: sw-x77v");
$sel->is_text_present_ok("2 błędy");
$sel->click_ok("link=Zmień wiele błędów jednocześnie");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Lista błędów");
$sel->click_ok("check_all");
$sel->type_ok("status_whiteboard", "");
$sel->click_ok("commit");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Błędy zostały przetworzone");

$sel->click_ok("link=sw-x77v");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Lista błędów: sw-x77v");
$sel->is_text_present_ok("Nie znaleziono żadnych błędów.");
$sel->click_ok("link=Usuń wyszukiwanie „sw-x77v”");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Usuwanie wyszukiwania");
$sel->is_text_present_ok("Wyszukiwanie sw-x77v zostało usunięte.");
logout($sel);
