use strict;
use warnings;
use lib qw(lib);

use Test::More "no_plan";

use QA::Util;
use utf8;

my ($sel, $config) = get_selenium();

# If a saved search named 'SavedSearchTEST1' exists, remove it.

log_in($sel, $config, 'QA_Selenium_TEST');
$sel->click_ok("link=Preferencje");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Preferencje użytkownika");
$sel->click_ok("link=Wyszukiwania");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Preferencje użytkownika");

if($sel->is_text_present("SavedSearchTEST1")) {
    # There is no other way to identify this link (as they are all named "Forget").
    $sel->click_ok('//a[contains(@href,"buglist.cgi?cmdtype=dorem&remaction=forget&namedcmd=SavedSearchTEST1")]');
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    $sel->title_is("Usuwanie wyszukiwania");
    $sel->is_text_present_ok("Wyszukiwanie SavedSearchTEST1 zostało usunięte.");
}

# Create a new saved search.

open_advanced_search_page($sel);
$sel->type_ok("short_desc", "test search");
$sel->click_ok("Szukaj");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Lista błędów");
$sel->type_ok("save_newqueryname", "SavedSearchTEST1");
$sel->click_ok("remember");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Utworzono wyszukiwanie");
my $text = trim($sel->get_text("message"));
ok($text =~ /Masz nowe wyszukiwanie o nazwie SavedSearchTEST1./, "New search named SavedSearchTEST1 has been created");
$sel->click_ok("link=SavedSearchTEST1");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Lista błędów: SavedSearchTEST1");

# Remove the saved search from the page footer. It should no longer be displayed there.

$sel->click_ok("link=Preferencje");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Preferencje użytkownika");
$sel->click_ok("link=Wyszukiwania");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Preferencje użytkownika");

$sel->is_text_present_ok("SavedSearchTEST1");
$sel->uncheck_ok('//input[@type="checkbox" and @alt="SavedSearchTEST1"]');
# $sel->value_is("//input[\@type='checkbox' and \@alt='SavedSearchTEST1']", "off");
$sel->click_ok("update");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Preferencje użytkownika");
$text = trim($sel->get_text("message"));
ok($text =~ /Zmiany w sekcji wyszukiwania zostały zapisane./, "Saved searches changes have been saved");

# Modify the saved search. Said otherwise, we should still be able to save
# a new search with exactly the same name.

open_advanced_search_page($sel);
$sel->type_ok("short_desc", "bilboa");
$sel->click_ok("Szukaj");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Lista błędów");
# As we said, this saved search should no longer be displayed in the page footer.
ok(!$sel->is_text_present("SavedSearchTEST1"), "SavedSearchTEST1 is not present in the page footer");
$sel->type_ok("save_newqueryname", "SavedSearchTEST1");
$sel->click_ok("remember");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Zaktualizowano wyszukiwanie");
$text = trim($sel->get_text("message"));
ok($text =~ /Twoje wyszukiwanie o nazwie SavedSearchTEST1 zostało zaktualizowane./, "Saved searche SavedSearchTEST1 has been updated.");

# Make sure our new criteria has been saved (let's edit the saved search).
# As the saved search is no longer displayed in the footer, we have to go
# to the "Preferences" page to edit it.

$sel->click_ok("link=Preferencje");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Preferencje użytkownika");
$sel->click_ok("link=Wyszukiwania");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Preferencje użytkownika");

$sel->is_text_present_ok("SavedSearchTEST1");
$sel->click_ok('//a[@href="buglist.cgi?cmdtype=dorem&remaction=run&namedcmd=SavedSearchTEST1"]');
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Lista błędów: SavedSearchTEST1");
$sel->click_ok("link=Modyfikuj wyszukiwanie");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Wyszukiwanie błędów");
$sel->value_is("short_desc", "bilboa");
$sel->go_back_ok();
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->click_ok("link=Usuń wyszukiwanie „SavedSearchTEST1”");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Usuwanie wyszukiwania");
$text = trim($sel->get_text("message"));
ok($text =~ /Wyszukiwanie SavedSearchTEST1 zostało usunięte./, "The SavedSearchTEST1 search is gone.");
logout($sel);
