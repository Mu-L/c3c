module std::os::env @test;

 fn void set_get_unset()
 {
 	const NAME = "C3_TEST_ENVVAR";
 	const VALUE = "foobar";

 	env::set_var(NAME, VALUE);
 	String v = env::get_var(mem, NAME)!!;
 	assert(v == VALUE, "got %s; want %s", v, VALUE);
	free(v);
 	env::clear_var(NAME);
 	if (try env::get_var(mem, NAME))
 	{
 	    unreachable("environment variable should no longer exist");
 	}
 }