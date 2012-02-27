use strict;
use warnings;
use lib qw(lib);

use Test::More "no_plan";

use QA::Util;
use utf8;

my ($sel, $config) = get_selenium();

log_in($sel, $config, 'admin');
set_parameters($sel, { "Pola błędu" => {"useclassification-on" => undef} });

# Do not use file_bug_in_product() because our goal here is not to file
# a bug but to check what is present in the UI, and also to make sure
# that we get exactly the right page with the right information.
#
# The admin is not a member of the "QA‑Selenium‑TEST" group, and so
# cannot see the "QA‑Selenium‑TEST" product.

$sel->click_ok("link=Nowy");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Wybór kategorii");
my $full_text = trim($sel->get_body_text());
ok($full_text =~ /Wszystkie: Wszystkie produkty/, "The 'All' link is displayed");
$sel->click_ok("link=Wszystkie");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Zgłaszanie błędu");
ok(!$sel->is_text_present("QA-Selenium-TEST"), "The QA-Selenium-TEST product is not displayed");
logout($sel);

# Same steps, but for a member of the "QA‑Selenium‑TEST" group.
# The "QA‑Selenium‑TEST" product must be visible to him.

log_in($sel, $config, 'QA_Selenium_TEST');
$sel->click_ok("link=Nowy");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Wybór kategorii");
$sel->click_ok("link=Wszystkie");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Zgłaszanie błędu");
$sel->is_text_present_ok("QA-Selenium-TEST");
# For some unknown reason, Selenium doesn't like hyphens in links.
#$sel->click_ok("link=QA-Selenium-TEST");
$sel->click_ok('//a[contains(@href, "product=QA-Selenium-TEST")]');
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Zgłaszanie błędu: QA-Selenium-TEST");
logout($sel);
