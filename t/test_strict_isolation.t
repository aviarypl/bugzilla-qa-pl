use strict;
use warnings;
use lib qw(lib);

use Test::More "no_plan";

use QA::Util;
use utf8;

my ($sel, $config) = get_selenium();
my $qa_user = $config->{QA_Selenium_TEST_user_login};
my $no_privs_user = $config->{unprivileged_user_login};

log_in($sel, $config, 'admin');
set_parameters($sel, { "Grupy zabezpieczeń" => {"strict_isolation-on" => undef} });

# Restrict the bug to the "Master" group, so that we can check that only
# allowed people can be CC'ed to the bug.

file_bug_in_product($sel, 'Another Product');
$sel->select_ok("component", "label=c2");
$sel->select_ok("version", "label=Another2");
my $bug_summary = "Test isolation";
$sel->type_ok("short_desc", $bug_summary);
$sel->type_ok("comment", "Unallowed users refused");
my $master_gid = $sel->get_attribute('//input[@type="checkbox" and @name="groups" and @value="Master"]@id');
$sel->check_ok($master_gid);
$master_gid =~ s/group_//;
my $bug1_id = create_bug($sel, $bug_summary);

# At that point, CANEDIT is off and so everybody can be CC'ed to the bug.

$sel->click_ok("cc_edit_area_showhide");
$sel->type_ok("newcc", "$qa_user, $no_privs_user");
edit_bug_and_return($sel, $bug1_id, $bug_summary);

$sel->click_ok("cc_edit_area_showhide");
$sel->add_selection_ok("cc", "label=$no_privs_user");
$sel->add_selection_ok("cc", "label=$qa_user");
$sel->check_ok("removecc");
edit_bug($sel, $bug1_id, $bug_summary);

# Now enable CANEDIT for the "Master" group. This will enable strict isolation
# for the product.

edit_product($sel, "Another Product");
$sel->click_ok("link=Modyfikuj relacje grupa/produkt:");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Modyfikowanie relacji grupa/produkt dla produktu „Another Product”");
$sel->check_ok("canedit_$master_gid");
$sel->click_ok("submit");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Aktualizacja grupy dla produktu „Another Product”");

# Non-members can no longer be CC'ed to the bug.

go_to_bug($sel, $bug1_id);
$sel->click_ok("cc_edit_area_showhide");
$sel->type_ok("newcc", $no_privs_user);
$sel->click_ok("commit");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Nieprawidłowa grupa użytkowników");
$sel->is_text_present_ok("Użytkownik „$no_privs_user” nie może modyfikować produktu „Another Product”");
$sel->go_back_ok();
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/^Błąd $bug1_id /);
$sel->click_ok("cc_edit_area_showhide");
$sel->type_ok("newcc", $qa_user);
$sel->click_ok("commit");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Nieprawidłowa grupa użytkowników");
$sel->is_text_present_ok("Użytkownik „$qa_user” nie może modyfikować produktu „Another Product”");

# Now set QA_Selenium_TEST user as a member of the Master group.

go_to_admin($sel);
$sel->click_ok("link=Użytkownicy");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Wyszukiwanie użytkowników");
$sel->type_ok("matchstr", $qa_user);
$sel->select_ok("matchtype", "label=dokładnie tego użytkownika");
$sel->click_ok("search");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Edytowanie użytkownika QA-Selenium-TEST <$qa_user>");
$sel->check_ok("group_$master_gid");
$sel->click_ok("update");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Zaktualizowano konto $qa_user");

# The QA_Selenium_TEST user can now be CC'ed to the bug.

go_to_bug($sel, $bug1_id);
$sel->click_ok("cc_edit_area_showhide");
$sel->type_ok("newcc", $qa_user);
edit_bug_and_return($sel, $bug1_id, $bug_summary);
$sel->click_ok("cc_edit_area_showhide");
$sel->add_selection_ok("cc", "label=$qa_user");
$sel->check_ok("removecc");
edit_bug_and_return($sel, $bug1_id, $bug_summary);

# The powerless user still cannot be CC'ed.

$sel->click_ok("cc_edit_area_showhide");
$sel->type_ok("newcc", "$qa_user, $no_privs_user");
$sel->click_ok("commit");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Nieprawidłowa grupa użytkowników");
$sel->is_text_present_ok("Użytkownik „$no_privs_user” nie może modyfikować produktu „Another Product”");

# Reset parameters back to defaults.

set_parameters($sel, { "Grupy zabezpieczeń" => {"strict_isolation-off" => undef} });

go_to_admin($sel);
$sel->click_ok("link=Użytkownicy");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Wyszukiwanie użytkowników");
$sel->type_ok("matchstr", $qa_user);
$sel->select_ok("matchtype", "label=dokładnie tego użytkownika");
$sel->click_ok("search");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Edytowanie użytkownika QA-Selenium-TEST <$qa_user>");
$sel->uncheck_ok("group_$master_gid");
$sel->click_ok("update");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Zaktualizowano konto $qa_user");

edit_product($sel, "Another Product");
$sel->click_ok("link=Modyfikuj relacje grupa/produkt:");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Modyfikowanie relacji grupa/produkt dla produktu „Another Product”");
$sel->uncheck_ok("canedit_$master_gid");
$sel->click_ok("submit");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Aktualizacja grupy dla produktu „Another Product”");
logout($sel);
