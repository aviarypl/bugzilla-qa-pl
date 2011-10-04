use strict;
use warnings;
use lib qw(lib);

use Test::More "no_plan";

use QA::Util;

my ($sel, $config) = get_selenium();

# XXX - At some point, this trivial script should be merged with test_create_user_accounts.t.
#       Either that or we should improve this script a lot.

# Try to log in to Bugzilla using an invalid account. To be sure that the login form
# is triggered, we try to file a new bug.

go_to_home($sel, $config);
$sel->click_ok("link=New");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Log in to Bugzilla");
# The login and password are hardcoded here, because this account doesn't exist.
$sel->type_ok("Bugzilla_login", 'guest@foo.com');
$sel->type_ok("Bugzilla_password", 'foo-bar-baz');
$sel->click_ok("log_in");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Invalid Username Or Password");
$sel->is_text_present_ok("The username or password you entered is not valid.");
