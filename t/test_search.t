use strict;
use warnings;
use lib qw(lib);
use QA::Util;
use utf8;
use Test::More "no_plan";

my ($sel, $config) = get_selenium();

# TODO: This test really needs improvement. There is by far much more stuff
# to test in this area.

# First, a very trivial search, which returns no result.

go_to_home($sel, $config);
open_advanced_search_page($sel);
$sel->type_ok("short_desc", "ois£jdfm#sd%fasd!fm", "Type a non-existent string in the bug summary field");
$sel->click_ok("Szukaj");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Lista błędów");
$sel->is_text_present_ok("Nie znaleziono żadnych błędów.");

# Display all available columns. Look for all bugs assigned to a user who doesn't exist.

$sel->open_ok("/$config->{bugzilla_installation}/buglist.cgi?quicksearch=%40xx45ft&columnlist=all");
$sel->title_is("Lista błędów");
$sel->is_text_present_ok("Nie znaleziono żadnych błędów.");

# Now some real tests.

log_in($sel, $config, 'canconfirm');
file_bug_in_product($sel, "TestProduct");
my $bug_summary = "Update this summary with this bug ID";
$sel->type_ok("short_desc", $bug_summary);
$sel->type_ok("comment", "I'm supposed to appear in the coming buglist.");
my $bug1_id = create_bug($sel, $bug_summary);
$sel->click_ok("editme_action");
$bug_summary .= ": my ID is $bug1_id";
$sel->type_ok("short_desc", $bug_summary);
$sel->type_ok("comment", "Updating bug summary....");
edit_bug($sel, $bug1_id, $bug_summary);

# Test pronoun substitution.

open_advanced_search_page($sel);
$sel->remove_all_selections("bug_status");
$sel->remove_all_selections("resolution");
$sel->type_ok("short_desc", "my ID is $bug1_id");
$sel->select_ok("f1", "label=Komentujący");
$sel->select_ok("o1", "label=jest taki, jak");
$sel->type_ok("v1", "%user%");
$sel->click_ok("add_button");
$sel->select_ok("f2", "label=Komentarz");
$sel->select_ok("o2", "label=zawiera wyrażenie");
$sel->type_ok("v2", "coming buglist");
$sel->click_ok("Szukaj");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Lista błędów");
$sel->is_text_present_ok("Znaleziono jeden błąd.");
$sel->is_text_present_ok("Update this summary with this bug ID: my ID is $bug1_id");
logout($sel);
