use strict;
use warnings;
use lib qw(lib);

use Test::More "no_plan";

use QA::Util;
use utf8;

my ($sel, $config) = get_selenium();

# 1st step: turn on usetargetmilestone, musthavemilestoneonaccept and letsubmitterchoosemilestone.

log_in($sel, $config, 'admin');
set_parameters($sel, {'Pola błędu'          => {'usetargetmilestone-on'          => undef},
                      'Zasady modyfikowania błędów' => {'musthavemilestoneonaccept-on'   => undef,
                                                'letsubmitterchoosemilestone-on' => undef},
                     }
              );

# 2nd step: Add the milestone "2.0" (with sortkey = 10) to the TestProduct product.

edit_product($sel, "TestProduct");
$sel->click_ok("link=Modyfikuj wersje docelowe:", undef, "Go to the Edit milestones page");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Modyfikowanie wersji docelowych produktu „TestProduct”", "Display milestones");
$sel->click_ok("link=Dodaj wersję docelową", undef, "Go add a new milestone");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Dodawanie wersji docelowej do produktu „TestProduct”", "Enter new milestone");
$sel->type_ok("milestone", "2.0", "Set its name to 2.0");
$sel->type_ok("sortkey", "10", "Set its sortkey to 10");
$sel->click_ok("create", undef, "Submit data");
$sel->wait_for_page_to_load(WAIT_TIME);
# If the milestone already exists, that's not a big deal. So no special action
# is required in this case.
$sel->title_is("Utworzono wersję docelową", "Milestone Created");

# 3rd step: file a new bug, leaving the milestone alone (should fall back to the default one).

file_bug_in_product($sel, "TestProduct");
$sel->selected_label_is("component", "TestComponent", "Component already selected (no other component defined)");
$sel->selected_label_is("target_milestone", "---", "Default milestone selected");
$sel->selected_label_is("version", "unspecified", "Version already selected (no other version defined)");
my $bug_summary = "Target Milestone left to default";
$sel->type_ok("short_desc", $bug_summary);
$sel->type_ok("comment", "Created by Selenium to test 'musthavemilestoneonaccept'");
my $bug1_id = create_bug($sel, $bug_summary);

# 4th step: edit the bug (test musthavemilestoneonaccept ON).

$sel->select_ok("bug_status", "label=W REALIZACJI", "Change bug status to IN_PROGRESS");
$sel->click_ok("commit", undef, "Save changes");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Wersja docelowa jest wymagana", "Change rejected: musthavemilestoneonaccept is on but the milestone selected is the default one");
$sel->is_text_present_ok("należy określić dla niego wersję docelową", undef, "Display error message");
# We cannot use go_back_ok() because we just left post_bug.cgi where data has been submitted using POST.
go_to_bug($sel, $bug1_id);
$sel->select_ok("target_milestone", "label=2.0", "Select a non-default milestone");
edit_bug($sel, $bug1_id, $bug_summary);

# 5th step: create another bug.

file_bug_in_product($sel, "TestProduct");
$sel->select_ok("target_milestone", "label=2.0", "Set the milestone to 2.0");
$sel->selected_label_is("component", "TestComponent", "Component already selected (no other component defined)");
$sel->selected_label_is("version", "unspecified", "Version already selected (no other version defined)");
my $bug_summary2 = "Target Milestone set to non-default";
$sel->type_ok("short_desc", $bug_summary2);
$sel->type_ok("comment", "Created by Selenium to test 'musthavemilestoneonaccept'");
my $bug2_id = create_bug($sel, $bug_summary2);

# 6th step: edit the bug (test musthavemilestoneonaccept ON).

$sel->select_ok("bug_status", "label=W REALIZACJI");
edit_bug($sel, $bug2_id, $bug_summary2);

# 7th step: test validation methods for milestones.

go_to_admin($sel);
$sel->click_ok("link=wersje docelowe");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Wybór produktu, którego wersje docelowe będą modyfikowane");
$sel->click_ok("link=TestProduct");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Modyfikowanie wersji docelowych produktu „TestProduct”");
$sel->click_ok("link=2.0");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Modyfikowanie wersji docelowej „2.0” produktu „TestProduct”");
$sel->type_ok("milestone", "1.0");
$sel->value_is("milestone", "1.0");
$sel->click_ok("update");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Zaktualizowano wersję docelową");
$sel->click_ok("link=Dodaj wersję docelową");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Dodawanie wersji docelowej do produktu „TestProduct”");
$sel->type_ok("milestone", "1.5");
$sel->value_is("milestone", "1.5");
$sel->type_ok("sortkey", "99999999999999999");
$sel->value_is("sortkey", "99999999999999999");
$sel->click_ok("create");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Nieprawidłowy klucz sortowania wersji docelowej");
my $error_msg = trim($sel->get_text("error_msg"));
ok($error_msg =~ /^Klucz sortowania „99999999999999999” nie mieści się w przedziale/, "Invalid sortkey");
$sel->go_back_ok();
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->type_ok("sortkey", "-polu7A");
$sel->value_is("sortkey", "-polu7A");
$sel->click_ok("create");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Nieprawidłowy klucz sortowania wersji docelowej");
$error_msg = trim($sel->get_text("error_msg"));
ok($error_msg =~ /^Klucz sortowania „-polu7A” nie mieści się w przedziale/, "Invalid sortkey");
$sel->go_back_ok();
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->click_ok("link=Modyfikuj wersje docelowe produktu „TestProduct”");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Modyfikowanie wersji docelowych produktu „TestProduct”");
$sel->click_ok("link=Usuń");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Usuwanie wersji docelowej produktu „TestProduct”");
$sel->is_text_present_ok("Po usunięciu tej wersji", undef, "Warn the user about bugs being affected");
$sel->click_ok("delete");
$sel->wait_for_page_to_load(WAIT_TIME);
$sel->title_is("Usunięto wersję docelową");

# 8th step: make sure the (now deleted) milestone of the bug has fallen back to the default milestone.

go_to_bug($sel, $bug1_id);
$sel->is_text_present_ok('regexp:Wersja docelowa:\W+---', undef, "Milestone has fallen back to the default milestone");

# 9th step: file another bug.

file_bug_in_product($sel, "TestProduct");
$sel->selected_label_is("target_milestone", "---", "Default milestone selected");
$sel->selected_label_is("component", "TestComponent");
my $bug_summary3 = "Only one Target Milestone available";
$sel->type_ok("short_desc", $bug_summary3);
$sel->type_ok("comment", "Created by Selenium to test 'musthavemilestoneonaccept'");
my $bug3_id = create_bug($sel, $bug_summary3);

# 10th step: musthavemilestoneonaccept must have no effect as there is
#            no other milestone available besides the default one.

$sel->select_ok("bug_status", "label=W REALIZACJI");
edit_bug($sel, $bug3_id, $bug_summary3);

# 11th step: turn musthavemilestoneonaccept back to OFF.

set_parameters($sel, {'Zasady modyfikowania błędów' => {'musthavemilestoneonaccept-off' => undef}});
logout($sel);
